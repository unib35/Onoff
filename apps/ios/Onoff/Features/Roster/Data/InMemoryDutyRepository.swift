// REQ-008 — 메모리 구현(미리보기 · 테스트). 기기 저장은 LiveDutyRepository.
import Foundation

actor InMemoryDutyRepository: DutyRepository {
    private var assignments: [CalendarDay: ShiftTypeID]

    init(_ assignments: [CalendarDay: ShiftTypeID]) { self.assignments = assignments }

    func assignments(from: CalendarDay, through: CalendarDay) async throws -> [CalendarDay: ShiftTypeID] {
        assignments.filter { $0.key >= from && $0.key <= through }
    }

    func apply(_ changes: DutyChanges) async throws {
        for day in changes.cleared { assignments[day] = nil }
        assignments.merge(changes.assigned) { _, new in new }
    }
}
