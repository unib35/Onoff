// REQ-009 · REQ-010 · REQ-011 · UI-IOS-14b · UI-IOS-5a · UI-IOS-11c — 입력 화면 상태.
// 규칙은 DutyDraft · PaintStroke(Domain)에 있고 여기서는 부르기만 한다. 방법을 바꿔도 초안 · 커서 · 되돌리기는 하나(REQ-009).
import Foundation

/// 14b 방법 바 — 1.0은 키패드 · 칠하기(글자 · 사진 보며는 이후 버전)
enum ShiftInputMethod: Hashable, CaseIterable, Sendable {
    case keypad
    case paint

    var title: String {
        switch self {
        case .keypad: "키패드"
        case .paint: "칠하기"
        }
    }
}

@MainActor @Observable
final class ShiftInputViewModel {
    enum State: Equatable {
        case loading
        case editing
        case failed
    }

    /// 달력 칸 하나
    struct Cell: Identifiable, Equatable {
        let date: CalendarDay
        let shift: ShiftType?
        let isCursor: Bool
        /// 칠한 칸 — 먹 테두리(11c 끄는 중 · 14b 이번 초안에서 칠한 칸)
        var isPainted = false
        /// 지금 손가락 아래 칸(11c 흐리게)
        var isUnderFinger = false
        var id: CalendarDay { date }
    }

    /// 칠하기 붓 — 근무 유형 하나 또는 지우개(미등록으로)
    enum Brush: Hashable {
        case shift(ShiftTypeID)
        case eraser

        var shiftID: ShiftTypeID? {
            if case let .shift(id) = self { return id }
            return nil
        }
    }

    private(set) var state: State = .loading
    private(set) var draft: DutyDraft
    private(set) var keypadTypes: [ShiftType] = []
    private(set) var isSaving = false
    /// 바꾸면 끄던 칠하기는 넣지 않고 버린다 — 미리보기는 초안이 아니다
    var method: ShiftInputMethod { didSet { stroke = nil } }
    /// 고른 붓 — 불러오면 목록 첫 근무
    var brush: Brush?
    /// 끄는 중인 칠하기 — 손을 떼면 초안에 넣고 nil
    private(set) var stroke: PaintStroke?
    /// 이번 입력에서 칠한 날과 그 근무 — 값이 그대로일 때만 테두리를 보인다
    private var paintMarks: [CalendarDay: ShiftTypeID] = [:]
    /// 저장 실패 알림
    var saveFailed = false

    private var typesByID: [ShiftTypeID: ShiftType] = [:]
    private let cursor: CalendarDay?
    private let startShiftInput: StartShiftInputUseCase
    private let applyShiftInput: ApplyShiftInputUseCase

    init(range: ClosedRange<CalendarDay>, cursor: CalendarDay?, method: ShiftInputMethod = .keypad,
         startShiftInput: StartShiftInputUseCase, applyShiftInput: ApplyShiftInputUseCase) {
        draft = DutyDraft(range: range, original: [:], protectedTypes: [])
        self.cursor = cursor
        self.method = method
        self.startShiftInput = startShiftInput
        self.applyShiftInput = applyShiftInput
    }

