// REQ-005 · UI-IOS-5b
import Foundation

@MainActor @Observable
final class ShiftTypeListViewModel {
    enum State: Equatable {
        case loading
        case loaded(ShiftTypeList)
        case failed
    }

    private(set) var state: State = .loading
    private let getShiftTypes: GetShiftTypesUseCase

    init(getShiftTypes: GetShiftTypesUseCase) {
        self.getShiftTypes = getShiftTypes
    }

    func load() async {
        do {
            state = .loaded(try await getShiftTypes())
        } catch {
            state = .failed
        }
    }
}
