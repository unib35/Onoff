// REQ-009 · REQ-010 · UI-IOS-5a · UI-IOS-14a — 입력 화면 상태. 가짜 데이터만.
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
        #expect(await model.apply())
        #expect(model.changedCount == 0)
        #expect(try await duties.assignments(from: day(1), through: day(30)) == [day(10): ShiftTypeID(rawValue: "N")])
    }

    @Test("적용 실패: 닫지 않고 알림, 초안은 그대로")
    func applyFails() async throws {
        let model = viewModel(duties: FailingDutyRepository(saved: [:]))
        await model.load()
        model.enter(try #require(model.keypadTypes.first))
        #expect(await model.apply() == false)
        #expect(model.saveFailed)
        #expect(model.changedCount == 1)
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
