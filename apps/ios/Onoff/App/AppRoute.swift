// 내비게이션 목적지 — 기능별 Route를 감싼다(architecture.md)
import SwiftUI

enum AppTab: String, Hashable, CaseIterable {
    case home, roster
}

enum AppRoute: Hashable {
    case shiftType(ShiftTypeRoute)

    @MainActor @ViewBuilder
    func view(container: AppContainer, router: AppRouter) -> some View {
        switch self {
        case let .shiftType(route): route.view(container: container, router: router)
        }
    }
}

enum AppSheet: Hashable, Identifiable {
    case roster(RosterRoute)
    case shiftInput(ShiftInputRoute)

    var id: Self { self }

    @MainActor @ViewBuilder
    func view(container: AppContainer, router: AppRouter) -> some View {
        switch self {
        case let .roster(route): route.view(container: container, router: router)
        case let .shiftInput(route): route.view(container: container, router: router)
        }
    }
}

/// 전체 화면으로 띄우는 목적지
enum AppCover: Hashable, Identifiable {
    case shiftInput(ShiftInputRoute)

    var id: Self { self }

    @MainActor @ViewBuilder
    func view(container: AppContainer, router: AppRouter) -> some View {
        switch self {
        case let .shiftInput(route): route.view(container: container, router: router)
        }
    }
}
