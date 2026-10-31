// REQ-016 · UI-IOS-12a
import Foundation

@MainActor @Observable
final class HomeViewModel {
    enum State: Equatable {
        case loading
        case loaded(HomeSummary)
        case failed
    }

    private(set) var state: State = .loading
    let profileInitial: String
    let features: ReleaseFeatures
    private let getHomeSummary: GetHomeSummaryUseCase

    init(getHomeSummary: GetHomeSummaryUseCase, profileInitial: String, features: ReleaseFeatures) {
        self.getHomeSummary = getHomeSummary
        self.profileInitial = profileInitial
        self.features = features
    }

    func load() async {
        do {
            state = .loaded(try await getHomeSummary())
        } catch {
            state = .failed
        }
    }
}
