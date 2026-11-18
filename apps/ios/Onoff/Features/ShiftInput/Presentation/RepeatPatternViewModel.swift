// REQ-013 · UI-IOS-22a · UI-IOS-22b — 순서 반복 화면 상태. 규칙은 RepeatPlan · DutyDraft(Domain)에 있다.
// 시작 달부터 최대 12달을 한 번 불러오고, 몇 달 · 순서를 바꿀 때마다 미리보기를 다시 계산한다.
import Foundation

@MainActor @Observable
final class RepeatPatternViewModel {
    enum State: Equatable {
        case loading
        case editing
        case failed
    }

    /// 순서 칸 하나(22a)
    struct PatternCell: Identifiable, Equatable {
        let index: Int
        let shift: ShiftType?
        var id: Int { index }
    }

    /// 미리보기 한 줄 — 그 달 날마다 근무(nil = 미등록)
    struct PreviewMonth: Identifiable, Equatable {
        let year: Int
        let month: Int
        let days: [ShiftType?]
        var id: Int { year * 100 + month }
    }

    static let monthRange = 1...12

    private(set) var state: State = .loading
    private(set) var preset: RepeatPreset = .fourTeamTwoShift
    private(set) var plan = RepeatPlan(pattern: RepeatPreset.fourTeamTwoShift.pattern ?? [], startIndex: 0)
    private(set) var months = 3
    /// 22b — 고치는 칸(끝 다음 = 「+」 자리). nil이면 고치지 않는 중
    private(set) var editingIndex: Int?
    /// 22b 「순서를 고쳐서 11월 1일 근무가 바뀌었어요」
    private(set) var firstDayChanged = false
    private(set) var isSaving = false
    var saveFailed = false

    private(set) var shiftTypes: [ShiftType] = []
    private var typesByID: [ShiftTypeID: ShiftType] = [:]
    private var base: DutyDraft
    private var firstDayBeforeEdit: ShiftTypeID?
    private let startShiftInput: StartShiftInputUseCase
    private let applyShiftInput: ApplyShiftInputUseCase

    init(year: Int, month: Int, startShiftInput: StartShiftInputUseCase, applyShiftInput: ApplyShiftInputUseCase) {
        let first = CalendarDay(year: year, month: month, day: 1)
        base = DutyDraft(range: first...Self.monthEnd(from: first, months: Self.monthRange.upperBound),
                         original: [:], protectedTypes: [])
        self.startShiftInput = startShiftInput
        self.applyShiftInput = applyShiftInput
    }

