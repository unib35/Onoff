// REQ-009 — 초안 적용: 바뀐 날만 한 번에 저장한다. 변경 이력(1l)은 그 이슈에서 여기에 붙인다.
import Foundation

struct ApplyShiftInputUseCase: Sendable {
    let duties: any DutyRepository

    /// - Returns: 저장한 날 수(바뀐 날이 없으면 0, 저장소를 부르지 않음)
    @discardableResult
    func callAsFunction(_ draft: DutyDraft) async throws -> Int {
        let changes = draft.changes
        guard !changes.isEmpty else { return 0 }
        try await duties.apply(changes)
        return changes.dayCount
    }
}
