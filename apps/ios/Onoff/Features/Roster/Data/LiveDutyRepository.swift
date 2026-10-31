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

    func assign(_ assignments: [CalendarDay: ShiftTypeID]) async throws {
        guard !assignments.isEmpty else { return }
        let keys = assignments.keys.map(\.storageKey)
        let existing = try stored(from: keys.min()!, through: keys.max()!)
        let byDay = Dictionary(existing.map { ($0.day, $0) }, uniquingKeysWith: { first, _ in first })
        for (day, typeID) in assignments {
            if let item = byDay[day.storageKey] {
                item.shiftTypeID = typeID.rawValue
            } else {
                modelContext.insert(StoredDuty(day: day, shiftTypeID: typeID))
            }
        }
        try modelContext.save()
    }

    func clear(_ days: [CalendarDay]) async throws {
        let keys = Set(days.map(\.storageKey))
        guard let lower = keys.min(), let upper = keys.max() else { return }
        for item in try stored(from: lower, through: upper) where keys.contains(item.day) {
            modelContext.delete(item)
        }
        try modelContext.save()
    }

    private func stored(from lower: Int, through upper: Int) throws -> [StoredDuty] {
        try modelContext.fetch(FetchDescriptor<StoredDuty>(predicate: #Predicate { $0.day >= lower && $0.day <= upper }))
    }
}
