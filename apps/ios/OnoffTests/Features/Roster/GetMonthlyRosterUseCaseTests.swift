// REQ-007 · REQ-008 · REQ-017 · UI-IOS-1f — 원본 1f 샘플 값과 같아야 한다
import Testing
@testable import Onoff

struct GetMonthlyRosterUseCaseTests {
    private func useCase(_ duties: [CalendarDay: ShiftTypeID] = SampleData.octoberDuties) -> GetMonthlyRosterUseCase {
        GetMonthlyRosterUseCase(
            shiftTypes: InMemoryShiftTypeRepository(SampleData.shiftTypes),
            loadDutyDays: TestSupport.loadDutyDays(duties),
            memos: InMemoryMemoRepository(SampleData.memos),
            clock: TestSupport.referenceClock
        )
    }

    @Test("10월 예정 · D 8 · E 6 · N 7 · OFF 10 · 182시간")
    func octoberSummary() async throws {
        let roster = try await useCase()(year: 2026, month: 10)
        #expect(roster.counts.map { "\($0.type.code) \($0.count)" } == ["D 8", "E 6", "N 7", "OFF 10"])
        #expect(roster.workMinutes == 182 * 60)
        #expect(roster.leadingBlanks == 4) // 10월 1일은 목요일
        #expect(roster.days.count == 31)
    }

    @Test("전날 N 다음 OFF에만 ~7:30")
    func carryOverOnlyAfterNight() async throws {
        let roster = try await useCase()(year: 2026, month: 10)
        let carried = roster.days.filter { $0.carryOverEnd != nil }.map(\.duty.date.day)
        #expect(carried == [11, 15, 29])
        #expect(roster.days.first { $0.duty.date.day == 11 }?.carryOverEnd == TimeOfDay(hour: 7, minute: 30))
    }

    @Test("오늘 · 메모 표시")
    func todayAndMemo() async throws {
        let roster = try await useCase()(year: 2026, month: 10)
        #expect(roster.days.filter(\.isToday).map(\.duty.date.day) == [4])
        #expect(roster.days.filter(\.hasMemo).map(\.duty.date.day) == [6, 7, 12, 17])
    }

    @Test("11월은 전부 미등록 — OFF로 세지 않는다")
    func nextMonthUnregistered() async throws {
        let roster = try await useCase()(year: 2026, month: 10)
        #expect(roster.nextMonth.month == 11)
        #expect(roster.nextMonth.days.count == 30)
        #expect(roster.nextMonth.isAllUnregistered)
    }

    @Test("월 경계: 10/31 N이면 11/1 OFF에 ~7:30")
    func carryOverAcrossMonth() async throws {
        var duties = SampleData.octoberDuties
        duties[TestSupport.day(2026, 10, 31)] = ShiftTypeID(rawValue: "N")
        duties[TestSupport.day(2026, 11, 1)] = ShiftTypeID(rawValue: "OFF")
        let november = try await useCase(duties)(year: 2026, month: 11)
        #expect(november.days.first?.carryOverEnd == TimeOfDay(hour: 7, minute: 30))
        #expect(november.days[1].duty.state == .unregistered)
        #expect(november.leadingBlanks == 0) // 11월 1일은 일요일
    }
}
