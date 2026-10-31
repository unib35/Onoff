// REQ-008 — 메모리 구현(미리보기 · 테스트). 기기 저장은 LiveDutyRepository.
import Foundation

actor InMemoryDutyRepository: DutyRepository {
    private var assignments: [CalendarDay: ShiftTypeID]

    init(_ assignments: [CalendarDay: ShiftTypeID]) { self.assignments = assignments }

    func assignments(from: CalendarDay, through: CalendarDay) async throws -> [CalendarDay: ShiftTypeID] {
        assignments.filter { $0.key >= from && $0.key <= through }
    }

    func assign(_ assignments: [CalendarDay: ShiftTypeID]) async throws {
        self.assignments.merge(assignments) { _, new in new }
    }

    func clear(_ days: [CalendarDay]) async throws {
        for day in days { assignments[day] = nil }
    }
}
