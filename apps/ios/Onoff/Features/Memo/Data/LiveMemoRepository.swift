// REQ-019 · DEC-013 — 메모 기기 저장(SwiftData)
import Foundation
import SwiftData

@ModelActor
actor LiveMemoRepository: MemoRepository {
    func memos(from: CalendarDay, through: CalendarDay) async throws -> [Memo] {
        let lower = from.storageKey, upper = through.storageKey
        let descriptor = FetchDescriptor<StoredMemo>(predicate: #Predicate { $0.day >= lower && $0.day <= upper },
                                                     sortBy: [SortDescriptor(\.day)])
        return try modelContext.fetch(descriptor).map { try $0.toDomain() }
    }

    func save(_ memo: Memo) async throws {
        if let existing = try find(memo.id) {
            existing.update(from: memo)
        } else {
            modelContext.insert(StoredMemo(memo))
        }
        try modelContext.save()
    }

    func delete(id: Memo.ID) async throws {
        guard let existing = try find(id) else { return }
        modelContext.delete(existing)
        try modelContext.save()
    }

    private func find(_ id: UUID) throws -> StoredMemo? {
        var descriptor = FetchDescriptor<StoredMemo>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
}
