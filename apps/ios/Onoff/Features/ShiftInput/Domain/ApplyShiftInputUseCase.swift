// REQ-009 — 초안 적용: 바뀐 날만 한 번에 저장하고, 저장한 값을 기준으로 한 새 초안을 돌려준다.
// 같은 초안을 계속 고쳐 다시 적용해도 이미 저장한 날을 또 쓰지 않는다. 변경 이력(1l)은 그 이슈에서 여기에 붙인다.
import Foundation

struct ApplyShiftInputUseCase: Sendable {
    struct Result: Hashable, Sendable {
        /// 저장한 날 수(바뀐 날이 없으면 0, 저장소를 부르지 않음)
        let savedDays: Int
        /// 이어서 고칠 초안 — 바뀐 날 없음
        let draft: DutyDraft
    }

    let duties: any DutyRepository

    func callAsFunction(_ draft: DutyDraft) async throws -> Result {
        let changes = draft.changes
        guard !changes.isEmpty else { return Result(savedDays: 0, draft: draft) }
        try await duties.apply(changes)
        return Result(savedDays: changes.dayCount, draft: draft.applied())
    }
}
