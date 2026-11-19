// 근무 입력 기능의 목적지 → 화면. 1f 「입력」 → 14a 시작 시트 → 입력 화면(14b · 5a)
import SwiftUI

enum ShiftInputRoute: Hashable {
    /// 14a 시작 시트
    case start(year: Int, month: Int)
    /// 입력 화면 — `day`는 누른 날(없으면 첫 미등록 날 · DEC-014)
    case editor(year: Int, month: Int, day: CalendarDay?)

    @MainActor @ViewBuilder
    func view(container: AppContainer, router: AppRouter) -> some View {
        switch self {
        case let .start(year, month):
            ShiftInputStartSheet(
                viewModel: ShiftInputStartViewModel(year: year, month: month, startShiftInput: container.startShiftInput),
                onKeypad: { router.present(AppCover.shiftInput(.editor(year: year, month: month, day: nil))) }
            )
        case let .editor(year, month, day):
            ShiftInputView(
                viewModel: ShiftInputViewModel(
                    range: StartShiftInputUseCase.month(year: year, month: month), cursor: day,
                    startShiftInput: container.startShiftInput, applyShiftInput: container.applyShiftInput
                ),
                onClose: { saved in
                    if saved { router.dataDidChange() }
                    router.dismissCover()
                }
            )
        }
    }
}
