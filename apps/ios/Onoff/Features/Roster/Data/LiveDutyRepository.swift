// REQ-008 · DEC-013 — 날짜별 근무 기기 저장(SwiftData)
import Foundation
import SwiftData

@ModelActor
actor LiveDutyRepository: DutyRepository {
    func assignments(from: CalendarDay, through: CalendarDay) async throws -> [CalendarDay: ShiftTypeID] {
        let items = try stored(from: from.storageKey, through: through.storageKey)
        return Dictionary(items.map { (CalendarDay(storageKey: $0.day), ShiftTypeID(rawValue: $0.shiftTypeID)) },
                          uniquingKeysWith: { _, last in last })
    }

    func apply(_ changes: DutyChanges) async throws {
        let keys = changes.assigned.keys.map(\.storageKey) + changes.cleared.map(\.storageKey)
        guard let lower = keys.min(), let upper = keys.max() else { return }
        let existing = try stored(from: lower, through: upper)
        let byDay = Dictionary(existing.map { ($0.day, $0) }, uniquingKeysWith: { first, _ in first })
        for day in changes.cleared {
            if let item = byDay[day.storageKey], changes.assigned[day] == nil { modelContext.delete(item) }
        }
        for (day, typeID) in changes.assigned {
            if let item = byDay[day.storageKey] {
                item.shiftTypeID = typeID.rawValue
            } else {
                modelContext.insert(StoredDuty(day: day, shiftTypeID: typeID))
            }
        }
        try modelContext.save() // 한 번에 저장 — 일부만 남지 않는다
    }

    private func stored(from lower: Int, through upper: Int) throws -> [StoredDuty] {
        try modelContext.fetch(FetchDescriptor<StoredDuty>(predicate: #Predicate { $0.day >= lower && $0.day <= upper }))
    }
}
