// REQ-011 · UI-IOS-11c — 끌어서 칠하기 한 번(길게 누른 칸 → 손가락이 있는 칸).
// 「지나간 날이 모두 칠해져요. 되돌아가면 지워지고」 — 칠할 날은 시작 칸과 지금 칸 사이의 모든 날(날짜 순서).
// 손을 뗄 때 DutyDraft.paint로 한 번에 넣는다.
import Foundation

struct PaintStroke: Hashable, Sendable {
    let anchor: CalendarDay
    private(set) var current: CalendarDay

    init(anchor: CalendarDay) {
        self.anchor = anchor
        current = anchor
    }

    /// 손가락이 다른 칸으로 — 되돌아가면 그만큼 줄어든다
    mutating func move(to day: CalendarDay) { current = day }

    var first: CalendarDay { min(anchor, current) }
    var last: CalendarDay { max(anchor, current) }

    /// 칠할 날 — 날짜 순서
    var days: [CalendarDay] {
        (0...SeoulCalendar.daysBetween(first, last)).map { SeoulCalendar.adding(days: $0, to: first) }
    }

    func contains(_ day: CalendarDay) -> Bool { first <= day && day <= last }
}
