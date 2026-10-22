// REQ-005 — 메모리 구현(샘플 · 테스트). 로컬 저장소 구현은 다음 이슈.
import Foundation

final class InMemoryShiftTypeRepository: ShiftTypeRepository {
    private let types: [ShiftType]

    init(_ types: [ShiftType]) { self.types = types }

    func shiftTypes() async throws -> [ShiftType] { types }
}
