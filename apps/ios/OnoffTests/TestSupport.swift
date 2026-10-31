// 테스트 공통 — 가짜 데이터만(code.md)
import Foundation
@testable import Onoff

enum TestSupport {
    static func day(_ y: Int, _ m: Int, _ d: Int) -> CalendarDay { CalendarDay(year: y, month: m, day: d) }

    static func type(_ code: String) -> ShiftType {
        SampleData.shiftTypes.first { $0.code == code }!
    }

    static func loadDutyDays(_ duties: [CalendarDay: ShiftTypeID] = SampleData.octoberDuties,
                             types: [ShiftType] = SampleData.shiftTypes) -> LoadDutyDaysUseCase {
        LoadDutyDaysUseCase(shiftTypes: InMemoryShiftTypeRepository(types), duties: InMemoryDutyRepository(duties))
    }

    static let referenceClock = FixedClock(date: SampleData.referenceNow)
}
