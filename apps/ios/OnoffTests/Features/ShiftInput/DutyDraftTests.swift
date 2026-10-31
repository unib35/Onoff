// REQ-009 · REQ-010 · REQ-011 · REQ-013 · REQ-008 — 공유 테스트 표 apps/shared/fixtures/duty-draft.json
import Foundation
import Testing
@testable import Onoff

private final class BundleToken {}

private struct DraftFixture: Decodable {
    struct Action: Decodable {
        struct Paint: Decodable {
            let shift: String?
            let days: [String]
        }
        struct Repeat: Decodable {
            let pattern: [String]
            let from: String
            let through: String
        }
        let enter: String?
        let erase: Bool?
        let move: String?
        let paint: Paint?
        let `repeat`: Repeat?
        let undo: Bool?
    }
    struct Expect: Decodable {
        let cursor: String
        let assigned: [String: String]
        let cleared: [String]
    }
    struct Case: Decodable, CustomTestStringConvertible {
        let name: String
        let range: [String]
        let original: [String: String]
        let protected: [String]
        let cursor: String
        let actions: [Action]
        let expect: Expect

        var testDescription: String { name }
    }
    let cases: [Case]

    static func cases() throws -> [Case] {
        guard let url = Bundle(for: BundleToken.self).url(forResource: "duty-draft", withExtension: "json", subdirectory: "fixtures") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try JSONDecoder().decode(DraftFixture.self, from: Data(contentsOf: url)).cases
    }
}

private func day(_ text: String) -> CalendarDay {
    let parts = text.split(separator: "-").map { Int($0)! }
    return CalendarDay(year: parts[0], month: parts[1], day: parts[2])
}

private func id(_ raw: String) -> ShiftTypeID { ShiftTypeID(rawValue: raw) }

private func assignments(_ map: [String: String]) -> [CalendarDay: ShiftTypeID] {
    Dictionary(uniqueKeysWithValues: map.map { (day($0.key), id($0.value)) })
}

struct DutyDraftTests {
    @Test("공유 테스트 표", arguments: try DraftFixture.cases())
    fileprivate func fixture(_ testCase: DraftFixture.Case) {
        var draft = DutyDraft(range: day(testCase.range[0])...day(testCase.range[1]),
                              original: assignments(testCase.original),
                              protectedTypes: Set(testCase.protected.map(id)),
                              cursor: day(testCase.cursor))
        for action in testCase.actions {
            if let shift = action.enter { draft.enter(id(shift)) }
            if action.erase == true { draft.erase() }
            if let target = action.move { draft.moveCursor(to: day(target)) }
            if let paint = action.paint { draft.paint(paint.shift.map(id), days: paint.days.map(day)) }
            if let pattern = action.repeat {
                draft.repeatPattern(pattern.pattern.map(id), from: day(pattern.from), through: day(pattern.through))
            }
            if action.undo == true { draft.undo() }
        }
        #expect(draft.cursor == day(testCase.expect.cursor))
        #expect(draft.changes == DutyChanges(assigned: assignments(testCase.expect.assigned),
                                             cleared: Set(testCase.expect.cleared.map(day))))
    }

    @Test("되돌리기를 끝까지 하면 시작할 때와 같다 — 바뀐 날 없음")
    func undoAll() {
        var draft = DutyDraft(range: StartShiftInputUseCase.month(year: 2026, month: 10),
                              original: SampleData.octoberDuties, protectedTypes: [id("AL")])
        draft.enter(id("N"))
        draft.paint(id("E"), days: [day("2026-10-05"), day("2026-10-06")])
        draft.repeatPattern([id("D"), id("OFF")], from: day("2026-10-20"), through: day("2026-10-31"))
        draft.moveCursor(to: day("2026-10-15"))
        draft.erase()
        while draft.canUndo { draft.undo() }
        #expect(draft.changes.isEmpty)
        #expect(draft.cursor == day("2026-10-01"))
    }

    @Test("아무것도 바꾸지 않는 동작은 되돌리기에 쌓이지 않는다")
    func noOpIsNotRecorded() {
        var draft = DutyDraft(range: StartShiftInputUseCase.month(year: 2026, month: 10),
                              original: [day("2026-10-05"): id("E")], protectedTypes: [])
        draft.paint(id("E"), days: [day("2026-10-05")])
        draft.erase() // 10/1은 이미 미등록
        draft.repeatPattern([], from: day("2026-10-01"), through: day("2026-10-31"))
        #expect(!draft.canUndo)
    }

    @Test("커서는 기간 안으로 맞춘다")
    func cursorClamped() {
        var draft = DutyDraft(range: StartShiftInputUseCase.month(year: 2026, month: 10), original: [:],
                              protectedTypes: [], cursor: day("2026-11-05"))
        #expect(draft.cursor == day("2026-10-31"))
        draft.moveCursor(to: day("2026-09-01"))
        #expect(draft.cursor == day("2026-10-01"))
    }
}

