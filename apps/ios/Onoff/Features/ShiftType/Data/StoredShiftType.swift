// REQ-005 · DEC-013 — 근무 유형 저장 모델. Domain(ShiftType)으로 바꿔서만 밖에 넘긴다.
import Foundation
import SwiftData

@Model
final class StoredShiftType {
    @Attribute(.unique) var id: String
    /// 목록 · 키패드 순서
    var order: Int
    var code: String
    var name: String
    var kind: String
    /// [ShiftSegment] JSON
    var segments: Data
    var colorKey: String
    var isHidden: Bool
    var isCustom: Bool
    var timeSuffix: String?

    init(_ type: ShiftType, order: Int) throws {
        id = type.id.rawValue
        self.order = order
        code = type.code
        name = type.name
        kind = type.kind.rawValue
        segments = try JSONEncoder().encode(type.segments)
        colorKey = type.colorKey
        isHidden = type.isHidden
        isCustom = type.isCustom
        timeSuffix = type.timeSuffix
    }

    func update(from type: ShiftType, order: Int) throws {
        self.order = order
        code = type.code
        name = type.name
        kind = type.kind.rawValue
        segments = try JSONEncoder().encode(type.segments)
        colorKey = type.colorKey
        isHidden = type.isHidden
        isCustom = type.isCustom
        timeSuffix = type.timeSuffix
    }

    func toDomain() throws -> ShiftType {
        guard let kind = ShiftKind(rawValue: kind),
              let segments = try? JSONDecoder().decode([ShiftSegment].self, from: segments)
        else { throw LocalStoreError.corrupted }
        return ShiftType(id: ShiftTypeID(rawValue: id), code: code, name: name, kind: kind, segments: segments,
                         colorKey: colorKey, isHidden: isHidden, isCustom: isCustom, timeSuffix: timeSuffix)
    }
}