    func load() async {
        do {
            let session = try await startShiftInput(range: draft.range, cursor: cursor)
            typesByID = Dictionary(session.shiftTypes.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            draft = session.draft
            keypadTypes = session.keypadTypes
            if brush == nil { brush = keypadTypes.first.map { .shift($0.id) } }
            state = .editing
        } catch {
            state = .failed
        }
    }

    // MARK: - 화면에 보이는 값

    var month: Int { draft.range.lowerBound.month }
    /// 「초안 14칸」 — 시작할 때와 달라진 날 수
    var changedCount: Int { draft.changes.dayCount }
    var canUndo: Bool { draft.canUndo }
    var cursorDay: CalendarDay { draft.cursor }
    var isCursorOnLastDay: Bool { draft.cursor == draft.range.upperBound }
    /// 「13/30」의 앞 수 — 넣은 날(지운 유형을 가리키는 날은 비어 보이므로 빼고 센다)
    var filledCount: Int { draft.filledCount(known: Set(typesByID.keys)) }
    /// 키패드로 넣은 뒤 커서가 갈 날 — 마지막 날이면 nil
    var nextDay: CalendarDay? { isCursorOnLastDay ? nil : SeoulCalendar.adding(days: 1, to: draft.cursor) }
    var dayCount: Int { draft.dayCount }
    /// 1일 앞 빈칸(일요일 시작)
    var leadingBlanks: Int { SeoulCalendar.weekdayIndex(draft.range.lowerBound) }

    var cells: [Cell] {
        let changed = draft.changes
        return (0..<draft.dayCount).map { offset in
            let date = SeoulCalendar.adding(days: offset, to: draft.range.lowerBound)
            if let stroke, stroke.contains(date) {
                // 끄는 중 — 붓 색으로 미리 보인다(지우개면 빈칸)
                return Cell(date: date, shift: brush?.shiftID.flatMap { typesByID[$0] }, isCursor: date == draft.cursor,
                            isPainted: true, isUnderFinger: date == stroke.current)
            }
            let id = draft.shift(on: date)
            let painted = id != nil && paintMarks[date] == id && changed.assigned[date] == id
            // 저장된 id가 지운 유형을 가리키면 칸은 비어 보인다 — 모르는 근무를 OFF로 보이지 않게(REQ-008)
            return Cell(date: date, shift: id.flatMap { typesByID[$0] }, isCursor: date == draft.cursor, isPainted: painted)
        }
    }

    /// 「연차 × 5일 · 11/12–16」 — 끄는 동안 위에 뜨는 수
    var strokeSummary: String? {
        guard let stroke, let brush else { return nil }
        let name = brush.shiftID.flatMap { typesByID[$0]?.name } ?? "지우개"
        let first = stroke.first
        let span = stroke.first == stroke.last ? "\(first.month)/\(first.day)" : "\(first.month)/\(first.day)–\(stroke.last.day)"
        return "\(name) × \(stroke.days.count)일 · \(span)"
    }

    // MARK: - 키패드

    func enter(_ type: ShiftType) {
        paintMarks[draft.cursor] = nil // 키패드로 넣은 칸은 칠한 칸이 아니다
        draft.enter(type.id)
    }
    func backspace() { draft.backspace() }
    func previousDay() { draft.previousDay() }
    func skipDay() { draft.skipDay() }
    func select(_ day: CalendarDay) { draft.moveCursor(to: day) }
    func undo() {
        draft.undo()
        // 되돌려서 값이 달라진 칸은 더 이상 칠한 칸이 아니다
        paintMarks = paintMarks.filter { draft.shift(on: $0.key) == $0.value }
    }

    // MARK: - 칠하기 (11c)

    /// 길게 누른 칸 — 고른 붓이 없으면 시작하지 않는다
    func beginStroke(at day: CalendarDay) {
        guard brush != nil, draft.range.contains(day) else { return }
        stroke = PaintStroke(anchor: day)
    }

    /// 손가락이 간 칸 — 달력 밖이면(nil) 마지막 칸을 그대로 둔다
    func moveStroke(to day: CalendarDay?) {
        guard let day, draft.range.contains(day) else { return }
        stroke?.move(to: day)
    }

    /// 손을 뗌 — 지나간 날을 한 번에 넣는다(되돌리기 한 번에 함께 돌아감)
    func endStroke() {
        let stroke = self.stroke
        self.stroke = nil
        guard let stroke, let brush else { return }
        // 실제로 바뀌는 날만 칠한 칸으로 — 이미 같은 값이던 날은 그대로
        let changing = stroke.days.filter { draft.range.contains($0) && draft.shift(on: $0) != brush.shiftID }
        draft.paint(brush.shiftID, days: stroke.days)
        for day in changing {
            if let id = brush.shiftID { paintMarks[day] = id } else { paintMarks[day] = nil }
        }
    }

    /// 한 날만 칠하기 — VoiceOver 동작 · 길게 누르고 움직이지 않고 뗀 경우
    func paintDay(_ day: CalendarDay) {
        beginStroke(at: day)
        endStroke()
    }

    var isStroking: Bool { stroke != nil }

    /// 제스처가 끊김(전화 등) — 넣지 않는다
    func cancelStroke() { stroke = nil }

    // MARK: - 적용

    enum ApplyOutcome: Equatable {
        /// 닫는다 — 저장한 날이 있으면 saved
        case close(saved: Bool)
        /// 저장 중이거나 실패 — 화면에 남는다
        case stay
    }

    /// 저장하는 동안에는 입력을 막는다(View가 isSaving으로) — 저장 중 고친 값이 사라지지 않게
    func apply() async -> ApplyOutcome {
        guard !isSaving else { return .stay }
        stroke = nil
        isSaving = true
        defer { isSaving = false }
        do {
            let result = try await applyShiftInput(draft)
            draft = result.draft
            paintMarks = [:]
            return .close(saved: result.savedDays > 0)
        } catch {
            saveFailed = true
            return .stay
        }
    }
}
