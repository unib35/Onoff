// 근무 입력 기능의 목적지 → 화면. 1f 「입력」 → 14a 시작 시트 → 입력 화면(14b · 5a)
import SwiftUI

enum ShiftInputRoute: Hashable {
    /// 14a 시작 시트
    case start(year: Int, month: Int)
    /// 입력 화면 — `day`는 누른 날(없으면 첫 미등록 날 · DEC-014), `method`는 처음 고른 방법(14b에서 바꿀 수 있음)
    case editor(year: Int, month: Int, day: CalendarDay?, method: ShiftInputMethod = .keypad)
    /// 22a 순서 반복 — 누르면 바로 저장
    case repeatPattern(year: Int, month: Int)

    @MainActor @ViewBuilder
    func view(container: AppContainer, router: AppRouter) -> some View {
        switch self {
        case let .start(year, month):
            ShiftInputStartSheet(
                viewModel: ShiftInputStartViewModel(year: year, month: month, startShiftInput: container.startShiftInput),
                onMethod: { method in
                    router.present(AppCover.shiftInput(.editor(year: year, month: month, day: nil, method: method)))
                },
                onRepeat: { router.present(AppCover.shiftInput(.repeatPattern(year: year, month: month))) }
            )
        case let .repeatPattern(year, month):
            RepeatPatternView(
                viewModel: RepeatPatternViewModel(year: year, month: month, startShiftInput: container.startShiftInput,
                                                  applyShiftInput: container.applyShiftInput),
                onClose: { result in
                    if let result, result.savedDays > 0 {
                        router.dataDidChange()
                        // 문구는 원본에 없음(보류) — 22a 「저장한 뒤 ‘되돌리기’ 한 번으로 모두 취소」를 받는 자리
                        router.undoOffer = UndoOffer(message: "순서 반복으로 \(result.savedDays)일 채웠어요", revert: result.revert)
                    }
                    router.dismissCover()
                }
            )
        case let .editor(year, month, day, method):
            ShiftInputView(
                viewModel: ShiftInputViewModel(
                    range: StartShiftInputUseCase.month(year: year, month: month), cursor: day, method: method,
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
