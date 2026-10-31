// 화면 상태 — 불러오기 성공 · 실패를 구분한다(code.md 오류 처리)
import Testing
@testable import Onoff

private struct FailingShiftTypeRepository: ShiftTypeRepository {
    struct Failure: Error {}
    func shiftTypes() async throws -> [ShiftType] { throw Failure() }
}

@MainActor
struct ViewModelTests {
    private func loadDutyDays(failing: Bool) -> LoadDutyDaysUseCase {
        failing
            ? LoadDutyDaysUseCase(shiftTypes: FailingShiftTypeRepository(), duties: InMemoryDutyRepository(SampleData.octoberDuties))
            : TestSupport.loadDutyDays()
    }

    @Test("홈: 불러오면 오늘 요약, 실패하면 failed", arguments: [false, true])
    func home(failing: Bool) async {
        let viewModel = HomeViewModel(
            getHomeSummary: GetHomeSummaryUseCase(loadDutyDays: loadDutyDays(failing: failing), clock: TestSupport.referenceClock),
            profileInitial: "가", features: .mvp
        )
        #expect(viewModel.state == .loading)
        await viewModel.load()
        if failing {
            #expect(viewModel.state == .failed)
        } else if case let .loaded(summary) = viewModel.state {
            #expect(summary.today.date == TestSupport.day(2026, 10, 4))
        } else {
            Issue.record("loaded 아님: \(viewModel.state)")
        }
    }

    @Test("월간: 이번 달(기준 시각의 달)을 불러온다, 실패하면 failed", arguments: [false, true])
    func monthly(failing: Bool) async {
        let types: any ShiftTypeRepository = failing ? FailingShiftTypeRepository() : InMemoryShiftTypeRepository(SampleData.shiftTypes)
        let viewModel = MonthlyRosterViewModel(
            getMonthlyRoster: GetMonthlyRosterUseCase(shiftTypes: types, loadDutyDays: loadDutyDays(failing: failing),
                                                      memos: InMemoryMemoRepository(SampleData.memos), clock: TestSupport.referenceClock),
            clock: TestSupport.referenceClock, features: .mvp
        )
        await viewModel.loadCurrentMonth()
        if failing {
            #expect(viewModel.state == .failed)
        } else if case let .loaded(roster) = viewModel.state {
            #expect(roster.month == 10)
        } else {
            Issue.record("loaded 아님: \(viewModel.state)")
        }
    }

    @Test("날짜 상세 · 근무 유형: 불러오기")
    func detailAndShiftTypes() async {
        let detail = DayDetailViewModel(day: TestSupport.day(2026, 10, 12), getDayDetail: GetDayDetailUseCase(
            shiftTypes: InMemoryShiftTypeRepository(SampleData.shiftTypes), loadDutyDays: TestSupport.loadDutyDays(),
            memos: InMemoryMemoRepository(SampleData.memos)))
        await detail.load()
        if case let .loaded(value) = detail.state { #expect(value.memos.count == 2) } else { Issue.record("detail 실패") }

        let list = ShiftTypeListViewModel(getShiftTypes: GetShiftTypesUseCase(repository: FailingShiftTypeRepository()))
        await list.load()
        #expect(list.state == .failed)
    }
}