struct ShiftInputUseCaseTests {
    private func repositories(_ duties: [CalendarDay: ShiftTypeID] = SampleData.octoberDuties)
        -> (InMemoryShiftTypeRepository, InMemoryDutyRepository) {
        (InMemoryShiftTypeRepository(SampleData.shiftTypes), InMemoryDutyRepository(duties))
    }

    @Test("시작: 저장된 근무 · 키패드는 숨긴 유형 빼고 목록 순서 · 휴가는 보호")
    func start() async throws {
        let (types, duties) = repositories()
        let session = try await StartShiftInputUseCase(shiftTypes: types, duties: duties)(
            range: StartShiftInputUseCase.month(year: 2026, month: 10), cursor: day("2026-10-12"))
        #expect(session.keypadTypes.map(\.code) == ["D", "E", "N", "OFF", "M", "교육", "S", "연차", "반차"])
        #expect(session.draft.protectedTypes == [id("AL"), id("HALF"), id("SICK"), id("PUB")])
        #expect(session.draft.shift(on: day("2026-10-12")) == id("OFF"))
        #expect(session.draft.cursor == day("2026-10-12"))
        #expect(session.draft.changes.isEmpty)
    }

    @Test("적용: 바뀐 날만 저장, 지운 날은 미등록으로 읽힌다")
    func apply() async throws {
        let (types, duties) = repositories()
        var session = try await StartShiftInputUseCase(shiftTypes: types, duties: duties)(
            range: StartShiftInputUseCase.month(year: 2026, month: 10), cursor: day("2026-10-12"))
        session.draft.enter(id("E"))
        session.draft.moveCursor(to: day("2026-10-31"))
        session.draft.erase()
        let result = try await ApplyShiftInputUseCase(duties: duties)(session.draft)
        #expect(result.savedDays == 2)
        #expect(result.draft.changes.isEmpty) // 저장한 값이 새 기준
        #expect(!result.draft.canUndo)
        #expect(result.draft.shift(on: day("2026-10-12")) == id("E"))

        let saved = try await duties.assignments(from: day("2026-10-01"), through: day("2026-10-31"))
        #expect(saved[day("2026-10-12")] == id("E"))
        #expect(saved[day("2026-10-31")] == nil)
        #expect(saved.count == 30)
        let loaded = try await TestSupport.loadDutyDays(saved)(from: day("2026-10-31"), through: day("2026-10-31"))
        #expect(loaded.first?.state == .unregistered)
    }

    @Test("적용: 바뀐 게 없으면 저장하지 않는다")
    func applyNothing() async throws {
        let (types, duties) = repositories()
        let session = try await StartShiftInputUseCase(shiftTypes: types, duties: duties)(
            range: StartShiftInputUseCase.month(year: 2026, month: 11))
        #expect(try await ApplyShiftInputUseCase(duties: duties)(session.draft).savedDays == 0)
    }

    @Test("적용한 뒤 이어서 고치면 그 뒤에 바꾼 날만 저장한다")
    func applyAgain() async throws {
        let (types, duties) = repositories([:])
        var session = try await StartShiftInputUseCase(shiftTypes: types, duties: duties)(
            range: StartShiftInputUseCase.month(year: 2026, month: 10))
        session.draft.enter(id("D"))
        let apply = ApplyShiftInputUseCase(duties: duties)
        var draft = try await apply(session.draft).draft
        draft.enter(id("E"))
        #expect(draft.changes == DutyChanges(assigned: [day("2026-10-02"): id("E")]))
        #expect(try await apply(draft).savedDays == 1)
    }

    @Test("기기 저장소: 넣기와 지우기가 한 번에 저장된다")
    func applyToLocalStore() async throws {
        let repository = LiveDutyRepository(modelContainer: try LocalStore.makeInMemoryContainer())
        try await repository.assign([day("2026-10-01"): id("D"), day("2026-10-02"): id("E")])
        try await repository.apply(DutyChanges(assigned: [day("2026-10-02"): id("N"), day("2026-10-03"): id("OFF")],
                                               cleared: [day("2026-10-01")]))
        #expect(try await repository.assignments(from: day("2026-10-01"), through: day("2026-10-31"))
                == [day("2026-10-02"): id("N"), day("2026-10-03"): id("OFF")])
    }

    @Test("같은 날이 넣기와 지우기에 둘 다 있으면 넣기가 이긴다 — 두 구현이 같다", arguments: [false, true])
    func assignedWins(live: Bool) async throws {
        let repository: any DutyRepository = live
            ? LiveDutyRepository(modelContainer: try LocalStore.makeInMemoryContainer())
            : InMemoryDutyRepository([:])
        try await repository.assign([day("2026-10-01"): id("D")])
        try await repository.apply(DutyChanges(assigned: [day("2026-10-01"): id("N")], cleared: [day("2026-10-01")]))
        #expect(try await repository.assignments(from: day("2026-10-01"), through: day("2026-10-01")) == [day("2026-10-01"): id("N")])
    }
}
