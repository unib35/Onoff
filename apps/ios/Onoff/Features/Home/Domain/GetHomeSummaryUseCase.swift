// REQ-007 · REQ-016 · DEC-012 · UI-IOS-12a — 홈: 오늘 · 내일 · 다음 OFF · 이번 주
import Foundation

struct HomeSummary: Sendable, Equatable {
    struct NextOff: Sendable, Equatable {
        let date: CalendarDay
        let type: ShiftType
        /// 오늘부터 며칠 후
        let daysFromToday: Int
    }

    let today: DutyDay
    /// 오늘 시작하는 다음 근무 구간까지 남은 분(근무 중이면 nil)
    let minutesUntilStart: Int?
    /// 지금 근무 중이면 끝나는 시각 — 전날 시작한 N이 이어지는 아침도 포함(REQ-007)
    let workingUntil: TimeOfDay?
    /// 오늘 하루(0–24시) 위의 근무 구간 — 24시간 띠
    let todayBand: [ClosedRange<Double>]
    /// 지금 시각(0...1)
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
        let yesterday = SeoulCalendar.adding(days: -1, to: today)
        let weekStart = SeoulCalendar.adding(days: -SeoulCalendar.weekdayIndex(today), to: today)
        let weekEnd = SeoulCalendar.adding(days: 6, to: weekStart)
        let searchEnd = max(weekEnd, SeoulCalendar.adding(days: searchDays, to: today))
        let days = try await loadDutyDays(from: min(weekStart, yesterday), through: searchEnd)
        let byDate = Dictionary(uniqueKeysWithValues: days.map { ($0.date, $0) })

        let todayDuty = byDate[today]!
        let todayIntervals = ShiftTimeline.intervals(on: today, state: todayDuty.state)
        let running = (ShiftTimeline.intervals(on: yesterday, state: byDate[yesterday]!.state) + todayIntervals)
            .first { $0.contains(now) }
        // 근무 중이 아닐 때만, 아직 시작 전인 첫 구간까지(스플릿은 다음 구간). 남은 초는 올림.
        let minutesUntilStart = running == nil
            ? todayIntervals.first { $0.start > now }.map { Int(($0.start.timeIntervalSince(now) / 60).rounded(.up)) }
            : nil

        // 미등록 날은 OFF로 세지 않는다(REQ-008)
        let nextOff = days
            .first { $0.date > today && $0.state.isOff }
            .flatMap { day in day.state.shiftType.map { HomeSummary.NextOff(date: day.date, type: $0, daysFromToday: SeoulCalendar.daysBetween(today, day.date)) } }

        return HomeSummary(
            today: todayDuty,
            minutesUntilStart: minutesUntilStart,
            workingUntil: running.map { SeoulCalendar.timeOfDay(of: $0.end) },
            todayBand: ShiftTimeline.dayFractions(of: todayDuty.state),
            nowFraction: now.timeIntervalSince(SeoulCalendar.startOfDay(today)) / 86_400,
            tomorrow: byDate[SeoulCalendar.adding(days: 1, to: today)]!,
            nextOff: nextOff,
            week: days.filter { $0.date >= weekStart && $0.date <= weekEnd }
        )
    }
}
