// REQ-013 · UI-IOS-22a · UI-IOS-22b — 순서 반복 설정: 순서 칸 · 첫날 위치 · 몇 달 · 휴가 뒤 · 이미 넣은 근무.
// 칸 글자는 내 근무 유형(22a). 누르면 바로 저장하고, 저장한 것은 한 번에 되돌린다(DutyDraft.revertChanges).
import Foundation

struct RepeatPlan: Hashable, Sendable {
    /// 순서 칸 — 22b에서 고치면 프리셋은 「직접」
    var pattern: [ShiftTypeID]
    /// 첫날(시작 달 1일)이 순서 몇 번째 칸인지 — 0부터
    var startIndex: Int
    var afterLeave: DutyDraft.AfterLeave = .continue
    /// 「이미 넣은 근무 · 그대로」
    var keepExisting = true

    /// 22b 「지우기 · 이 칸 빼기」는 2칸까지만
    static let minimumLength = 2

    /// 첫날 근무 — 「11월 1일 근무 D · 2번째」
    var firstDayShift: ShiftTypeID? { pattern.isEmpty ? nil : pattern[startIndex % pattern.count] }

    /// 기간 첫날부터 `end`까지 채운 초안. 바뀐 날(`changes`)이 저장할 것이다.
    func filled(_ base: DutyDraft, through end: CalendarDay) -> DutyDraft {
        guard !pattern.isEmpty else { return base }
        let first = base.range.lowerBound
        // 첫날이 startIndex번째가 되도록 순서를 돌린다
        let shift = startIndex % pattern.count
        let rotated = Array(pattern[shift...] + pattern[..<shift])
        var draft = base
        draft.repeatPattern(rotated, from: first, through: end, afterLeave: afterLeave, keepExisting: keepExisting)
        return draft
    }

    // MARK: - 22b 칸 고치기

    /// 칸을 바꾼다 — 끝 다음 칸(「+」)이면 끝에 붙인다
    mutating func set(_ shift: ShiftTypeID, at index: Int) {
        if index >= pattern.count { pattern.append(shift) } else { pattern[index] = shift }
    }

    /// 칸을 빼고 뒤를 당긴다(최소 2칸). 첫날 위치는 같은 칸을 가리키게 맞춘다.
    mutating func remove(at index: Int) {
        guard pattern.count > Self.minimumLength, pattern.indices.contains(index) else { return }
        pattern.remove(at: index)
        if index < startIndex { startIndex -= 1 }
        startIndex = min(startIndex, pattern.count - 1)
    }
}

/// 22a 프리셋 칩. 칸 글자는 기본 근무 유형 id(D · N · OFF) — 사용자에게 없으면 그 프리셋은 쓸 수 없다.
enum RepeatPreset: String, CaseIterable, Hashable, Sendable {
    case fourTeamTwoShift
    case nightOnly
    case weekdayFixed
    case custom

    var title: String {
        switch self {
        case .fourTeamTwoShift: "4조 2교대"
        case .nightOnly: "야간전담"
        case .weekdayFixed: "주간 고정"
        case .custom: "직접"
        }
    }

    /// 순서 칸. 「직접」은 지금 칸을 그대로 둔다(nil)
    var pattern: [ShiftTypeID]? {
        let d = ShiftTypeID(rawValue: "D"), n = ShiftTypeID(rawValue: "N"), off = ShiftTypeID(rawValue: "OFF")
        switch self {
        // 22a: D D N N + OFF 4개(8일)
        case .fourTeamTwoShift: return [d, d, n, n, off, off, off, off]
        // 원본에 칸이 없음 — 보류(진행 로그). 나이트 3번 · OFF 3번으로 둠
        case .nightOnly: return [n, n, n, off, off, off]
        // 월–금 D · 토일 OFF
        case .weekdayFixed: return [d, d, d, d, d, off, off]
        case .custom: return nil
        }
    }

    /// 첫날 위치 — 주간 고정은 요일로 자동(22a), 나머지는 1번째
    func startIndex(firstDay: CalendarDay) -> Int {
        guard self == .weekdayFixed else { return 0 }
        // 월요일 = 0번째 칸
        return (SeoulCalendar.weekdayIndex(firstDay) + 6) % 7
    }
}
