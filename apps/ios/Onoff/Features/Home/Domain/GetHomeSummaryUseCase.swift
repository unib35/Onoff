// REQ-016 · DEC-012 · UI-IOS-12a — 홈: 오늘 · 내일 · 다음 OFF · 이번 주
import Foundation

struct HomeSummary: Sendable, Equatable {
    struct NextOff: Sendable, Equatable {
        let date: CalendarDay
        /// 오늘부터 며칠 후
        let daysFromToday: Int
    }

    let today: DutyDay
    /// 오늘 근무가 아직 시작 전이면 남은 분
    let minutesUntilStart: Int?
    /// 지금 시각(0...1) — 24시간 띠 표시
    let nowFraction: Double
    let tomorrow: DutyDay
    let nextOff: NextOff?
    /// 이번 주(일–토) 7일
    let week: [DutyDay]
}

struct GetHomeSummaryUseCase: Sendable {
    let loadDutyDays: LoadDutyDaysUseCase
    let clock: any AppClock
    /// 다음 OFF를 찾는 범위(일)
    var searchDays = 60

    func callAsFunction() async throws -> HomeSummary {
        let now = clock.now()
        let today = SeoulCalendar.day(of: now)
        let weekStart = SeoulCalendar.adding(days: -SeoulCalendar.weekdayIndex(today), to: today)
        let weekEnd = SeoulCalendar.adding(days: 6, to: weekStart)
        let searchEnd = max(weekEnd, SeoulCalendar.adding(days: searchDays, to: today))
        let days = try await loadDutyDays(from: weekStart, through: searchEnd)
        let byDate = Dictionary(uniqueKeysWithValues: days.map { ($0.date, $0) })

        let todayDuty = byDate[today]!
        let start = ShiftTimeline.intervals(on: today, state: todayDuty.state).first?.start
        let minutesUntilStart = start.flatMap { $0 > now ? Int($0.timeIntervalSince(now) / 60) : nil }

        // 미등록 날은 OFF로 세지 않는다(REQ-008)
        let nextOff = days
            .filter { $0.date > today && $0.state.isOff }
            .first
            .map { HomeSummary.NextOff(date: $0.date, daysFromToday: SeoulCalendar.daysBetween(today, $0.date)) }

        let midnight = SeoulCalendar.startOfDay(today)
        return HomeSummary(
            today: todayDuty,
            minutesUntilStart: minutesUntilStart,
            nowFraction: now.timeIntervalSince(midnight) / 86_400,
            tomorrow: byDate[SeoulCalendar.adding(days: 1, to: today)]!,
            nextOff: nextOff,
            week: days.filter { $0.date >= weekStart && $0.date <= weekEnd }
        )
    }
}
