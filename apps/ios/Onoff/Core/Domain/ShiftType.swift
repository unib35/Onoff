// REQ-005 · REQ-006 · REQ-007 · UI-IOS-5b
import Foundation

/// 근무 유형의 종류 — 알람 · 통계 · 공유가 이 값에 따라 달라진다(REQ-006, 1.1부터).
enum ShiftKind: String, Sendable, Codable, CaseIterable {
    case work   // 근무 — 근무시간 통계에 들어감
    case off    // 휴무
    case leave  // 휴가
}

/// 하루 안의 시각(분 단위, 0..<1440).
struct TimeOfDay: Hashable, Sendable, Codable, Comparable {
    let minutes: Int

    init(hour: Int, minute: Int = 0) {
        precondition((0..<24).contains(hour) && (0..<60).contains(minute))
        minutes = hour * 60 + minute
    }

    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(Int.self)
        guard (0..<1440).contains(value) else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "0..<1440 밖의 시각: \(value)"))
        }
        minutes = value
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(minutes)
    }

    var hour: Int { minutes / 60 }
    var minute: Int { minutes % 60 }

    static func < (lhs: TimeOfDay, rhs: TimeOfDay) -> Bool { lhs.minutes < rhs.minutes }
}

/// 근무 시간 한 구간. 종료가 시작보다 이르거나 같으면 다음 날 종료로 계산한다(REQ-005 · DEC-006).
struct ShiftSegment: Hashable, Sendable, Codable {
    let start: TimeOfDay
    let end: TimeOfDay

    var endsNextDay: Bool { end <= start }

    /// 구간 길이(분)
    var durationMinutes: Int {
        endsNextDay ? (24 * 60 - start.minutes) + end.minutes : end.minutes - start.minutes
    }
}

struct ShiftTypeID: Hashable, Sendable, Codable, RawRepresentable {
    let rawValue: String
}

/// 사용자가 정하는 근무 유형. 코드(D · E · N …)로 분기하지 않고 종류 · 구간으로 판단한다(code.md).
struct ShiftType: Identifiable, Hashable, Sendable, Codable {
    let id: ShiftTypeID
    /// 표시 코드 — 최대 3자(REQ-005)
    var code: String
    var name: String
    var kind: ShiftKind
    /// 비어 있으면 종일. 스플릿은 구간 여러 개.
    var segments: [ShiftSegment]
    /// 디자인 시스템 근무 색 이름(ShiftPalette)
    var colorKey: String
    /// 숨기면 키패드에 안 보인다
    var isHidden: Bool
    /// 사용자가 추가한 근무(5b 점 표시)
    var isCustom: Bool
    /// 시각 표시 뒤에 붙는 말(예: 오전 반차 「근무」)
    var timeSuffix: String?

    var isAllDay: Bool { segments.isEmpty }

    /// 근무 시간 합(분). 종일은 0.
    var workMinutes: Int { segments.reduce(0) { $0 + $1.durationMinutes } }
}
