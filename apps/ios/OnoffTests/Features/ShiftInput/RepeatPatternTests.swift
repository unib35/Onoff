// REQ-013 · UI-IOS-22a · UI-IOS-22b — 순서 반복 설정 · 화면 상태. 가짜 데이터만.
import Testing
@testable import Onoff

private func id(_ raw: String) -> ShiftTypeID { ShiftTypeID(rawValue: raw) }

struct RepeatPlanTests {
    private func day(_ d: Int) -> CalendarDay { TestSupport.day(2026, 11, d) }

    @Test("첫날 위치만큼 돌려서 채운다 · 휴가 그대로 · 이미 넣은 근무 그대로/덮어쓰기")
    func filled() {
        let base = DutyDraft(range: day(1)...day(30), original: [day(2): id("E"), day(3): id("AL")], protectedTypes: [id("AL")])
        var plan = RepeatPlan(pattern: [id("D"), id("N"), id("OFF")], startIndex: 1)
        var draft = plan.filled(base, through: day(5))
        // 1일 = 2번째(N), 2일 E 그대로(OFF 차례), 3일 연차(D 차례 — 이어서), 4일 N, 5일 OFF
        #expect(draft.changes.assigned == [day(1): id("N"), day(4): id("N"), day(5): id("OFF")])

        plan.keepExisting = false
        draft = plan.filled(base, through: day(5))
        #expect(draft.changes.assigned[day(2)] == id("OFF"))
        #expect(draft.shift(on: day(3)) == id("AL"))
        #expect(draft.changes.assigned[day(6)] == nil) // 끝 날 뒤는 안 건드림
    }

    @Test("되돌리기 변경: 없던 날은 미등록으로, 있던 날은 원래 값으로")
    func revert() {
        var draft = DutyDraft(range: day(1)...day(30), original: [day(2): id("E")], protectedTypes: [])
        draft.repeatPattern([id("D")], from: day(1), through: day(3))
        #expect(draft.revertChanges.cleared == [day(1), day(3)])
        #expect(draft.revertChanges.assigned == [day(2): id("E")])

        // 지운 날은 원래 값으로 다시
        var erased = DutyDraft(range: day(1)...day(30), original: [day(5): id("N")], protectedTypes: [])
        erased.paint(nil, days: [day(5)])
        #expect(erased.revertChanges.assigned == [day(5): id("N")])
        #expect(erased.revertChanges.cleared.isEmpty)
    }

    @Test("그대로 + 밀어서: 있는 근무는 번호를 쓰고, 휴가는 번호를 안 씀")
    func keepAndPush() {
        let base = DutyDraft(range: day(1)...day(30), original: [day(2): id("E"), day(3): id("AL")], protectedTypes: [id("AL")])
        var plan = RepeatPlan(pattern: [id("D"), id("N"), id("OFF")], startIndex: 0)
        plan.afterLeave = .push
        let draft = plan.filled(base, through: day(5))
        // 1일 D, 2일 E 그대로(N 차례), 3일 연차(번호 안 씀), 4일 OFF, 5일 D
        #expect(draft.changes.assigned == [day(1): id("D"), day(4): id("OFF"), day(5): id("D")])
    }

    @Test("해를 넘는 달 계산")
    func monthMath() {
        let dec = TestSupport.day(2026, 12, 1)
        #expect(RepeatPatternViewModel.monthStart(from: dec, adding: 1) == TestSupport.day(2027, 1, 1))
        #expect(RepeatPatternViewModel.monthEnd(from: dec, months: 3) == TestSupport.day(2027, 2, 28))
    }

    @Test("칸 고치기: 끝에 붙이기 · 빼고 당기기(최소 2칸) · 첫날 위치는 같은 칸")
    func edit() {
        var plan = RepeatPlan(pattern: [id("D"), id("N"), id("OFF")], startIndex: 2)
        plan.set(id("E"), at: 3)
        #expect(plan.pattern == [id("D"), id("N"), id("OFF"), id("E")])
        plan.remove(at: 0)
        #expect(plan.startIndex == 1 && plan.firstDayShift == id("OFF"))
        plan.remove(at: 1)
        plan.remove(at: 0) // 2칸이면 더 못 뺌
        #expect(plan.pattern.count == 2)
    }

    @Test("주간 고정은 요일로 시작 위치 — 2026-11-01은 일요일 → OFF")
    func weekdayFixed() {
        let index = RepeatPreset.weekdayFixed.startIndex(firstDay: day(1))
        #expect(RepeatPreset.weekdayFixed.pattern?[index] == id("OFF"))
        #expect(RepeatPreset.weekdayFixed.startIndex(firstDay: day(2)) == 0) // 월요일 = 첫 D
        #expect(RepeatPreset.fourTeamTwoShift.pattern?.count == 8)
    }
}

@MainActor
struct RepeatPatternViewModelTests {
    private func day(_ m: Int, _ d: Int) -> CalendarDay { TestSupport.day(2026, m, d) }

    private func model(_ saved: [CalendarDay: ShiftTypeID]) -> (RepeatPatternViewModel, InMemoryDutyRepository) {
        let duties = InMemoryDutyRepository(saved)
        let types = InMemoryShiftTypeRepository(SampleData.shiftTypes)
        return (RepeatPatternViewModel(year: 2026, month: 11,
                                       startShiftInput: StartShiftInputUseCase(shiftTypes: types, duties: duties),
                                       applyShiftInput: ApplyShiftInputUseCase(duties: duties)), duties)
    }

