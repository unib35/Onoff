// 샘플 데이터 — 원본 iOS 캔버스의 가정(기록 1): 기준 시각 2026-10-04(일) 09:41, 10월 근무표(1f).
// 가짜 데이터만 쓴다. 실제 앱은 기기 저장소(빈 근무표)로 뜨고, 이 샘플은 미리보기 · 테스트 · DEBUG 화면 확인(-onoffScreen)에서만 쓴다.
import Foundation

enum SampleData {
    /// 원본 기준 시각 — 시뮬레이터에서 원본과 같은 화면을 보기 위해 고정
    static let referenceNow: Date = SeoulCalendar.date(CalendarDay(year: 2026, month: 10, day: 4), at: TimeOfDay(hour: 9, minute: 41))

    /// 5b 근무 유형 관리 — 기본 목록에서 M · S를 사용자가 추가한 것으로(원본 점 표시)
    static let shiftTypes: [ShiftType] = DefaultShiftTypes.all.map { type in
        var type = type
        type.isCustom = ["M", "S"].contains(type.id.rawValue)
        return type
    }

    /// 1f 10월 근무표(원본 octCells). 11월은 넣지 않음 → 미등록.
    static let octoberDuties: [CalendarDay: ShiftTypeID] = {
        let codes = "D D OFF E E E OFF N N N OFF OFF D N OFF OFF D D E E OFF D D D OFF N N N OFF OFF E".split(separator: " ")
        var result: [CalendarDay: ShiftTypeID] = [:]
        for (index, code) in codes.enumerated() {
            result[CalendarDay(year: 2026, month: 10, day: index + 1)] = ShiftTypeID(rawValue: String(code))
        }
        return result
    }()

    /// 1f 개인 일정 점(6 · 7 · 12 · 17일)과 3c 메모
    static let memos: [Memo] = [
        Memo(id: UUID(), date: CalendarDay(year: 2026, month: 10, day: 6), time: nil, text: "치과"),
        Memo(id: UUID(), date: CalendarDay(year: 2026, month: 10, day: 7), time: TimeOfDay(hour: 19), text: "준호 저녁"),
        Memo(id: UUID(), date: CalendarDay(year: 2026, month: 10, day: 12), time: TimeOfDay(hour: 19), text: "준호와 저녁"),
        Memo(id: UUID(), date: CalendarDay(year: 2026, month: 10, day: 12), time: nil, text: "교육 이수증 챙기기"),
        Memo(id: UUID(), date: CalendarDay(year: 2026, month: 10, day: 17), time: nil, text: "지은 생일"),
    ]
}
