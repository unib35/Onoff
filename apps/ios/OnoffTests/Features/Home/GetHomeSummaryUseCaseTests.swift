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
        #expect(summary.nextOff == .init(date: TestSupport.day(2026, 10, 7), daysFromToday: 3))
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
}
