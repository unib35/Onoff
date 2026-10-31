// REQ-005 · UI-IOS-5b — 근무 유형 목록: 키패드에 보이는 것 · 숨긴 것
import Foundation

struct ShiftTypeList: Sendable, Equatable {
    /// 목록 순서 = 키패드 순서
    let visible: [ShiftType]
    let hidden: [ShiftType]
}

struct GetShiftTypesUseCase: Sendable {
    let repository: any ShiftTypeRepository

    func callAsFunction() async throws -> ShiftTypeList {
        let all = try await repository.shiftTypes()
        return ShiftTypeList(visible: all.filter { !$0.isHidden }, hidden: all.filter(\.isHidden))
    }
}
