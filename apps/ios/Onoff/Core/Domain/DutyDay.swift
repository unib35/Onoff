// REQ-008 · DEC-006
import Foundation

/// 달력 날짜(Asia/Seoul 기준 연 · 월 · 일). 시각을 갖지 않는다.
struct CalendarDay: Hashable, Sendable, Codable, Comparable {
    let year: Int
    let month: Int
    let day: Int

    static func < (lhs: CalendarDay, rhs: CalendarDay) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }
}

/// 날짜 하나의 근무 상태. **미등록은 OFF가 아니다**(REQ-008).
enum DutyState: Hashable, Sendable {
    /// 정보 없음 — 근무표를 아직 넣지 않은 날
    case unregistered
    case assigned(ShiftType)

    var shiftType: ShiftType? {
        if case let .assigned(type) = self { return type }
        return nil
    }

    var isOff: Bool { shiftType?.kind == .off }
}

struct DutyDay: Hashable, Sendable {
    let date: CalendarDay
    let state: DutyState
}
