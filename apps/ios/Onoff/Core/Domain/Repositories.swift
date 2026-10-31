// REQ-005 · REQ-008 · REQ-019 · DEC-013 — 저장소 인터페이스. 구현은 각 기능의 Data(Live = SwiftData, InMemory = 미리보기 · 테스트)
import Foundation

protocol ShiftTypeRepository: Sendable {
    /// 목록 순서 = 키패드 순서(5b)
    func shiftTypes() async throws -> [ShiftType]
    /// 목록 전체를 이 순서로 저장한다 — 빠진 유형은 지운다
    func replaceAll(_ types: [ShiftType]) async throws
}

protocol DutyRepository: Sendable {
    /// 넣지 않은 날은 결과에 없다 — 호출하는 쪽이 미등록으로 본다
    func assignments(from: CalendarDay, through: CalendarDay) async throws -> [CalendarDay: ShiftTypeID]
    /// 넣기 · 바꾸기 · 지우기를 한 번에 저장한다 — 일부만 저장되지 않게(REQ-009 한 번에 적용)
    func apply(_ changes: DutyChanges) async throws
}

extension DutyRepository {
    /// 날짜별 근무를 넣거나 바꾼다
    func assign(_ assignments: [CalendarDay: ShiftTypeID]) async throws {
        try await apply(DutyChanges(assigned: assignments))
    }

    /// 그 날을 미등록으로 되돌린다 — OFF로 채우지 않는다(REQ-008)
    func clear(_ days: [CalendarDay]) async throws {
        try await apply(DutyChanges(cleared: Set(days)))
    }
}

/// 저장할 근무 변경. 지운 날(`cleared`)은 미등록이 된다 — OFF가 아니다(REQ-008).
struct DutyChanges: Hashable, Sendable {
    var assigned: [CalendarDay: ShiftTypeID] = [:]
    var cleared: Set<CalendarDay> = []

    var isEmpty: Bool { assigned.isEmpty && cleared.isEmpty }
    var dayCount: Int { assigned.count + cleared.count }
}

struct Memo: Identifiable, Hashable, Sendable {
    let id: UUID
    let date: CalendarDay
    var time: TimeOfDay?
    var text: String
    /// 기본은 나만 보기
    var isPrivate: Bool = true
}

protocol MemoRepository: Sendable {
    func memos(from: CalendarDay, through: CalendarDay) async throws -> [Memo]
    /// 같은 id가 있으면 바꾸고, 없으면 넣는다
    func save(_ memo: Memo) async throws
    func delete(id: Memo.ID) async throws
}
