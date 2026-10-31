// REQ-005 · DEC-013 — 근무 유형 기기 저장(SwiftData)
import Foundation
import SwiftData

@ModelActor
actor LiveShiftTypeRepository: ShiftTypeRepository {
    func shiftTypes() async throws -> [ShiftType] {
        let descriptor = FetchDescriptor<StoredShiftType>(sortBy: [SortDescriptor(\.order)])
        return try modelContext.fetch(descriptor).map { try $0.toDomain() }
    }

    func replaceAll(_ types: [ShiftType]) async throws {
        let stored = try modelContext.fetch(FetchDescriptor<StoredShiftType>())
        let byID = Dictionary(stored.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let keep = Set(types.map(\.id.rawValue))
        for item in stored where !keep.contains(item.id) { modelContext.delete(item) }
        for (order, type) in types.enumerated() {
            if let existing = byID[type.id.rawValue] {
                try existing.update(from: type, order: order)
            } else {
                modelContext.insert(try StoredShiftType(type, order: order))
            }
        }
        try modelContext.save()
    }

    /// 처음 실행 — 저장된 근무 유형이 없을 때만 기본 목록을 넣는다. 화면이 뜨기 전에 끝나도록 동기로 부른다.
    static func seedIfEmpty(_ container: ModelContainer, defaults: [ShiftType]) throws {
        let context = ModelContext(container)
        guard try context.fetchCount(FetchDescriptor<StoredShiftType>()) == 0 else { return }
        for (order, type) in defaults.enumerated() { context.insert(try StoredShiftType(type, order: order)) }
        try context.save()
    }
}