    func load() async {
        do {
            let session = try await startShiftInput(range: base.range)
            base = session.draft
            shiftTypes = session.shiftTypes
            typesByID = Dictionary(session.shiftTypes.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            // 기본 프리셋을 쓸 수 없으면(D · N · OFF가 없음) 「직접」으로 첫 근무 두 칸
            if !isAvailable(preset) {
                preset = .custom
                plan.pattern = Array(keypadTypes.prefix(RepeatPlan.minimumLength).map(\.id))
            }
            state = .editing
        } catch {
            state = .failed
        }
    }

    // MARK: - 화면에 보이는 값

    var firstDay: CalendarDay { base.range.lowerBound }
    var keypadTypes: [ShiftType] { shiftTypes.filter { !$0.isHidden } }
    var patternCells: [PatternCell] { plan.pattern.enumerated().map { PatternCell(index: $0.offset, shift: typesByID[$0.element]) } }
    var startIndex: Int { plan.startIndex }
    var afterLeave: DutyDraft.AfterLeave { plan.afterLeave }
    var keepExisting: Bool { plan.keepExisting }
    var firstDayShift: ShiftType? { plan.firstDayShift.flatMap { typesByID[$0] } }
    var lastDay: CalendarDay { Self.monthEnd(from: firstDay, months: months) }
    var lastMonth: Int { lastDay.month }

    func isAvailable(_ preset: RepeatPreset) -> Bool {
        guard let pattern = preset.pattern else { return true }
        return pattern.allSatisfy { typesByID[$0] != nil }
    }

    private var filled: DutyDraft { plan.filled(base, through: lastDay) }

    /// 채울 날 수 — 휴가 · 그대로 둘 근무는 빼고 실제로 바뀌는 날
    var fillCount: Int { filled.changes.dayCount }

    var previewMonths: [PreviewMonth] {
        let draft = filled
        return (0..<months).map { offset in
            let start = Self.monthStart(from: firstDay, adding: offset)
            let count = SeoulCalendar.daysInMonth(year: start.year, month: start.month)
            let days = (0..<count).map { draft.shift(on: SeoulCalendar.adding(days: $0, to: start)).flatMap { typesByID[$0] } }
            return PreviewMonth(year: start.year, month: start.month, days: days)
        }
    }

    /// 「11/13–14 연차는 그대로 둬요」 — 채울 기간 안 휴가 구간. 없으면 nil
    var keptLeaveNote: String? {
        var spans: [(first: CalendarDay, last: CalendarDay, type: ShiftType)] = []
        var day = firstDay
        while day <= lastDay {
            if let id = base.shift(on: day), base.protectedTypes.contains(id), let type = typesByID[id] {
                if let last = spans.last, last.type.id == id, SeoulCalendar.adding(days: 1, to: last.last) == day {
                    spans[spans.count - 1].last = day
                } else {
                    spans.append((day, day, type))
                }
            }
            day = SeoulCalendar.adding(days: 1, to: day)
        }
        guard !spans.isEmpty else { return nil }
        let text = spans.map { span in
            let range = span.first == span.last ? "\(span.first.month)/\(span.first.day)"
                : span.first.month == span.last.month ? "\(span.first.month)/\(span.first.day)–\(span.last.day)"
                : "\(span.first.month)/\(span.first.day)–\(span.last.month)/\(span.last.day)"
            return "\(range) \(span.type.name)"
        }.joined(separator: " · ")
        return "\(text)\(Self.topicParticle(after: spans.last!.type.name)) 그대로 둬요"
    }

    // MARK: - 22a 설정

    func choose(_ preset: RepeatPreset) {
        guard isAvailable(preset) else { return }
        self.preset = preset
        if let pattern = preset.pattern {
            plan.pattern = pattern
            plan.startIndex = preset.startIndex(firstDay: firstDay)
        }
        editingIndex = nil
        firstDayChanged = false
    }

    func chooseStart(_ index: Int) { plan.startIndex = max(0, min(index, plan.pattern.count - 1)) }
    func setAfterLeave(_ value: DutyDraft.AfterLeave) { plan.afterLeave = value }
    func setKeepExisting(_ value: Bool) { plan.keepExisting = value }
    func addMonth() { months = min(months + 1, Self.monthRange.upperBound) }
    func removeMonth() { months = max(months - 1, Self.monthRange.lowerBound) }

    // MARK: - 22b 칸 고치기

    var isEditing: Bool { editingIndex != nil }

    /// 칸(또는 「+」)을 눌러 고치기 시작
    func edit(_ index: Int) {
        if editingIndex == nil { firstDayBeforeEdit = plan.firstDayShift }
        editingIndex = min(index, plan.pattern.count)
    }

    /// 근무를 누름 — 바꾸고 다음 칸으로(끝이면 「+」 자리)
    func put(_ type: ShiftType) {
        guard let index = editingIndex else { return }
        plan.set(type.id, at: index)
        editingIndex = index + 1
        didEditPattern()
    }

    /// 「지우기 · 이 칸 빼기」 — 「+」 자리에서는 아무것도 하지 않는다
    func removeEditing() {
        guard let index = editingIndex, index < plan.pattern.count, plan.pattern.count > RepeatPlan.minimumLength else { return }
        plan.remove(at: index)
        editingIndex = min(index, plan.pattern.count)
        didEditPattern()
    }

    var canRemove: Bool {
        guard let index = editingIndex else { return false }
        return index < plan.pattern.count && plan.pattern.count > RepeatPlan.minimumLength
    }

    /// 지금 칸의 근무(키에 고리)
    var editingShift: ShiftTypeID? {
        guard let index = editingIndex, index < plan.pattern.count else { return nil }
        return plan.pattern[index]
    }

    func finishEditing() { editingIndex = nil }

    private func didEditPattern() {
        preset = .custom
        firstDayChanged = plan.firstDayShift != firstDayBeforeEdit
    }

    // MARK: - 채우기

    /// 바로 저장 — 되돌릴 변경과 저장한 날 수를 돌려준다. 실패하면 nil(알림)
    func fill() async -> ApplyShiftInputUseCase.Result? {
        guard !isSaving, state == .editing else { return nil }
        isSaving = true
        defer { isSaving = false }
        do {
            return try await applyShiftInput(filled)
        } catch {
            saveFailed = true
            return nil
        }
    }

    // MARK: -

    static func monthStart(from first: CalendarDay, adding months: Int) -> CalendarDay {
        let index = first.year * 12 + (first.month - 1) + months
        return CalendarDay(year: index / 12, month: index % 12 + 1, day: 1)
    }

    static func monthEnd(from first: CalendarDay, months: Int) -> CalendarDay {
        let start = monthStart(from: first, adding: months - 1)
        return CalendarDay(year: start.year, month: start.month, day: SeoulCalendar.daysInMonth(year: start.year, month: start.month))
    }

    /// 받침이 있으면 「은」, 없으면 「는」(한글이 아니면 「는」)
    static func topicParticle(after word: String) -> String {
        guard let scalar = word.unicodeScalars.last, (0xAC00...0xD7A3).contains(scalar.value) else { return "는" }
        return (scalar.value - 0xAC00) % 28 == 0 ? "는" : "은"
    }
}
