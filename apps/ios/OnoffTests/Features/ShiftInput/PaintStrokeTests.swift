// REQ-011 · UI-IOS-11c — 끌어서 칠하기 한 번의 범위. 가짜 데이터만.
import Testing
@testable import Onoff

struct PaintStrokeTests {
    private func day(_ d: Int) -> CalendarDay { TestSupport.day(2026, 11, d) }

    @Test("시작 칸만 · 앞으로 · 거꾸로 · 되돌아가기")
    func range() {
        var stroke = PaintStroke(anchor: day(12))
        #expect(stroke.days == [day(12)])
        stroke.move(to: day(16))
        #expect(stroke.days == [day(12), day(13), day(14), day(15), day(16)])
        stroke.move(to: day(10))
        #expect(stroke.days == [day(10), day(11), day(12)])
        #expect(stroke.first == day(10) && stroke.last == day(12) && stroke.current == day(10))
        stroke.move(to: day(12))
        #expect(stroke.days == [day(12)])
    }

    @Test("포함 경계 · 달 경계를 넘는 날짜 계산")
    func contains() {
        var stroke = PaintStroke(anchor: day(29))
        stroke.move(to: TestSupport.day(2026, 12, 2))
        #expect(stroke.days.count == 4)
        #expect(stroke.contains(day(29)) && stroke.contains(TestSupport.day(2026, 12, 2)))
        #expect(!stroke.contains(day(28)) && !stroke.contains(TestSupport.day(2026, 12, 3)))
    }
}
