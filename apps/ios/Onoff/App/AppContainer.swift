// DI 조립 — Live/InMemory 구현을 이 한 곳에서 만든다(architecture.md). 지금은 저장소가 없어 InMemory + 샘플 데이터.
import Foundation

@MainActor
final class AppContainer {
    let features: ReleaseFeatures
    let clock: any AppClock
    let shiftTypes: any ShiftTypeRepository
    let duties: any DutyRepository
    let memos: any MemoRepository
    /// 홈 프로필 동그라미 글자 — 계정(15e)이 생기면 거기서 가져온다
    let profileInitial: String

    init(
        features: ReleaseFeatures,
        clock: any AppClock,
        shiftTypes: any ShiftTypeRepository,
        duties: any DutyRepository,
        memos: any MemoRepository,
        profileInitial: String
    ) {
        self.features = features
        self.clock = clock
        self.shiftTypes = shiftTypes
        self.duties = duties
        self.memos = memos
        self.profileInitial = profileInitial
    }

    /// 원본 캔버스와 같은 화면 — 기준 시각 2026-10-04 09:41 고정
    static func sample() -> AppContainer {
        AppContainer(
            features: .mvp,
            clock: FixedClock(date: SampleData.referenceNow),
            shiftTypes: InMemoryShiftTypeRepository(SampleData.shiftTypes),
            duties: InMemoryDutyRepository(SampleData.octoberDuties),
            memos: InMemoryMemoRepository(SampleData.memos),
            profileInitial: "서"
        )
    }

    // MARK: - UseCase

    var loadDutyDays: LoadDutyDaysUseCase { LoadDutyDaysUseCase(shiftTypes: shiftTypes, duties: duties) }
    var getHomeSummary: GetHomeSummaryUseCase { GetHomeSummaryUseCase(loadDutyDays: loadDutyDays, clock: clock) }
    var getMonthlyRoster: GetMonthlyRosterUseCase {
        GetMonthlyRosterUseCase(shiftTypes: shiftTypes, loadDutyDays: loadDutyDays, memos: memos, clock: clock)
    }
    var getDayDetail: GetDayDetailUseCase { GetDayDetailUseCase(shiftTypes: shiftTypes, loadDutyDays: loadDutyDays, memos: memos) }
    var getShiftTypes: GetShiftTypesUseCase { GetShiftTypesUseCase(repository: shiftTypes) }
}
