// REQ-009 · REQ-010 · UI-IOS-5a · UI-IOS-14a — 입력 화면 상태. 가짜 데이터만.
import CoreGraphics
import Foundation
import Testing
@testable import Onoff

private struct FailingDutyRepository: DutyRepository {
    struct Failure: Error {}
    let saved: [CalendarDay: ShiftTypeID]
    func assignments(from: CalendarDay, through: CalendarDay) async throws -> [CalendarDay: ShiftTypeID] { saved }
    func apply(_ changes: DutyChanges) async throws { throw Failure() }
}

@MainActor
struct ShiftInputViewModelTests {
    private func day(_ d: Int) -> CalendarDay { TestSupport.day(2026, 11, d) }

    private func viewModel(duties: any DutyRepository, cursor: CalendarDay? = nil) -> ShiftInputViewModel {
        ShiftInputViewModel(
            range: StartShiftInputUseCase.month(year: 2026, month: 11), cursor: cursor,
            startShiftInput: StartShiftInputUseCase(shiftTypes: InMemoryShiftTypeRepository(SampleData.shiftTypes), duties: duties),
            applyShiftInput: ApplyShiftInputUseCase(duties: duties))
    }

    @Test("키패드: 넣으면 다음 날로, 초안 칸 수 · 상태 줄 · 지우기")
    func keypad() async throws {
        let duties = InMemoryDutyRepository([day(1): ShiftTypeID(rawValue: "OFF")])
        let model = viewModel(duties: duties)
        await model.load()
        #expect(model.state == .editing)
        #expect(model.cursorDay == day(2)) // 첫 미등록 날
        #expect(model.leadingBlanks == 0) // 2026-11-01 일요일
        #expect(model.keypadTypes.map(\.code) == ["D", "E", "N", "OFF", "M", "교육", "S", "연차", "반차"])

        let d = try #require(model.keypadTypes.first { $0.code == "D" })
        model.enter(d)
        model.enter(d)
        #expect(model.changedCount == 2)
        #expect(model.filledCount == 3)
        #expect(model.dayCount == 30)
        #expect(model.cells.first { $0.isCursor }?.date == day(4))

        model.backspace()
        #expect(model.cursorDay == day(3))
        #expect(model.changedCount == 1)
        #expect(model.cells[2].shift == nil) // 지운 칸은 미등록
    }

