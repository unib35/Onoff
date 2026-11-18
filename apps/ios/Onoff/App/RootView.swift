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

            if let offer = router.undoOffer {
                UndoToast(offer: offer) {
                    router.undoOffer = nil
                    Task {
                        do {
                            try await container.applyShiftInput.revert(offer.revert)
                            router.dataDidChange()
                        } catch {
                            router.undoFailed = true
                        }
                    }
                } onExpire: {
                    if router.undoOffer == offer { router.undoOffer = nil }
                }
                .padding(.horizontal, OnoffSpace.xl)
                .padding(.bottom, router.isAtRoot ? 100 : OnoffSpace.xl)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.default, value: router.undoOffer)
        // 문구는 원본에 없음(보류)
        .alert("되돌리지 못했어요", isPresented: $router.undoFailed) {
            Button("확인", role: .cancel) {}
        }
        .sheet(item: $router.sheet, onDismiss: router.sheetDidDismiss) { sheet in
            sheet.view(container: container, router: router)
        }
        .fullScreenCover(item: $router.cover) { cover in
            cover.view(container: container, router: router)
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

/// 바로 저장한 뒤 「되돌리기」 — 원본에 이 안내 모양은 없다(보류). 8초 뒤 사라진다.
private struct UndoToast: View {
    let offer: UndoOffer
    let onUndo: () -> Void
    let onExpire: () -> Void

    var body: some View {
        HStack(spacing: OnoffSpace.l) {
            Text(offer.message).onoffText(14, .semibold)
            Spacer(minLength: 0)
            Button("되돌리기", action: onUndo).onoffText(14, .heavy).buttonStyle(.plain)
        }
        .foregroundStyle(OnoffColor.onInk)
        .padding(.horizontal, OnoffSpace.xl)
        .frame(minHeight: 48)
        .background(OnoffColor.ink, in: RoundedRectangle(cornerRadius: 16))
        .task(id: offer.id) {
            try? await Task.sleep(for: .seconds(8))
            onExpire()
        }
    }
}
