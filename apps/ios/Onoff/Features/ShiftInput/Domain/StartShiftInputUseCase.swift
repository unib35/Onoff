// REQ-009 · UI-IOS-14a — 입력 시작: 그 기간에 저장된 근무로 초안을 만들고, 키패드에 보일 근무 유형을 준다
import Foundation

struct ShiftInputSession: Hashable, Sendable {
    var draft: DutyDraft
    /// 키패드 순서 = 근무 유형 목록 순서, 숨긴 유형 제외(REQ-005)
    let keypadTypes: [ShiftType]
}

struct StartShiftInputUseCase: Sendable {
    let shiftTypes: any ShiftTypeRepository
    let duties: any DutyRepository

    /// - Parameter cursor: 처음 커서 날(누른 날). 없으면 기간 첫날
    func callAsFunction(range: ClosedRange<CalendarDay>, cursor: CalendarDay? = nil) async throws -> ShiftInputSession {
        async let types = shiftTypes.shiftTypes()
        async let saved = duties.assignments(from: range.lowerBound, through: range.upperBound)
        let allTypes = try await types
        let protected = Set(allTypes.filter { $0.kind == .leave }.map(\.id))
        let draft = DutyDraft(range: range, original: try await saved, protectedTypes: protected, cursor: cursor)
        return ShiftInputSession(draft: draft, keypadTypes: allTypes.filter { !$0.isHidden })
    }

    /// 한 달 전체 기간
    static func month(year: Int, month: Int) -> ClosedRange<CalendarDay> {
        CalendarDay(year: year, month: month, day: 1)...CalendarDay(year: year, month: month, day: SeoulCalendar.daysInMonth(year: year, month: month))
    }
}
