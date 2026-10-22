// REQ-018 · REQ-019 · UI-IOS-3c
import Foundation
import Testing
@testable import Onoff

struct GetDayDetailUseCaseTests {
    private func useCase(memos: [Memo], duties: [CalendarDay: ShiftTypeID] = SampleData.octoberDuties) -> GetDayDetailUseCase {
        GetDayDetailUseCase(
            shiftTypes: InMemoryShiftTypeRepository(SampleData.shiftTypes),
            loadDutyDays: TestSupport.loadDutyDays(duties),
            memos: InMemoryMemoRepository(memos)
        )
    }

    @Test("E 근무 중 19:00 메모는 근무와 겹침, 시각 없는 메모는 아님")
    func eveningOverlap() async throws {
        let target = TestSupport.day(2026, 10, 5) // E
        let detail = try await useCase(memos: [
            Memo(id: UUID(), date: target, time: TimeOfDay(hour: 19), text: "저녁 약속"),
            Memo(id: UUID(), date: target, time: nil, text: "챙길 것"),
            Memo(id: UUID(), date: target, time: TimeOfDay(hour: 10), text: "오전 약속"),
        ])(target)
        #expect(detail.memos.map(\.memo.text) == ["오전 약속", "저녁 약속", "챙길 것"])
        #expect(detail.memos.map(\.overlapsShift) == [false, true, false])
    }

    @Test("전날 N이 이어지는 아침 메모도 겹침(날짜 넘김)")
    func carryOverOverlap() async throws {
        let target = TestSupport.day(2026, 10, 11) // 10/10 N 다음 OFF
        let detail = try await useCase(memos: [
            Memo(id: UUID(), date: target, time: TimeOfDay(hour: 6), text: "아침"),
            Memo(id: UUID(), date: target, time: TimeOfDay(hour: 8), text: "퇴근 뒤"),
        ])(target)
        #expect(detail.memos.map(\.overlapsShift) == [true, false])
        #expect(detail.bandSegments.isEmpty) // OFF는 띠가 비어 있다
    }

    @Test("빠른 선택은 앞쪽 근무 4개 + 첫 휴가 — 원본 D · E · N · OFF · 연차")
    func quickOptions() async throws {
        let detail = try await useCase(memos: [])(TestSupport.day(2026, 10, 12))
        #expect(detail.quickOptions.map(\.code) == ["D", "E", "N", "OFF", "연차"])
    }

    @Test("미등록 날")
    func unregisteredDay() async throws {
        let detail = try await useCase(memos: [])(TestSupport.day(2026, 11, 3))
        #expect(detail.duty.state == .unregistered)
        #expect(detail.bandSegments.isEmpty)
    }
}
