// 근무표 기능의 목적지 → 화면
import SwiftUI

enum RosterRoute: Hashable {
    case month
    case day(CalendarDay)

    @MainActor @ViewBuilder
    func view(container: AppContainer, router: AppRouter) -> some View {
        switch self {
        case .month:
            MonthlyRosterView(
                viewModel: MonthlyRosterViewModel(
                    getMonthlyRoster: container.getMonthlyRoster,
                    clock: container.clock,
                    features: container.features
                ),
                onSelectDay: { router.present(.roster(.day($0))) },
                onInput: { router.present(AppSheet.shiftInput(.start(year: $0, month: $1))) },
                dataRevision: router.dataRevision
            )
        case let .day(day):
            DayDetailSheet(viewModel: DayDetailViewModel(day: day, getDayDetail: container.getDayDetail))
        }
    }
}
