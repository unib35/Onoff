// REQ-008 — 메모리 구현(샘플 · 테스트). 로컬 저장소 구현은 다음 이슈.
import Foundation

final class InMemoryDutyRepository: DutyRepository {
    private let assignments: [CalendarDay: ShiftTypeID]

    init(_ assignments: [CalendarDay: ShiftTypeID]) { self.assignments = assignments }

    func assignments(from: CalendarDay, through: CalendarDay) async throws -> [CalendarDay: ShiftTypeID] {
        assignments.filter { $0.key >= from && $0.key <= through }
    }
}
