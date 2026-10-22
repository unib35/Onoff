// DEC-006 — 시간대는 Asia/Seoul 고정
import Foundation

/// 날짜 · 시각 계산은 모두 이 달력으로 한다. 기기 시간대를 쓰지 않는다.
enum SeoulCalendar {
    static let timeZone = TimeZone(identifier: "Asia/Seoul")!

    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        calendar.locale = Locale(identifier: "ko_KR")
        calendar.firstWeekday = 1 // 일요일 시작(원본 달력)
        return calendar
    }()

    static func day(of date: Date) -> CalendarDay {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return CalendarDay(year: c.year!, month: c.month!, day: c.day!)
    }

    /// 그 날 0시
    static func startOfDay(_ day: CalendarDay) -> Date {
        calendar.date(from: DateComponents(year: day.year, month: day.month, day: day.day))!
    }

    static func date(_ day: CalendarDay, at time: TimeOfDay) -> Date {
        startOfDay(day).addingTimeInterval(TimeInterval(time.minutes * 60))
    }

    static func adding(days: Int, to day: CalendarDay) -> CalendarDay {
        self.day(of: calendar.date(byAdding: .day, value: days, to: startOfDay(day))!)
    }

    /// 0 = 일요일 … 6 = 토요일
    static func weekdayIndex(_ day: CalendarDay) -> Int {
        calendar.component(.weekday, from: startOfDay(day)) - 1
    }

    static func daysInMonth(year: Int, month: Int) -> Int {
        let first = startOfDay(CalendarDay(year: year, month: month, day: 1))
        return calendar.range(of: .day, in: .month, for: first)!.count
    }

    static func daysBetween(_ from: CalendarDay, _ to: CalendarDay) -> Int {
        calendar.dateComponents([.day], from: startOfDay(from), to: startOfDay(to)).day!
    }
}
