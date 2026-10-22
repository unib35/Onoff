// REQ-007 · REQ-008 — 날짜 범위의 근무를 불러온다. 넣지 않은 날은 미등록(OFF 아님).
import Foundation

struct LoadDutyDaysUseCase: Sendable {
    let shiftTypes: any ShiftTypeRepository
    let duties: any DutyRepository

    /// from ... through 날짜마다 하나씩, 빠짐없이
    func callAsFunction(from: CalendarDay, through: CalendarDay) async throws -> [DutyDay] {
        let types = Dictionary(uniqueKeysWithValues: try await shiftTypes.shiftTypes().map { ($0.id, $0) })
        let assigned = try await duties.assignments(from: from, through: through)
        let count = SeoulCalendar.daysBetween(from, through)
        guard count >= 0 else { return [] }
        return (0...count).map { offset in
            let day = SeoulCalendar.adding(days: offset, to: from)
            // 알 수 없는 유형 id도 미등록으로 둔다 — OFF로 바꾸지 않는다
            if let id = assigned[day], let type = types[id] {
                return DutyDay(date: day, state: .assigned(type))
            }
            return DutyDay(date: day, state: .unregistered)
        }
    }
}

/// 근무 시간 표시용 — 「8시간 30분」 · 「182시간」
enum DurationText {
    static func hoursMinutes(_ minutes: Int) -> String {
        let h = minutes / 60, m = minutes % 60
        if m == 0 { return "\(h)시간" }
        if h == 0 { return "\(m)분" }
        return "\(h)시간 \(m)분"
    }

    static func clock(_ time: TimeOfDay) -> String {
        String(format: "%02d:%02d", time.hour, time.minute)
    }
}
