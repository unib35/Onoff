// 탭 · 스택 · 시트만 다룬다. 화면은 목적지만 요청한다(architecture.md).
import SwiftUI

@MainActor @Observable
final class AppRouter {
    var selectedTab: AppTab = .home
    var paths: [AppTab: [AppRoute]] = [:]
    var sheet: AppSheet?
    /// 전체 화면(근무 입력 14b · 5a)
    var cover: AppCover?
    /// 시트를 닫은 뒤 띄울 전체 화면 — 시트 위에 바로 띄우지 않는다
    private var pendingCover: AppCover?
    /// 저장된 근무가 바뀌면 올라간다 — 홈 · 근무표가 이 값으로 다시 불러온다
    private(set) var dataRevision = 0
    /// 바로 저장한 뒤 한 번 되돌릴 수 있게 아래에 띄우는 안내(순서 반복 22a)
    var undoOffer: UndoOffer?

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

    func present(_ cover: AppCover) {
        if sheet != nil {
            pendingCover = cover
            sheet = nil
        } else {
            self.cover = cover
        }
    }

    /// 시트가 닫힌 뒤(RootView) — 기다리던 전체 화면을 띄운다
    func sheetDidDismiss() {
        guard let pendingCover else { return }
        self.pendingCover = nil
        cover = pendingCover
    }

    func dismissCover() {
        cover = nil
    }

    func dataDidChange() {
        dataRevision += 1
    }
}

/// 「90일 채웠어요 · 되돌리기」 — 되돌릴 변경을 함께 든다
struct UndoOffer: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let revert: DutyChanges
}
