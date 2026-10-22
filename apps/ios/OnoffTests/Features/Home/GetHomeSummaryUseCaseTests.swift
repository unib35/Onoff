// REQ-016 · DEC-012 · UI-IOS-12a — 원본 12a 샘플 값(2026-10-04 09:41)
import Foundation
import Testing
@testable import Onoff

struct GetHomeSummaryUseCaseTests {
    private func useCase(_ duties: [CalendarDay: ShiftTypeID] = SampleData.octoberDuties,
                         now: Date = SampleData.referenceNow) -> GetHomeSummaryUseCase {
        GetHomeSummaryUseCase(loadDutyDays: TestSupport.loadDutyDays(duties), clock: FixedClock(date: now))
    }

    @Test("오늘 E · 출근까지 4시간 49분 · 내일 E · 다음 OFF 3일 후 10/7")
    func referenceSample() async throws {
        let summary = try await useCase()()
        #expect(summary.today.state.shiftType?.code == "E")
        #expect(summary.minutesUntilStart == 4 * 60 + 49)
        #expect(summary.tomorrow.state.shiftType?.code == "E")
        #expect(summary.nextOff == .init(date: TestSupport.day(2026, 10, 7), type: TestSupport.type("OFF"), daysFromToday: 3))
        #expect(summary.workingUntil == nil)
        #expect(abs(summary.nowFraction - (9 * 60 + 41) / 1440.0) < 0.0001)
    }

    @Test("이번 주는 일요일부터 7일")
    func weekStartsSunday() async throws {
        let summary = try await useCase()()
        #expect(summary.week.map(\.date.day) == [4, 5, 6, 7, 8, 9, 10])
        #expect(summary.week.compactMap(\.state.shiftType?.code) == ["E", "E", "E", "OFF", "N", "N", "N"])
    }

    @Test("근무가 시작한 뒤에는 출근까지를 보이지 않는다")
    func noCountdownAfterStart() async throws {
        let afterStart = SeoulCalendar.date(TestSupport.day(2026, 10, 4), at: TimeOfDay(hour: 15))
        #expect(try await useCase(now: afterStart)().minutesUntilStart == nil)
    }

    @Test("미등록 날은 다음 OFF로 세지 않는다")
    func unregisteredIsNotNextOff() async throws {
        let onlyToday = [TestSupport.day(2026, 10, 4): ShiftTypeID(rawValue: "E")]
        let summary = try await useCase(onlyToday)()
        #expect(summary.nextOff == nil)
        #expect(summary.tomorrow.state == .unregistered)
    }

    @Test("전날 N이 이어지는 아침(다음 날 OFF)은 근무 중 — 출근까지 대신 퇴근 예정 07:30")
    func carriedNightOnOffDay() async throws {
        let at3 = SeoulCalendar.date(TestSupport.day(2026, 10, 11), at: TimeOfDay(hour: 3))
        let summary = try await useCase(now: at3)()
        #expect(summary.today.state.shiftType?.code == "OFF")
        #expect(summary.minutesUntilStart == nil)
        #expect(summary.workingUntil == TimeOfDay(hour: 7, minute: 30))
    }

    @Test("N이 이틀 이어지면 새벽엔 근무 중 — 오늘 밤 N까지 남은 시간을 보이지 않는다")
    func consecutiveNights() async throws {
        let at3 = SeoulCalendar.date(TestSupport.day(2026, 10, 9), at: TimeOfDay(hour: 3))
        let summary = try await useCase(now: at3)()
        #expect(summary.minutesUntilStart == nil)
        #expect(summary.workingUntil == TimeOfDay(hour: 7, minute: 30))
        let at8 = SeoulCalendar.date(TestSupport.day(2026, 10, 9), at: TimeOfDay(hour: 8))
        #expect(try await useCase(now: at8)().minutesUntilStart == 14 * 60 + 30)
    }

    @Test("스플릿: 첫 구간이 끝나면 두 번째 구간까지 남은 시간")
    func splitSecondSegment() async throws {
        let target = TestSupport.day(2026, 10, 4)
        let noon = SeoulCalendar.date(target, at: TimeOfDay(hour: 12))
        let summary = try await useCase([target: ShiftTypeID(rawValue: "S")], now: noon)()
        #expect(summary.minutesUntilStart == 5 * 60)
        #expect(summary.workingUntil == nil)
    }

    @Test("남은 초는 올림 — 59초 남으면 1분")
    func roundsUp() async throws {
        let almost = SampleData.referenceNow.addingTimeInterval(4 * 3600 + 48 * 60 + 1)
        #expect(try await useCase(now: almost)().minutesUntilStart == 1)
    }
}
