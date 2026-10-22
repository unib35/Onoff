// 앱 진입점
import SwiftUI

@main
struct OnoffApp: App {
    // 저장소가 생기기 전까지 원본 캔버스 샘플로 띄운다(이슈 #3 범위)
    @State private var container = AppContainer.sample()

    var body: some Scene {
        WindowGroup {
            RootView(container: container)
                .environment(\.locale, Locale(identifier: "ko_KR"))
        }
    }
}
