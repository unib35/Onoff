// REQ-018 · UI-IOS-3c
import Foundation

@MainActor @Observable
final class DayDetailViewModel {
    enum State: Equatable {
        case loading
        case loaded(DayDetail)
        case failed
    }

    let day: CalendarDay
    private(set) var state: State = .loading
    private let getDayDetail: GetDayDetailUseCase

    init(day: CalendarDay, getDayDetail: GetDayDetailUseCase) {
        self.day = day
        self.getDayDetail = getDayDetail
    }

    func load() async {
        do {
            state = .loaded(try await getDayDetail(day))
        } catch {
            state = .failed
        }
    }
}
