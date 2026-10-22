// REQ-019 — 메모리 구현(샘플 · 테스트). 로컬 저장소 구현은 다음 이슈.
import Foundation

final class InMemoryMemoRepository: MemoRepository {
    private let items: [Memo]

    init(_ items: [Memo]) { self.items = items }

    func memos(from: CalendarDay, through: CalendarDay) async throws -> [Memo] {
        items.filter { $0.date >= from && $0.date <= through }
    }
}
