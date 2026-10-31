// REQ-005 · REQ-008 · REQ-019 — 저장소 인터페이스. 구현은 각 기능의 Data(지금은 InMemory, 로컬 저장소는 다음 이슈)
import Foundation

protocol ShiftTypeRepository: Sendable {
    /// 목록 순서 = 키패드 순서(5b)
    func shiftTypes() async throws -> [ShiftType]
}

protocol DutyRepository: Sendable {
    /// 넣지 않은 날은 결과에 없다 — 호출하는 쪽이 미등록으로 본다
    func assignments(from: CalendarDay, through: CalendarDay) async throws -> [CalendarDay: ShiftTypeID]
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
}
