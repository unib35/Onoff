// 샘플 데이터 — 원본 iOS 캔버스의 가정(기록 1): 기준 시각 2026-10-04(일) 09:41, 10월 근무표(1f).
// 가짜 데이터만 쓴다. 저장소가 생기면(다음 이슈) 첫 실행 샘플로만 남기거나 지운다.
import Foundation

enum SampleData {
    /// 원본 기준 시각 — 시뮬레이터에서 원본과 같은 화면을 보기 위해 고정
    static let referenceNow: Date = SeoulCalendar.date(CalendarDay(year: 2026, month: 10, day: 4), at: TimeOfDay(hour: 9, minute: 41))

    private static func t(_ h: Int, _ m: Int = 0) -> TimeOfDay { TimeOfDay(hour: h, minute: m) }
    private static func seg(_ s: TimeOfDay, _ e: TimeOfDay) -> ShiftSegment { ShiftSegment(start: s, end: e) }
    private static func id(_ raw: String) -> ShiftTypeID { ShiftTypeID(rawValue: raw) }

    /// 5b 근무 유형 관리 — 목록 순서 = 키패드 순서
    static let shiftTypes: [ShiftType] = [
        ShiftType(id: id("D"), code: "D", name: "데이", kind: .work, segments: [seg(t(7), t(15, 30))], colorKey: "D", isHidden: false, isCustom: false),
        ShiftType(id: id("E"), code: "E", name: "이브닝", kind: .work, segments: [seg(t(14, 30), t(23))], colorKey: "E", isHidden: false, isCustom: false),
        ShiftType(id: id("N"), code: "N", name: "나이트", kind: .work, segments: [seg(t(22, 30), t(7, 30))], colorKey: "N", isHidden: false, isCustom: false),
        ShiftType(id: id("OFF"), code: "OFF", name: "오프", kind: .off, segments: [], colorKey: "OFF", isHidden: false, isCustom: false),
        ShiftType(id: id("M"), code: "M", name: "미드", kind: .work, segments: [seg(t(11), t(19, 30))], colorKey: "M", isHidden: false, isCustom: true),
        ShiftType(id: id("EDU"), code: "교육", name: "병동 교육", kind: .work, segments: [seg(t(9), t(18))], colorKey: "교육", isHidden: false, isCustom: false),
        ShiftType(id: id("S"), code: "S", name: "스플릿", kind: .work, segments: [seg(t(7), t(11)), seg(t(17), t(21))], colorKey: "S", isHidden: false, isCustom: true),
        ShiftType(id: id("AL"), code: "연차", name: "연차", kind: .leave, segments: [], colorKey: "연차", isHidden: false, isCustom: false),
        ShiftType(id: id("HALF"), code: "반차", name: "오전 반차", kind: .leave, segments: [seg(t(11), t(15, 30))], colorKey: "반차", isHidden: false, isCustom: false, timeSuffix: "근무"),
        ShiftType(id: id("SICK"), code: "병가", name: "병가", kind: .leave, segments: [], colorKey: "병가", isHidden: true, isCustom: false),
        ShiftType(id: id("PUB"), code: "공가", name: "공가", kind: .leave, segments: [], colorKey: "공가", isHidden: true, isCustom: false),
    ]

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
