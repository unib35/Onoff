// REQ-018 · REQ-019 · REQ-038 · UI-IOS-3c — 날짜 상세(1.0: 근무 · 메모만)
import Foundation

struct DayDetail: Sendable, Equatable {
    struct MemoItem: Sendable, Equatable, Identifiable {
        let memo: Memo
        /// 메모 시각이 그 날 근무 시간과 겹침(REQ-019)
        let overlapsShift: Bool
        var id: UUID { memo.id }
    }

    let duty: DutyDay
    let bandSegments: [ClosedRange<Double>]
    let memos: [MemoItem]
    /// 「이 날 근무 바꾸기」 빠른 선택 — 앞쪽 근무 4개 + 첫 휴가
    let quickOptions: [ShiftType]
}

struct GetDayDetailUseCase: Sendable {
    let shiftTypes: any ShiftTypeRepository
    let loadDutyDays: LoadDutyDaysUseCase
    let memos: any MemoRepository

    func callAsFunction(_ day: CalendarDay) async throws -> DayDetail {
        let days = try await loadDutyDays(from: SeoulCalendar.adding(days: -1, to: day), through: day)
        let previous = days[0], duty = days[1]
        // 전날 시작해 이 날까지 이어지는 근무도 겹침 판단에 넣는다(N 날짜 넘김)
        let intervals = ShiftTimeline.intervals(on: previous.date, state: previous.state)
            + ShiftTimeline.intervals(on: day, state: duty.state)
        let items = try await memos.memos(from: day, through: day)
            .sorted { ($0.time?.minutes ?? Int.max) < ($1.time?.minutes ?? Int.max) }
            .map { memo in
                let overlaps = memo.time.map { t in intervals.contains { $0.contains(SeoulCalendar.date(day, at: t)) } } ?? false
                return DayDetail.MemoItem(memo: memo, overlapsShift: overlaps)
            }

        let visible = try await shiftTypes.shiftTypes().filter { !$0.isHidden }
        let firstLeave = visible.first { $0.kind == .leave }
        let quick = Array(visible.filter { $0.kind != .leave }.prefix(4)) + (firstLeave.map { [$0] } ?? [])

        return DayDetail(
            duty: duty,
            bandSegments: ShiftTimeline.dayFractions(of: duty.state),
            memos: items,
            quickOptions: quick
        )
    }
}
