// REQ-008 · DEC-013 — 날짜별 근무 저장 모델. 넣은 날만 저장한다(없는 날 = 미등록).
import Foundation
import SwiftData

@Model
final class StoredDuty {
    /// CalendarDay.storageKey(yyyymmdd)
    @Attribute(.unique) var day: Int
    var shiftTypeID: String

    init(day: CalendarDay, shiftTypeID: ShiftTypeID) {
        self.day = day.storageKey
        self.shiftTypeID = shiftTypeID.rawValue
    }
}
