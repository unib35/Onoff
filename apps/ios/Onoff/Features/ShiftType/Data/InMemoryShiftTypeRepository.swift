// REQ-005 — 메모리 구현(미리보기 · 테스트). 기기 저장은 LiveShiftTypeRepository.
import Foundation

actor InMemoryShiftTypeRepository: ShiftTypeRepository {
    private var types: [ShiftType]

    init(_ types: [ShiftType]) { self.types = types }

    func shiftTypes() async throws -> [ShiftType] { types }

    func replaceAll(_ types: [ShiftType]) async throws { self.types = types }
}
