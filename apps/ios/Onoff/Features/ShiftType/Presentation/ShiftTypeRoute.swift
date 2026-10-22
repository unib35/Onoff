// 근무 유형 기능의 목적지 → 화면
import SwiftUI

enum ShiftTypeRoute: Hashable {
    case list

    @MainActor @ViewBuilder
    func view(container: AppContainer, router: AppRouter) -> some View {
        switch self {
        case .list:
            ShiftTypeListView(
                viewModel: ShiftTypeListViewModel(getShiftTypes: container.getShiftTypes),
                onBack: { router.back() }
            )
        }
    }
}