    @Test("적용: 저장 후 닫아도 됨, 다시 열면 저장한 값")
    func applySaves() async throws {
        let duties = InMemoryDutyRepository([:])
        let model = viewModel(duties: duties, cursor: day(10))
        await model.load()
        model.enter(try #require(model.keypadTypes.first { $0.code == "N" }))
        #expect(await model.apply() == .close(saved: true))
        #expect(model.changedCount == 0)
        #expect(try await duties.assignments(from: day(1), through: day(30)) == [day(10): ShiftTypeID(rawValue: "N")])
    }

    @Test("적용 실패: 닫지 않고 알림, 초안은 그대로")
    func applyFails() async throws {
        let model = viewModel(duties: FailingDutyRepository(saved: [:]))
        await model.load()
        model.enter(try #require(model.keypadTypes.first))
        #expect(await model.apply() == .stay)
        #expect(model.saveFailed)
        #expect(model.changedCount == 1)
    }

    @Test("고쳤다가 되돌리면 바뀐 칸 0 — 취소할 때 묻지 않는다, 바뀐 게 없으면 저장 없이 닫음")
    func undoBackToZero() async throws {
        let model = viewModel(duties: InMemoryDutyRepository([day(3): ShiftTypeID(rawValue: "D")]), cursor: day(3))
        await model.load()
        model.enter(try #require(model.keypadTypes.first { $0.code == "E" }))
        model.undo()
        #expect(model.changedCount == 0)
        #expect(model.cursorDay == day(3))
        model.skipDay()
        #expect(model.cursorDay == day(4))
        model.previousDay()
        model.select(day(20))
        #expect(model.cursorDay == day(20))
        #expect(model.nextDay == day(21))
        model.select(day(30))
        #expect(model.nextDay == nil)
        #expect(await model.apply() == .close(saved: false))
    }

    @Test("지운 근무 유형을 가리키는 날은 빈 칸 · 넣은 날로 세지 않는다(REQ-008)")
    func unknownTypeIsEmpty() async {
        let model = viewModel(duties: InMemoryDutyRepository([day(1): ShiftTypeID(rawValue: "GONE"), day(2): ShiftTypeID(rawValue: "D")]))
        await model.load()
        #expect(model.cells[0].shift == nil)
        #expect(model.filledCount == 1)
    }

    @Test("불러오기 실패")
    func loadFails() async {
        let model = viewModel(duties: FailingLoad())
        await model.load()
        #expect(model.state == .failed)
    }

    @Test("칠하기: 길게 누른 칸부터 끈 날 모두, 되돌아가면 줄고, 떼면 한 번에 · 되돌리기 한 번(REQ-011)")
    func paintStroke() async throws {
        let model = viewModel(duties: InMemoryDutyRepository([:]), cursor: day(10))
        await model.load()
        #expect(model.brush == .shift(ShiftTypeID(rawValue: "D"))) // 처음 붓은 목록 첫 근무
        model.brush = .shift(ShiftTypeID(rawValue: "AL"))

        model.beginStroke(at: day(12))
        model.moveStroke(to: day(17))
        model.moveStroke(to: day(16)) // 되돌아가면 17일은 빠진다
        model.moveStroke(to: nil)     // 달력 밖 — 마지막 칸 그대로
        #expect(model.strokeSummary == "연차 × 5일 · 11/12–16")
        #expect(model.cells[15].isUnderFinger)
        #expect(model.cells[16].isPainted == false)
        #expect(model.changedCount == 0) // 떼기 전에는 초안에 안 들어감

        model.endStroke()
        #expect(model.strokeSummary == nil)
        #expect(model.changedCount == 5)
        #expect(model.cursorDay == day(10)) // 커서는 그대로(14b 「키패드로 돌아가면 10일부터」)
        #expect(model.cells[11].isPainted && model.cells[15].isPainted)
        #expect(model.cells[11].shift?.code == "연차")

        model.undo()
        #expect(model.changedCount == 0)
        #expect(model.cells[11].isPainted == false)
    }

    @Test("칠하기: 거꾸로 끌기 · 한 칸 · 지우개 · 끊기면 넣지 않음")
    func paintVariants() async throws {
        let model = viewModel(duties: InMemoryDutyRepository([day(5): ShiftTypeID(rawValue: "N"), day(6): ShiftTypeID(rawValue: "N")]))
        await model.load()

        model.beginStroke(at: day(9))
        model.moveStroke(to: day(7))
        #expect(model.strokeSummary == "데이 × 3일 · 11/7–9")
        model.cancelStroke()
        #expect(model.changedCount == 0)

        model.beginStroke(at: day(20))
        #expect(model.strokeSummary == "데이 × 1일 · 11/20")
        model.endStroke()
        #expect(model.changedCount == 1)

        model.brush = .eraser
        model.beginStroke(at: day(4))
        model.moveStroke(to: day(6))
        #expect(model.strokeSummary == "지우개 × 3일 · 11/4–6")
        model.endStroke()
        #expect(model.cells[4].shift == nil && model.cells[5].shift == nil) // 미등록으로(OFF 아님)
        #expect(model.changedCount == 3) // 20일 + 지운 5 · 6일
    }

    @Test("방법을 바꿔도 초안 · 커서 · 되돌리기 그대로(REQ-009 · 14b)")
    func switchMethod() async throws {
        let model = viewModel(duties: InMemoryDutyRepository([:]), cursor: day(1))
        await model.load()
        let d = try #require(model.keypadTypes.first { $0.code == "D" })
        model.enter(d)
        model.method = .paint
        model.beginStroke(at: day(12))
        model.endStroke()
        model.method = .keypad
        #expect(model.cursorDay == day(2))
        #expect(model.changedCount == 2)
        model.undo()
        model.undo()
        #expect(model.changedCount == 0)
        #expect(model.cursorDay == day(1))
    }

    @Test("끄는 중 방법을 바꾸거나 적용하면 미리보기는 버린다(넣지 않음)")
    func strokeDiscarded() async throws {
        let model = viewModel(duties: InMemoryDutyRepository([:]))
        await model.load()
        model.beginStroke(at: day(3))
        model.moveStroke(to: day(5))
        model.method = .keypad
        #expect(model.isStroking == false)
        #expect(model.cells[3].shift == nil && model.changedCount == 0)

        model.method = .paint
        model.beginStroke(at: day(3))
        #expect(await model.apply() == .close(saved: false))
        #expect(model.isStroking == false)
    }

    @Test("칠한 칸 테두리: 실제로 바뀐 날만, 되돌리거나 키패드로 넣은 칸은 아님(14b)")
    func paintMarks() async throws {
        let model = viewModel(duties: InMemoryDutyRepository([:]), cursor: day(12))
        await model.load()
        let d = try #require(model.keypadTypes.first { $0.code == "D" })
        model.enter(d) // 12일 D(키패드)
        model.method = .paint
        model.beginStroke(at: day(10))
        model.moveStroke(to: day(14))
        model.endStroke() // D 붓
        #expect(model.cells[11].isPainted == false) // 이미 D였던 12일
        #expect(model.cells[9].isPainted && model.cells[13].isPainted)

        model.undo() // 칠하기 되돌림
        model.method = .keypad
        model.select(day(10))
        model.enter(d)
        #expect(model.cells[9].isPainted == false)

        model.paintDay(day(20))
        #expect(model.cells[19].isPainted && model.cells[19].shift?.code == "D")
    }

    @Test("달력 칸 자리 계산 — 손가락 위치 → 날")
    func gridLayout() {
        // 폭 7칸 × 50 + 사이 2 × 6 = 362, 줄 높이 52 + 2
        let width: CGFloat = 362
        #expect(InputGridLayout.dayIndex(at: CGPoint(x: 1, y: 1), width: width, leadingBlanks: 0, dayCount: 30) == 0)
        #expect(InputGridLayout.dayIndex(at: CGPoint(x: 361, y: 60), width: width, leadingBlanks: 0, dayCount: 30) == 13)
        #expect(InputGridLayout.dayIndex(at: CGPoint(x: 1, y: 1), width: width, leadingBlanks: 3, dayCount: 30) == nil) // 앞 빈칸
        #expect(InputGridLayout.dayIndex(at: CGPoint(x: 200, y: 4 * 54 + 10), width: width, leadingBlanks: 0, dayCount: 30) == nil) // 30일 뒤
        #expect(InputGridLayout.dayIndex(at: CGPoint(x: -1, y: 10), width: width, leadingBlanks: 0, dayCount: 30) == nil)
    }

    @Test("시작 시트: 미등록 날 수, 실패하면 숫자를 보이지 않음")
    func startSheet() async {
        let start = StartShiftInputUseCase(shiftTypes: InMemoryShiftTypeRepository(SampleData.shiftTypes),
                                           duties: InMemoryDutyRepository([day(1): ShiftTypeID(rawValue: "D")]))
        let sheet = ShiftInputStartViewModel(year: 2026, month: 11, startShiftInput: start)
        await sheet.load()
        #expect(sheet.unregisteredDays == 29)

        let failing = ShiftInputStartViewModel(year: 2026, month: 11, startShiftInput: StartShiftInputUseCase(
            shiftTypes: InMemoryShiftTypeRepository(SampleData.shiftTypes), duties: FailingLoad()))
        await failing.load()
        #expect(failing.unregisteredDays == nil)
    }
}

private struct FailingLoad: DutyRepository {
    struct Failure: Error {}
    func assignments(from: CalendarDay, through: CalendarDay) async throws -> [CalendarDay: ShiftTypeID] { throw Failure() }
    func apply(_ changes: DutyChanges) async throws {}
}
