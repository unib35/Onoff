// REQ-017 · UI-IOS-1f
import Foundation

@MainActor @Observable
final class MonthlyRosterViewModel {
    enum State: Equatable {
        case loading
        case loaded(MonthlyRoster)
        case failed
    }

    private(set) var state: State = .loading
    let features: ReleaseFeatures
    private let getMonthlyRoster: GetMonthlyRosterUseCase
    private let clock: any AppClock

    init(getMonthlyRoster: GetMonthlyRosterUseCase, clock: any AppClock, features: ReleaseFeatures) {
        self.getMonthlyRoster = getMonthlyRoster
        self.clock = clock
        self.features = features
    }

    /// 이번 달(오늘이 속한 달)을 불러온다 — 「오늘」 버튼도 같은 동작
    func loadCurrentMonth() async {
        let today = SeoulCalendar.day(of: clock.now())
        do {
            state = .loaded(try await getMonthlyRoster(year: today.year, month: today.month))
        } catch {
            state = .failed
        }
    }
}
