// 근무 시각 · 날짜 표시 문구 — 원본 화면 표기 그대로
import Foundation

enum ShiftFormat {
    /// 「07:00–15:30」 · 「22:30–다음 날 07:30」 · 「07:00–11:00 · 17:00–21:00」 · 「종일」 (5b · 12a 내일)
    static func compactTime(_ type: ShiftType) -> String {
        guard !type.isAllDay else { return "종일" }
        let text = type.segments.map { segment in
            let end = (segment.endsNextDay ? "다음 날 " : "") + DurationText.clock(segment.end)
            return DurationText.clock(segment.start) + "–" + end
        }.joined(separator: " · ")
        return type.timeSuffix.map { "\(text) \($0)" } ?? text
    }

    /// 「14:30 – 23:00」 큰 표기(12a · 3c). 다음 날 종료도 시각만.
    static func wideTime(_ type: ShiftType) -> String {
        guard let first = type.segments.first, let last = type.segments.last else { return "종일" }
        return DurationText.clock(first.start) + " – " + DurationText.clock(last.end)
    }

    /// 「이브닝 · 8시간 30분」
    static func nameAndDuration(_ type: ShiftType) -> String {
        type.isAllDay ? type.name : "\(type.name) · \(DurationText.hoursMinutes(type.workMinutes))"
    }

    static let weekdays = ["일", "월", "화", "수", "목", "금", "토"]

    static func weekday(_ day: CalendarDay) -> String { weekdays[SeoulCalendar.weekdayIndex(day)] }

    /// 「10월 4일 일요일」
    static func longDate(_ day: CalendarDay) -> String { "\(day.month)월 \(day.day)일 \(weekday(day))요일" }

    /// 「10월 12일 (월)」
    static func titleDate(_ day: CalendarDay) -> String { "\(day.month)월 \(day.day)일 (\(weekday(day)))" }

    /// 「10/7 (수)」
    static func shortDate(_ day: CalendarDay) -> String { "\(day.month)/\(day.day) (\(weekday(day)))" }

    /// 「4시간 49분」
    static func remaining(_ minutes: Int) -> String { DurationText.hoursMinutes(minutes) }
}
