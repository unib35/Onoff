// REQ-009 · REQ-010 · UI-IOS-14b · UI-IOS-5a — 입력 화면 상태. 규칙은 DutyDraft(Domain)에 있고 여기서는 부르기만 한다.
import Foundation

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
        var id: CalendarDay { date }
    }

    private(set) var state: State = .loading
    private(set) var draft: DutyDraft
    private(set) var keypadTypes: [ShiftType] = []
    private(set) var isSaving = false
    /// 저장 실패 알림
    var saveFailed = false

    private var typesByID: [ShiftTypeID: ShiftType] = [:]
    private let cursor: CalendarDay?
    private let startShiftInput: StartShiftInputUseCase
    private let applyShiftInput: ApplyShiftInputUseCase

    init(range: ClosedRange<CalendarDay>, cursor: CalendarDay?,
         startShiftInput: StartShiftInputUseCase, applyShiftInput: ApplyShiftInputUseCase) {
        draft = DutyDraft(range: range, original: [:], protectedTypes: [])
        self.cursor = cursor
        self.startShiftInput = startShiftInput
        self.applyShiftInput = applyShiftInput
    }

    func load() async {
        do {
            let session = try await startShiftInput(range: draft.range, cursor: cursor)
            typesByID = Dictionary(session.shiftTypes.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            draft = session.draft
            keypadTypes = session.keypadTypes
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
        (0..<draft.dayCount).map { offset in
            let date = SeoulCalendar.adding(days: offset, to: draft.range.lowerBound)
            // 저장된 id가 지운 유형을 가리키면 칸은 비어 보인다 — 모르는 근무를 OFF로 보이지 않게(REQ-008)
            return Cell(date: date, shift: draft.shift(on: date).flatMap { typesByID[$0] }, isCursor: date == draft.cursor)
        }
    }

    // MARK: - 키패드

    func enter(_ type: ShiftType) { draft.enter(type.id) }
    func backspace() { draft.backspace() }
    func previousDay() { draft.previousDay() }
    func skipDay() { draft.skipDay() }
    func select(_ day: CalendarDay) { draft.moveCursor(to: day) }
    func undo() { draft.undo() }

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
        isSaving = true
        defer { isSaving = false }
        do {
            let result = try await applyShiftInput(draft)
            draft = result.draft
            return .close(saved: result.savedDays > 0)
        } catch {
            saveFailed = true
            return .stay
        }
    }
}
