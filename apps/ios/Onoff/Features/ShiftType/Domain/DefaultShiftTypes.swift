// REQ-005 · UI-IOS-5b — 처음 실행할 때 넣는 기본 근무 유형(원본 5b의 11개). 사용자가 고치면 저장소 값이 원본이다.
import Foundation

enum DefaultShiftTypes {
    private static func t(_ h: Int, _ m: Int = 0) -> TimeOfDay { TimeOfDay(hour: h, minute: m) }
    private static func seg(_ s: TimeOfDay, _ e: TimeOfDay) -> ShiftSegment { ShiftSegment(start: s, end: e) }
    private static func id(_ raw: String) -> ShiftTypeID { ShiftTypeID(rawValue: raw) }

    /// 목록 순서 = 키패드 순서
    static let all: [ShiftType] = [
        ShiftType(id: id("D"), code: "D", name: "데이", kind: .work, segments: [seg(t(7), t(15, 30))], colorKey: "D", isHidden: false, isCustom: false),
        ShiftType(id: id("E"), code: "E", name: "이브닝", kind: .work, segments: [seg(t(14, 30), t(23))], colorKey: "E", isHidden: false, isCustom: false),
        ShiftType(id: id("N"), code: "N", name: "나이트", kind: .work, segments: [seg(t(22, 30), t(7, 30))], colorKey: "N", isHidden: false, isCustom: false),
        ShiftType(id: id("OFF"), code: "OFF", name: "오프", kind: .off, segments: [], colorKey: "OFF", isHidden: false, isCustom: false),
        ShiftType(id: id("M"), code: "M", name: "미드", kind: .work, segments: [seg(t(11), t(19, 30))], colorKey: "M", isHidden: false, isCustom: false),
        ShiftType(id: id("EDU"), code: "교육", name: "병동 교육", kind: .work, segments: [seg(t(9), t(18))], colorKey: "교육", isHidden: false, isCustom: false),
        ShiftType(id: id("S"), code: "S", name: "스플릿", kind: .work, segments: [seg(t(7), t(11)), seg(t(17), t(21))], colorKey: "S", isHidden: false, isCustom: false),
        ShiftType(id: id("AL"), code: "연차", name: "연차", kind: .leave, segments: [], colorKey: "연차", isHidden: false, isCustom: false),
        ShiftType(id: id("HALF"), code: "반차", name: "오전 반차", kind: .leave, segments: [seg(t(11), t(15, 30))], colorKey: "반차", isHidden: false, isCustom: false, timeSuffix: "근무"),
        ShiftType(id: id("SICK"), code: "병가", name: "병가", kind: .leave, segments: [], colorKey: "병가", isHidden: true, isCustom: false),
        ShiftType(id: id("PUB"), code: "공가", name: "공가", kind: .leave, segments: [], colorKey: "공가", isHidden: true, isCustom: false),
    ]
}
