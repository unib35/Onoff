// REQ-009 · UI-IOS-14a — 시작 시트: 그 달에 아직 넣지 않은 날 수
import Foundation

@MainActor @Observable
final class ShiftInputStartViewModel {
    let year: Int
    let month: Int
    /// 「미등록 30일」 — 불러오기 전 · 실패하면 nil(숫자를 지어내지 않는다)
    private(set) var unregisteredDays: Int?
    private let startShiftInput: StartShiftInputUseCase

    init(year: Int, month: Int, startShiftInput: StartShiftInputUseCase) {
        self.year = year
        self.month = month
        self.startShiftInput = startShiftInput
    }

    func load() async {
        let draft = try? await startShiftInput(range: StartShiftInputUseCase.month(year: year, month: month)).draft
        unregisteredDays = draft.map { $0.dayCount - $0.filledCount }
    }
}
