// REQ-007 · DEC-006 — 공유 테스트 표 apps/shared/fixtures/shift-timeline.json
import Foundation
import Testing
@testable import Onoff

private final class BundleToken {}

private struct TimelineFixture: Decodable {
    struct Case: Decodable {
        struct Expect: Decodable {
            let intervals: [[String]]
            let carryOverEndIntoNextDay: String?
            let workMinutes: Int
        }
        let name: String
        let date: String
        let segments: [[String]]
        let expect: Expect
    }
    let cases: [Case]

    static func load() throws -> TimelineFixture {
        let url = try #require(Bundle(for: BundleToken.self).url(forResource: "shift-timeline", withExtension: "json", subdirectory: "fixtures"))
        return try JSONDecoder().decode(TimelineFixture.self, from: Data(contentsOf: url))
    }
}

private func time(_ text: String) -> TimeOfDay {
    let parts = text.split(separator: ":").map { Int($0)! }
    return TimeOfDay(hour: parts[0], minute: parts[1])
}

private func day(_ text: String) -> CalendarDay {
    let parts = text.split(separator: "-").map { Int($0)! }
    return CalendarDay(year: parts[0], month: parts[1], day: parts[2])
}

/// "2026-10-08T22:30" (Asia/Seoul)
private func instant(_ text: String) -> Date {
    let pieces = text.split(separator: "T").map(String.init)
    return SeoulCalendar.date(day(pieces[0]), at: time(pieces[1]))
}

struct ShiftTimelineTests {
    @Test("공유 테스트 표의 모든 경우", arguments: try TimelineFixture.load().cases.map(\.name))
    func fixtureCase(name: String) throws {
        let fixtureCase = try #require(try TimelineFixture.load().cases.first { $0.name == name })
        let type = ShiftType(
            id: ShiftTypeID(rawValue: "X"), code: "X", name: "X", kind: fixtureCase.segments.isEmpty ? .off : .work,
            segments: fixtureCase.segments.map { ShiftSegment(start: time($0[0]), end: time($0[1])) },
            colorKey: "X", isHidden: false, isCustom: false
        )
        let state = DutyState.assigned(type)

        let intervals = ShiftTimeline.intervals(on: day(fixtureCase.date), state: state)
        #expect(intervals == fixtureCase.expect.intervals.map { ShiftInterval(start: instant($0[0]), end: instant($0[1])) })

        let next = SeoulCalendar.adding(days: 1, to: day(fixtureCase.date))
        #expect(ShiftTimeline.carryOverEnd(into: next, previous: state) == fixtureCase.expect.carryOverEndIntoNextDay.map(time))
        #expect(type.workMinutes == fixtureCase.expect.workMinutes)
    }

    @Test("미등록 날은 구간도 이어짐도 없다")
    func unregisteredHasNoTime() {
        #expect(ShiftTimeline.intervals(on: day("2026-11-01"), state: .unregistered).isEmpty)
        #expect(ShiftTimeline.carryOverEnd(into: day("2026-11-02"), previous: .unregistered) == nil)
        #expect(DutyState.unregistered.isOff == false)
    }

    @Test("24시간 띠: N은 그 날 24시에서 자른다")
    func dayFractionsClipAtMidnight() throws {
        let night = try #require(SampleData.shiftTypes.first { $0.code == "N" })
        let fractions = ShiftTimeline.dayFractions(of: .assigned(night))
        #expect(fractions == [(22.5 / 24)...1])
    }
}