    @Test("22a: 4조 2교대 3달 — 연차 2일은 빼고 90일, 휴가 안내, 바로 저장 후 되돌리기")
    func fillAndRevert() async throws {
        let (vm, duties) = model([day(11, 13): id("AL"), day(11, 14): id("AL")])
        await vm.load()
        #expect(vm.preset == .fourTeamTwoShift)
        #expect(vm.months == 3 && vm.lastMonth == 1)
        #expect(vm.fillCount == 90) // 30 + 31 + 31 − 연차 2
        #expect(vm.keptLeaveNote == "11/13–14 연차는 그대로 둬요")
        #expect(vm.previewMonths.map(\.days.count) == [30, 31, 31])

        let result = try #require(await vm.fill())
        #expect(result.savedDays == 90)
        let saved = try await duties.assignments(from: day(11, 1), through: TestSupport.day(2027, 1, 31))
        #expect(saved.count == 92)
        try await ApplyShiftInputUseCase(duties: duties).revert(result.revert)
        let after = try await duties.assignments(from: day(11, 1), through: TestSupport.day(2027, 1, 31))
        #expect(after == [day(11, 13): id("AL"), day(11, 14): id("AL")])
    }

    @Test("22b: 칸을 누르고 근무를 넣으면 다음 칸으로 · 고치면 「직접」 · 첫날 근무가 바뀌면 안내")
    func editPattern() async throws {
        let (vm, _) = model([:])
        await vm.load()
        vm.removeMonth(); vm.removeMonth(); vm.removeMonth()
        #expect(vm.months == 1)
        vm.edit(0)
        let n = try #require(vm.keypadTypes.first { $0.code == "N" })
        vm.put(n)
        #expect(vm.editingIndex == 1)
        #expect(vm.preset == .custom)
        #expect(vm.firstDayChanged) // 11월 1일 D → N
        vm.edit(vm.plan.pattern.count) // 「+」
        #expect(vm.canRemove == false)
        vm.put(n)
        #expect(vm.plan.pattern.count == 9)
        vm.edit(8)
        vm.removeEditing()
        #expect(vm.plan.pattern.count == 8)
        vm.finishEditing()
        #expect(vm.isEditing == false)

        vm.choose(.weekdayFixed)
        #expect(vm.firstDayShift?.code == "OFF") // 일요일 시작
        #expect(vm.firstDayChanged == false)
    }

    @Test("첫날 안내: 고친 뒤 다른 칸을 고쳐도 남고, 첫날 위치를 고르면 사라짐 · 야간전담은 숨김")
    func firstDayNotice() async throws {
        let (vm, _) = model([:])
        await vm.load()
        #expect(vm.isAvailable(.nightOnly) == false)
        let n = try #require(vm.keypadTypes.first { $0.code == "N" })
        vm.edit(0); vm.put(n); vm.finishEditing()
        #expect(vm.firstDayChanged)
        vm.edit(2); vm.put(n)
        #expect(vm.firstDayChanged)
        vm.chooseStart(99) // 범위 밖은 마지막 칸으로
        #expect(vm.startIndex == vm.plan.pattern.count - 1)
        #expect(vm.firstDayChanged == false)
    }

    @Test("저장 실패: 알림, 결과 없음")
    func fillFails() async {
        let duties = FailingApply()
        let types = InMemoryShiftTypeRepository(SampleData.shiftTypes)
        let vm = RepeatPatternViewModel(year: 2026, month: 11, startShiftInput: StartShiftInputUseCase(shiftTypes: types, duties: duties),
                                        applyShiftInput: ApplyShiftInputUseCase(duties: duties))
        await vm.load()
        #expect(await vm.fill() == nil)
        #expect(vm.saveFailed)
    }

    @Test("D · N · OFF가 없으면 「직접」 — 휴가가 아닌 근무 두 칸")
    func fallbackPreset() async {
        let types = SampleData.shiftTypes.filter { !["D", "N"].contains($0.id.rawValue) }
        let duties = InMemoryDutyRepository([:])
        let vm = RepeatPatternViewModel(year: 2026, month: 11,
                                        startShiftInput: StartShiftInputUseCase(shiftTypes: InMemoryShiftTypeRepository(types), duties: duties),
                                        applyShiftInput: ApplyShiftInputUseCase(duties: duties))
        await vm.load()
        #expect(vm.preset == .custom)
        #expect(vm.plan.pattern.count == 2)
        #expect(vm.patternCells.allSatisfy { $0.shift?.kind != .leave })
    }

    @Test("이미 넣은 근무: 그대로면 세지 않고, 덮어쓰기면 센다 · 받침 따라 은/는")
    func keepExisting() async {
        let (vm, _) = model([day(11, 1): id("E")])
        await vm.load()
        vm.removeMonth(); vm.removeMonth()
        #expect(vm.fillCount == 29)
        vm.setKeepExisting(false)
        #expect(vm.fillCount == 30)
        #expect(RepeatPatternViewModel.topicParticle(after: "교육") == "은")
        #expect(RepeatPatternViewModel.topicParticle(after: "연차") == "는")
    }
}

private struct FailingApply: DutyRepository {
    struct Failure: Error {}
    func assignments(from: CalendarDay, through: CalendarDay) async throws -> [CalendarDay: ShiftTypeID] { [:] }
    func apply(_ changes: DutyChanges) async throws { throw Failure() }
}
