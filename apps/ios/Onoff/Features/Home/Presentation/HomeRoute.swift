// 홈 기능의 목적지 → 화면
import SwiftUI

enum HomeRoute: Hashable {
    case root

    @MainActor @ViewBuilder
    func view(container: AppContainer, router: AppRouter) -> some View {
        switch self {
        case .root:
            HomeView(
                viewModel: HomeViewModel(
                    getHomeSummary: container.getHomeSummary,
                    profileInitial: container.profileInitial,
                    features: container.features
                ),
                // 임시 진입점: 설정(8b · 15e)이 생기기 전까지 프로필 → 근무 유형
                onProfile: { router.navigate(.shiftType(.list)) }
            )
        }
    }
}
