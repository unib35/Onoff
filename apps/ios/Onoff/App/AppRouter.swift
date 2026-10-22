// 탭 · 스택 · 시트만 다룬다. 화면은 목적지만 요청한다(architecture.md).
import SwiftUI

@MainActor @Observable
final class AppRouter {
    var selectedTab: AppTab = .home
    var paths: [AppTab: [AppRoute]] = [:]
    var sheet: AppSheet?

    func path(for tab: AppTab) -> Binding<[AppRoute]> {
        Binding(get: { self.paths[tab, default: []] }, set: { self.paths[tab] = $0 })
    }

    var isAtRoot: Bool { paths[selectedTab, default: []].isEmpty }

    func navigate(_ route: AppRoute) {
        paths[selectedTab, default: []].append(route)
    }

    func back() {
        guard !paths[selectedTab, default: []].isEmpty else { return }
        paths[selectedTab]?.removeLast()
    }

    func backToRoot() {
        paths[selectedTab] = []
    }

    func present(_ sheet: AppSheet) {
        self.sheet = sheet
    }

    func dismissSheet() {
        sheet = nil
    }
}
