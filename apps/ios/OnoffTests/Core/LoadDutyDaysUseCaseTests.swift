// REQ-008 — 미등록은 OFF가 아니다
import Testing
@testable import Onoff

struct LoadDutyDaysUseCaseTests {
    @Test("넣지 않은 날은 미등록으로 빠짐없이 나온다")
    func missingDaysAreUnregistered() async throws {
        let days = try await TestSupport.loadDutyDays()(from: TestSupport.day(2026, 10, 30), through: TestSupport.day(2026, 11, 2))
        #expect(days.map(\.date) == [TestSupport.day(2026, 10, 30), TestSupport.day(2026, 10, 31), TestSupport.day(2026, 11, 1), TestSupport.day(2026, 11, 2)])
        #expect(days[0].state.shiftType?.code == "OFF")
        #expect(days[1].state.shiftType?.code == "E")
        #expect(days[2].state == .unregistered)
        #expect(days[3].state == .unregistered)
        #expect(!days[2].state.isOff)
    }

    @Test("알 수 없는 근무 유형도 OFF로 바꾸지 않고 미등록")
    func unknownTypeIsNotOff() async throws {
        let target = TestSupport.day(2026, 10, 1)
        let days = try await TestSupport.loadDutyDays([target: ShiftTypeID(rawValue: "지워진-유형")])(from: target, through: target)
        #expect(days.first?.state == .unregistered)
    }
}
