// REQ-009 · REQ-010 · REQ-011 · REQ-013 · REQ-008 — 입력 초안. 모든 입력 방법(키패드 · 칠하기 · 순서 반복)이
// 이 초안 하나에 쌓이고 「적용」할 때 한 번에 저장된다. 방법을 바꿔도 칸 · 커서 · 되돌리기는 그대로다.
import Foundation

struct DutyDraft: Hashable, Sendable {
    /// 입력하는 기간 — 이 밖의 날은 건드리지 않는다
    let range: ClosedRange<CalendarDay>
    /// 순서 반복이 덮어쓰지 않는 근무(휴가 종류 — REQ-013)
    let protectedTypes: Set<ShiftTypeID>
    /// 시작할 때 저장돼 있던 근무 — 바뀐 날을 가려내는 기준
    private let original: [CalendarDay: ShiftTypeID]
    private var current: [CalendarDay: ShiftTypeID]
    /// 키패드가 넣을 날
    private(set) var cursor: CalendarDay
    private var history: [Step] = []

    /// 되돌리기 한 번 = 동작 하나. 그 동작 전의 값과 커서를 기억한다.
    private struct Step: Hashable, Sendable {
        struct Entry: Hashable, Sendable {
            let day: CalendarDay
            let shift: ShiftTypeID?
        }
        let previous: [Entry]
        let cursor: CalendarDay
    }

    init(range: ClosedRange<CalendarDay>, original: [CalendarDay: ShiftTypeID],
         protectedTypes: Set<ShiftTypeID>, cursor: CalendarDay? = nil) {
        self.range = range
        self.protectedTypes = protectedTypes
        let inRange = original.filter { range.contains($0.key) }
        self.original = inRange
        current = inRange
        self.cursor = cursor.map { Self.clamp($0, to: range) } ?? range.lowerBound
    }

    /// 넣지 않은 날은 nil — 미등록(REQ-008)
    func shift(on day: CalendarDay) -> ShiftTypeID? { current[day] }

    var canUndo: Bool { !history.isEmpty }

    /// 시작할 때와 달라진 날만. 원래 값으로 되돌려 넣은 날은 빠진다.
    var changes: DutyChanges {
        var result = DutyChanges()
        for (day, shift) in current where original[day] != shift { result.assigned[day] = shift }
        for day in original.keys where current[day] == nil { result.cleared.insert(day) }
        return result
    }

    // MARK: - 커서

    /// 칸을 눌러 커서를 옮긴다. 되돌리기 대상이 아니다.
    mutating func moveCursor(to day: CalendarDay) {
        cursor = Self.clamp(day, to: range)
    }

    // MARK: - 키패드 (REQ-010)

    /// 커서 날에 넣고 다음 날로 간다. 기간 마지막 날에서는 커서가 그대로 있다.
    mutating func enter(_ shift: ShiftTypeID) {
        record([cursor])
        current[cursor] = shift
        if cursor < range.upperBound { cursor = SeoulCalendar.adding(days: 1, to: cursor) }
    }

    /// 커서 날을 미등록으로 — OFF로 채우지 않는다(REQ-008). 커서는 그대로.
    mutating func erase() {
        guard current[cursor] != nil else { return }
        record([cursor])
        current[cursor] = nil
    }

    // MARK: - 칠하기 (REQ-011)

    /// 여러 날을 한 번에 — 손을 뗄 때 한 번 부른다. nil이면 지우기(미등록). 되돌리기 한 번에 함께 돌아간다.
    mutating func paint(_ shift: ShiftTypeID?, days: [CalendarDay]) {
        let targets = Set(days.filter { range.contains($0) && current[$0] != shift })
        guard !targets.isEmpty else { return }
        record(Array(targets))
        for day in targets { current[day] = shift }
    }

    // MARK: - 순서 반복 (REQ-013)

    /// `pattern`을 `from`부터 날마다 차례로 반복한다. 휴가가 이미 들어 있는 날은 건너뛰되 순서는 날짜 기준으로 계속 간다
    /// (휴가가 끼어도 뒤 순서가 밀리지 않는다). 기간 밖은 건드리지 않는다.
    mutating func repeatPattern(_ pattern: [ShiftTypeID], from start: CalendarDay, through end: CalendarDay) {
        // 기간과 겹치는 날만 돈다. 순서 번호는 `from`부터 센다(기간 앞에서 시작해도 날짜 기준으로 맞물림).
        let lower = max(start, range.lowerBound), upper = min(end, range.upperBound)
        guard !pattern.isEmpty, lower <= upper else { return }
        var updates: [CalendarDay: ShiftTypeID] = [:]
        var day = lower
        var index = SeoulCalendar.daysBetween(start, lower)
        while day <= upper {
            if !isProtected(day), current[day] != pattern[index % pattern.count] {
                updates[day] = pattern[index % pattern.count]
            }
            day = SeoulCalendar.adding(days: 1, to: day)
            index += 1
        }
        guard !updates.isEmpty else { return }
        record(Array(updates.keys))
        current.merge(updates) { _, new in new }
    }

    // MARK: - 적용

    /// 저장에 성공한 뒤의 초안 — 지금 값이 새 기준이 되고 되돌리기는 비운다. 커서는 그대로.
    /// 적용한 것을 되돌리기(1l 변경 이력)는 그 이슈에서 이 위에 붙인다.
    func applied() -> DutyDraft {
        var next = DutyDraft(range: range, original: current, protectedTypes: protectedTypes, cursor: cursor)
        next.history = []
        return next
    }

    // MARK: - 되돌리기

    mutating func undo() {
        guard let step = history.popLast() else { return }
        for entry in step.previous { current[entry.day] = entry.shift }
        cursor = step.cursor
    }

    // MARK: -

    private func isProtected(_ day: CalendarDay) -> Bool {
        current[day].map(protectedTypes.contains) ?? false
    }

    private mutating func record(_ days: [CalendarDay]) {
        history.append(Step(previous: days.map { Step.Entry(day: $0, shift: current[$0]) }, cursor: cursor))
    }

    private static func clamp(_ day: CalendarDay, to range: ClosedRange<CalendarDay>) -> CalendarDay {
        min(max(day, range.lowerBound), range.upperBound)
    }
}
