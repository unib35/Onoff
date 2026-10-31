// REQ-019 · DEC-013 — 메모 저장 모델
import Foundation
import SwiftData

@Model
final class StoredMemo {
    @Attribute(.unique) var id: UUID
    /// CalendarDay.storageKey(yyyymmdd)
    var day: Int
    /// 하루 안의 분(0..<1440). 없으면 시각 없는 메모
    var minutes: Int?
    var text: String
    var isPrivate: Bool

    init(_ memo: Memo) {
        id = memo.id
        day = memo.date.storageKey
        minutes = memo.time?.minutes
        text = memo.text
        isPrivate = memo.isPrivate
    }

    func update(from memo: Memo) {
        day = memo.date.storageKey
        minutes = memo.time?.minutes
        text = memo.text
        isPrivate = memo.isPrivate
    }

    func toDomain() throws -> Memo {
        var time: TimeOfDay?
        if let minutes {
            guard (0..<1440).contains(minutes) else { throw LocalStoreError.corrupted }
            time = TimeOfDay(hour: minutes / 60, minute: minutes % 60)
        }
        return Memo(id: id, date: CalendarDay(storageKey: day), time: time, text: text, isPrivate: isPrivate)
    }
}
