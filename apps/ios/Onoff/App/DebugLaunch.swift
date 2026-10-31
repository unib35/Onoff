// 개발용 — 시뮬레이터 스크린샷을 원본과 비교하려고 실행 인자로 첫 화면을 고른다. 출시 빌드에는 없다.
// 예: xcrun simctl launch "iPhone 17" app.onoff.ios -onoffScreen roster-day-12
#if DEBUG
import Foundation

@MainActor
enum DebugLaunch {
    static func apply(to router: AppRouter) {
        guard let screen = UserDefaults.standard.string(forKey: "onoffScreen") else { return }
        switch screen {
        case "roster":
            router.selectedTab = .roster
        case let value where value.hasPrefix("roster-day-"):
            router.selectedTab = .roster
            if let day = Int(value.dropFirst("roster-day-".count)) {
                router.present(.roster(.day(CalendarDay(year: 2026, month: 10, day: day))))
            }
        case "shift-types":
            router.navigate(.shiftType(.list))
        default:
            break
        }
    }
}
#endif
