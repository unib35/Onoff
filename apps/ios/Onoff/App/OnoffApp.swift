// 앱 진입점
import SwiftUI

@main
struct OnoffApp: App {
    @State private var launch = Launch.start()

    var body: some Scene {
        WindowGroup {
            Group {
                switch launch {
                case let .ready(container):
                    RootView(container: container)
                case .failed:
                    // 저장소를 열지 못함 — 빈 화면으로 넘어가 데이터가 없는 것처럼 보이지 않게 한다(REQ-008)
                    LoadFailedView { launch = Launch.start() }
                        .padding(OnoffSpace.xl)
                        .frame(maxHeight: .infinity)
                        .background(OnoffColor.background)
                }
            }
            .environment(\.locale, Locale(identifier: "ko_KR"))
        }
    }
}

private enum Launch {
    case ready(AppContainer)
    case failed

    @MainActor
    static func start() -> Launch {
        #if DEBUG
        // 화면 확인(-onoffScreen)은 원본 캔버스 샘플로 — DebugLaunch
        if UserDefaults.standard.string(forKey: "onoffScreen") != nil { return .ready(.sample()) }
        #endif
        do {
            return .ready(try .live(store: LocalStore.makeContainer()))
        } catch {
            return .failed
        }
    }
}
