// REQ-005 · UI-IOS-5b
import Testing
@testable import Onoff

struct GetShiftTypesUseCaseTests {
    @Test("키패드에 보이는 근무 9 · 숨김 2, 목록 순서 유지")
    func visibleAndHidden() async throws {
        let list = try await GetShiftTypesUseCase(repository: InMemoryShiftTypeRepository(SampleData.shiftTypes))()
        #expect(list.visible.map(\.code) == ["D", "E", "N", "OFF", "M", "교육", "S", "연차", "반차"])
        #expect(list.hidden.map(\.code) == ["병가", "공가"])
    }

    @Test("원본 5b 시각 표기")
    func timeText() {
        #expect(ShiftFormat.compactTime(TestSupport.type("D")) == "07:00–15:30")
        #expect(ShiftFormat.compactTime(TestSupport.type("N")) == "22:30–다음 날 07:30")
        #expect(ShiftFormat.compactTime(TestSupport.type("OFF")) == "종일")
        #expect(ShiftFormat.compactTime(TestSupport.type("S")) == "07:00–11:00 · 17:00–21:00")
        #expect(ShiftFormat.compactTime(TestSupport.type("반차")) == "11:00–15:30 근무")
        #expect(ShiftFormat.nameAndDuration(TestSupport.type("E")) == "이브닝 · 8시간 30분")
    }
}
