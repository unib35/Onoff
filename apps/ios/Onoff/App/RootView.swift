// REQ-039 · DEC-009 · DEC-011 — 1.0 탭은 홈 · 근무표 두 개. 떠 있는 탭바(디자인 시스템 07)는 각 탭 첫 화면에서만.
import SwiftUI

struct RootView: View {
    let container: AppContainer
    @State private var router = AppRouter()

    private var tabItems: [FloatingTabItem] {
        [
            FloatingTabItem(id: AppTab.home.rawValue, title: "홈", icon: .home),
            FloatingTabItem(id: AppTab.roster.rawValue, title: "근무표", icon: .roster),
        ]
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            switch router.selectedTab {
            case .home:
                stack(for: .home) { HomeRoute.root.view(container: container, router: router) }
            case .roster:
                stack(for: .roster) { RosterRoute.month.view(container: container, router: router) }
            }

            if router.isAtRoot {
                FloatingTabBar(
                    items: tabItems,
                    selection: Binding(get: { router.selectedTab.rawValue }, set: { router.selectedTab = AppTab(rawValue: $0) ?? .home })
                )
                .padding(.horizontal, OnoffSpace.xl)
                .padding(.bottom, 26) // 원본: 화면 아래 끝에서 26
                .ignoresSafeArea(.container, edges: .bottom)
            }
        }
        .sheet(item: $router.sheet) { sheet in
            sheet.view(container: container, router: router)
        }
        #if DEBUG
        .task { DebugLaunch.apply(to: router) }
        #endif
    }

    private func stack(for tab: AppTab, @ViewBuilder root: () -> some View) -> some View {
        NavigationStack(path: router.path(for: tab)) {
            root()
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: AppRoute.self) { route in
                    route.view(container: container, router: router)
                        .toolbar(.hidden, for: .navigationBar)
                }
        }
    }
}
