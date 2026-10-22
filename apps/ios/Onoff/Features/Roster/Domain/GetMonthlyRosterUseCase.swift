// REQ-007 · REQ-008 · REQ-017 · UI-IOS-1f — 월간 근무표
import Foundation

struct RosterDay: Sendable, Equatable, Identifiable {
    let duty: DutyDay
    /// 전날 근무가 이 날 아침까지 이어지면 그 종료 시각(「~7:30」)
    let carryOverEnd: TimeOfDay?
    let hasMemo: Bool
    let isToday: Bool

    var id: CalendarDay { duty.date }
}

struct MonthlyRoster: Sendable, Equatable {
    struct Count: Sendable, Equatable {
        let type: ShiftType
        let count: Int
    }

    let year: Int
    let month: Int
    /// 첫 주 앞의 빈 칸 수(일요일 시작)
    let leadingBlanks: Int
    let days: [RosterDay]
    /// 근무 유형 목록 순서, 1개 이상인 것만
    let counts: [Count]
    /// 근무(kind == .work) 시간 합(분)
    let workMinutes: Int
    let nextMonth: NextMonth

    struct NextMonth: Sendable, Equatable {
        let month: Int
        let days: [DutyDay]
        var isAllUnregistered: Bool { days.allSatisfy { $0.state == .unregistered } }
    }
}

struct GetMonthlyRosterUseCase: Sendable {
    let shiftTypes: any ShiftTypeRepository
    let loadDutyDays: LoadDutyDaysUseCase
    let memos: any MemoRepository
    let clock: any AppClock

    func callAsFunction(year: Int, month: Int) async throws -> MonthlyRoster {
        let first = CalendarDay(year: year, month: month, day: 1)
        let last = CalendarDay(year: year, month: month, day: SeoulCalendar.daysInMonth(year: year, month: month))
        let nextFirst = SeoulCalendar.adding(days: 1, to: last)
        let nextLast = CalendarDay(year: nextFirst.year, month: nextFirst.month,
                                   day: SeoulCalendar.daysInMonth(year: nextFirst.year, month: nextFirst.month))
        // 전날(지난달 말일)까지 읽어야 월초 「~7:30」이 맞다
        let days = try await loadDutyDays(from: SeoulCalendar.adding(days: -1, to: first), through: nextLast)
        let memoDays = Set(try await memos.memos(from: first, through: last).map(\.date))
        let today = SeoulCalendar.day(of: clock.now())

        var rosterDays: [RosterDay] = []
        for index in days.indices where days[index].date >= first && days[index].date <= last {
            let duty = days[index]
            let carry = duty.state.isOff ? ShiftTimeline.carryOverEnd(into: duty.date, previous: days[index - 1].state) : nil
            rosterDays.append(RosterDay(duty: duty, carryOverEnd: carry, hasMemo: memoDays.contains(duty.date), isToday: duty.date == today))
        }

        let assigned = rosterDays.compactMap(\.duty.state.shiftType)
        let order = try await shiftTypes.shiftTypes()
        let counts = order.compactMap { type -> MonthlyRoster.Count? in
            let n = assigned.filter { $0.id == type.id }.count
            return n > 0 ? MonthlyRoster.Count(type: type, count: n) : nil
        }

        return MonthlyRoster(
            year: year,
            month: month,
            leadingBlanks: SeoulCalendar.weekdayIndex(first),
            days: rosterDays,
            counts: counts,
            workMinutes: assigned.filter { $0.kind == .work }.reduce(0) { $0 + $1.workMinutes },
            nextMonth: .init(month: nextFirst.month, days: days.filter { $0.date >= nextFirst })
        )
    }
}
