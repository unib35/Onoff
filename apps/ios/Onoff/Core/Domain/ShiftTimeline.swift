// REQ-007 · DEC-006 — 근무는 시작한 날에 속하고, N은 다음 날 종료 시각까지 이어진다
import Foundation

/// 실제 시각 위의 근무 구간
struct ShiftInterval: Hashable, Sendable {
    let start: Date
    let end: Date

    func contains(_ date: Date) -> Bool { start <= date && date < end }
}

/// 근무 시각 계산 — 코드가 아니라 근무 유형의 구간으로 계산한다.
enum ShiftTimeline {
    /// 그 날 시작한 근무의 실제 구간들. 종일 · 미등록은 빈 배열.
    static func intervals(on day: CalendarDay, state: DutyState) -> [ShiftInterval] {
        guard let type = state.shiftType else { return [] }
        return type.segments.map { segment in
            let start = SeoulCalendar.date(day, at: segment.start)
            let endDay = segment.endsNextDay ? SeoulCalendar.adding(days: 1, to: day) : day
            return ShiftInterval(start: start, end: SeoulCalendar.date(endDay, at: segment.end))
        }
    }

    /// 전날 시작한 근무가 이 날까지 이어지면 그 종료 시각(예: 전날 N → 07:30). 월말 → 월초도 같다.
    static func carryOverEnd(into day: CalendarDay, previous: DutyState) -> TimeOfDay? {
        guard let type = previous.shiftType else { return nil }
        return type.segments.last(where: \.endsNextDay)?.end
    }

    /// 그 날 하루(0–24시) 위의 근무 구간 비율 — 24시간 띠용. 다음 날로 넘는 부분은 24시에서 자른다.
    static func dayFractions(of state: DutyState) -> [ClosedRange<Double>] {
        guard let type = state.shiftType else { return [] }
        return type.segments.map { segment in
            let start = Double(segment.start.minutes) / 1440
            let end = segment.endsNextDay ? 1 : Double(segment.end.minutes) / 1440
            return start...end
        }
    }
}
