// DEC-013 · REQ-005 · REQ-008 · REQ-019 — 기기 저장소(SwiftData). 가짜 데이터만.
import Foundation
import SwiftData
import Testing
@testable import Onoff

@MainActor
struct LocalStoreTests {
    private let day = TestSupport.day

    @Test("근무 유형: 처음 실행엔 기본 11개를 순서대로, 다시 실행해도 덮어쓰지 않는다")
    func seedShiftTypes() async throws {
        let store = try LocalStore.makeInMemoryContainer()
        try LiveShiftTypeRepository.seedIfEmpty(store, defaults: DefaultShiftTypes.all)
        let repository = LiveShiftTypeRepository(modelContainer: store)
        #expect(try await repository.shiftTypes() == DefaultShiftTypes.all)

        let edited = Array(try await repository.shiftTypes().reversed().dropLast())
        try await repository.replaceAll(edited)
        try LiveShiftTypeRepository.seedIfEmpty(store, defaults: DefaultShiftTypes.all)
        #expect(try await repository.shiftTypes() == edited) // 순서 유지 · 빠진 유형은 지워짐
    }

    @Test("근무 유형: 스플릿 · 날짜 넘김 구간 · 휴가 종류가 그대로 돌아온다")
    func shiftTypeRoundTrip() async throws {
        let repository = LiveShiftTypeRepository(modelContainer: try LocalStore.makeInMemoryContainer())
        let types = ["S", "N", "반차"].map(TestSupport.type)
        try await repository.replaceAll(types)
        #expect(try await repository.shiftTypes() == types)
    }

    @Test("근무표: 처음엔 비어 있다 — 기본 근무 유형만 넣고 날짜는 미등록")
    func freshLaunchIsUnregistered() async throws {
        let container = try await AppContainer.live(store: LocalStore.makeInMemoryContainer())
        let days = try await container.loadDutyDays(from: day(2026, 10, 1), through: day(2026, 10, 31))
        #expect(days.count == 31)
        #expect(days.allSatisfy { $0.state == .unregistered })
        #expect(try await container.shiftTypes.shiftTypes().count == 11)
    }

    @Test("근무표: 넣기 · 바꾸기 · 지우기(미등록으로), 범위는 월 경계에서 자른다")
    func duties() async throws {
        let repository = LiveDutyRepository(modelContainer: try LocalStore.makeInMemoryContainer())
        let n = ShiftTypeID(rawValue: "N"), off = ShiftTypeID(rawValue: "OFF"), d = ShiftTypeID(rawValue: "D")
        try await repository.assign([day(2026, 10, 31): n, day(2026, 11, 1): off, day(2026, 11, 2): d])
        try await repository.assign([day(2026, 11, 2): n])
        #expect(try await repository.assignments(from: day(2026, 11, 1), through: day(2026, 11, 30))
                == [day(2026, 11, 1): off, day(2026, 11, 2): n])

        try await repository.clear([day(2026, 11, 1)])
        let all = try await repository.assignments(from: day(2026, 10, 1), through: day(2026, 12, 31))
        #expect(all == [day(2026, 10, 31): n, day(2026, 11, 2): n]) // 지운 날은 OFF가 아니라 없음
    }

    @Test("근무표: 연말을 넘는 범위")
    func yearBoundary() async throws {
        let repository = LiveDutyRepository(modelContainer: try LocalStore.makeInMemoryContainer())
        let n = ShiftTypeID(rawValue: "N")
        try await repository.assign([day(2026, 12, 31): n, day(2027, 1, 1): n, day(2027, 2, 1): n])
        #expect(try await repository.assignments(from: day(2026, 12, 1), through: day(2027, 1, 31)).count == 2)
    }

    @Test("메모: 저장 · 고치기 · 지우기, 시각 없는 메모도 그대로")
    func memos() async throws {
        let repository = LiveMemoRepository(modelContainer: try LocalStore.makeInMemoryContainer())
        var dinner = Memo(id: UUID(), date: day(2026, 10, 12), time: TimeOfDay(hour: 19), text: "저녁 약속")
        let note = Memo(id: UUID(), date: day(2026, 10, 12), time: nil, text: "챙길 것")
        try await repository.save(dinner)
        try await repository.save(note)
        dinner.text = "저녁 약속 변경"
        try await repository.save(dinner)
        let saved = try await repository.memos(from: day(2026, 10, 12), through: day(2026, 10, 12))
        #expect(Set(saved) == [dinner, note])

        try await repository.delete(id: dinner.id)
        #expect(try await repository.memos(from: day(2026, 10, 1), through: day(2026, 10, 31)) == [note])
        #expect(try await repository.memos(from: day(2026, 11, 1), through: day(2026, 11, 30)).isEmpty)
    }

    @Test("앱을 껐다 켜도 남는다 — 같은 파일을 새 저장소로 다시 연다")
    func survivesRelaunch() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("Onoff.store")
        let memo = Memo(id: UUID(), date: day(2026, 10, 7), time: nil, text: "가짜 메모")

        do {
            let first = try await AppContainer.live(store: LocalStore.makeContainer(at: url))
            try await first.duties.assign([day(2026, 10, 7): ShiftTypeID(rawValue: "OFF")])
            try await first.memos.save(memo)
        }

        let second = try await AppContainer.live(store: LocalStore.makeContainer(at: url))
        #expect(try await second.duties.assignments(from: day(2026, 10, 1), through: day(2026, 10, 31))
                == [day(2026, 10, 7): ShiftTypeID(rawValue: "OFF")])
        #expect(try await second.memos.memos(from: day(2026, 10, 7), through: day(2026, 10, 7)) == [memo])
        #expect(try await second.shiftTypes.shiftTypes().count == 11) // 다시 넣지 않음
    }

    @Test("메모 날짜를 바꿔 저장하면 원래 날에서 빠지고 새 날에 나온다")
    func memoMovesDay() async throws {
        let repository = LiveMemoRepository(modelContainer: try LocalStore.makeInMemoryContainer())
        let memo = Memo(id: UUID(), date: day(2026, 10, 6), time: nil, text: "가짜 메모")
        try await repository.save(memo)
        let moved = Memo(id: memo.id, date: day(2026, 10, 8), time: TimeOfDay(hour: 9), text: memo.text)
        try await repository.save(moved)
        #expect(try await repository.memos(from: day(2026, 10, 6), through: day(2026, 10, 6)).isEmpty)
        #expect(try await repository.memos(from: day(2026, 10, 8), through: day(2026, 10, 8)) == [moved])
    }

    @Test("지운 근무 유형을 가리키던 날은 미등록 — OFF로 보이지 않는다")
    func removedTypeBecomesUnregistered() async throws {
        let container = try await AppContainer.live(store: LocalStore.makeInMemoryContainer())
        try await container.duties.assign([day(2026, 10, 9): ShiftTypeID(rawValue: "M")])
        try await container.shiftTypes.replaceAll(DefaultShiftTypes.all.filter { $0.id.rawValue != "M" })
        let days = try await container.loadDutyDays(from: day(2026, 10, 9), through: day(2026, 10, 9))
        #expect(days.first?.state == .unregistered)
    }
}
