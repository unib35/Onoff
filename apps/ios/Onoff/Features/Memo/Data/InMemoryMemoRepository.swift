// REQ-019 — 메모리 구현(미리보기 · 테스트). 기기 저장은 LiveMemoRepository.
import Foundation

actor InMemoryMemoRepository: MemoRepository {
    private var items: [Memo]

    init(_ items: [Memo]) { self.items = items }

    func memos(from: CalendarDay, through: CalendarDay) async throws -> [Memo] {
        items.filter { $0.date >= from && $0.date <= through }
    }

    func save(_ memo: Memo) async throws {
        if let index = items.firstIndex(where: { $0.id == memo.id }) {
            items[index] = memo
        } else {
            items.append(memo)
        }
    }

    func delete(id: Memo.ID) async throws {
        items.removeAll { $0.id == id }
    }
}
