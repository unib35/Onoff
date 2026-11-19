// REQ-007 · REQ-008 · REQ-017 · UI-IOS-22e(1f를 1.0으로 덜어낸 안) — 이번 달 근무표 + 다음 달 한 줄.
// 칸에는 날짜와 근무만. 전날 나이트가 이어지는 날은 칸 위 남색 띠(시각은 날짜를 누르면 3c에서).
// 희망 듀티 · 신청 마감 · 사진 버튼은 그 기능이 나오는 버전에서(REQ-038).
import SwiftUI

struct MonthlyRosterView: View {
    @State var viewModel: MonthlyRosterViewModel
    let onSelectDay: (CalendarDay) -> Void
    /// 근무 입력 시작(14a) — 그 달(연 · 월)
    let onInput: (Int, Int) -> Void
    /// 저장된 근무가 바뀌면 바뀐다 — 다시 불러온다
    let dataRevision: Int

    var body: some View {
        ScrollView {
            if case .failed = viewModel.state {
                LoadFailedView { Task { await viewModel.loadCurrentMonth() } }
                    .padding(.horizontal, OnoffSpace.xl)
            }
            if case let .loaded(roster) = viewModel.state {
                VStack(alignment: .leading, spacing: 12) {
                    header(roster)
                    MonthGrid(roster: roster, onSelectDay: onSelectDay)
                    if roster.nextMonth.isAllUnregistered {
                        NextMonthRow(month: roster.nextMonth.month) { inputNextMonth(roster) }
                    }
                }
                .padding(.horizontal, OnoffSpace.xl)
                .padding(.top, OnoffSpace.xs)
                .padding(.bottom, 120)
            }
        }
        .scrollIndicators(.hidden)
        .background(OnoffColor.background)
        .foregroundStyle(OnoffColor.ink)
        .task(id: dataRevision) { await viewModel.loadCurrentMonth() }
    }

    private func inputNextMonth(_ roster: MonthlyRoster) {
        guard let first = roster.nextMonth.days.first?.date else { return }
        onInput(first.year, first.month)
    }

    private func header(_ roster: MonthlyRoster) -> some View {
        HStack(alignment: .bottom) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(roster.month)월").onoffText(30, .bold)
                Text(String(roster.year)).onoffText(15).foregroundStyle(OnoffColor.textTertiary)
            }
            Spacer()
            Button { Task { await viewModel.loadCurrentMonth() } } label: {
                Text("오늘")
                    .onoffText(14, .semibold)
                    .padding(.horizontal, 14)
                    .frame(height: 36)
                    .background(OnoffColor.card, in: Capsule())
                    .overlay(Capsule().strokeBorder(OnoffColor.line, lineWidth: 1))
            }
            .buttonStyle(.plain)
            // 22e 「+ 넣기」 — 근무 입력 시작(14a)
            Button { onInput(roster.year, roster.month) } label: {
                HStack(spacing: 5) {
                    Image(systemName: "plus").font(.system(size: 13, weight: .bold))
                    Text("넣기").onoffText(14, .semibold)
                }
                .foregroundStyle(OnoffColor.onInk)
                .padding(.leading, 11)
                .padding(.trailing, 14)
                .frame(height: 36)
                .background(OnoffColor.ink, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, OnoffSpace.xs)
    }
}

// MARK: - 달력

private struct MonthGrid: View {
    let roster: MonthlyRoster
    let onSelectDay: (CalendarDay) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 0) {
                ForEach(Array(ShiftFormat.weekdays.enumerated()), id: \.offset) { index, name in
                    Text(name)
                        .onoffText(12, .semibold)
                        .foregroundStyle(index == 0 ? OnoffColor.sunday : OnoffColor.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(0..<roster.leadingBlanks, id: \.self) { _ in Color.clear.frame(height: 60) }
                ForEach(roster.days) { day in
                    Button { onSelectDay(day.duty.date) } label: { DayCell(day: day) }
                        .buttonStyle(.plain)
                }
            }
            summary
        }
        .padding(EdgeInsets(top: 12, leading: 8, bottom: 8, trailing: 8))
        .background(OnoffColor.card, in: RoundedRectangle(cornerRadius: OnoffRadius.panel))
    }

    /// 22e 「근무 21일 · OFF 10일」 · 「182시간」
    private var summary: some View {
        HStack {
            Text("근무 \(roster.workDays)일 · OFF \(roster.offDays)일")
            Spacer()
            Text(DurationText.hoursMinutes(roster.workMinutes))
        }
        .onoffText(13, numeric: true)
        .foregroundStyle(OnoffColor.textSecondary)
        .padding(EdgeInsets(top: 8, leading: 8, bottom: 2, trailing: 8))
        .overlay(alignment: .top) { Rectangle().fill(OnoffColor.divider).frame(height: 1) }
    }
}

private struct DayCell: View {
    let day: RosterDay

    var body: some View {
        let isSunday = SeoulCalendar.weekdayIndex(day.duty.date) == 0
        VStack(spacing: 4) {
            Text("\(day.duty.date.day)")
                .onoffText(13, .semibold, numeric: true)
                .foregroundStyle(isSunday ? OnoffColor.sunday : OnoffColor.textSecondary)
                .frame(height: 15)
            Group {
                if let type = day.duty.state.shiftType {
                    ShiftChip(code: type.code, colorKey: type.colorKey, height: 22, cornerRadius: 7,
                              fontSize: type.code.count > 1 ? 12 : 13)
                } else {
                    // 미등록 — OFF로 보이지 않게(REQ-008)
                    UnregisteredPattern(cornerRadius: 7).frame(height: 22)
                }
            }
            .overlay(alignment: .top) {
                // 전날 나이트가 이어짐 — 칩 위 남색 띠(22e). 시각은 날짜 상세(3c)에서
                if day.carryOverEnd != nil {
                    UnevenRoundedRectangle(topLeadingRadius: 7, topTrailingRadius: 7)
                        .fill(ShiftPalette.colors(for: day.carryOverColorKey ?? "").background)
                        .frame(height: 5)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(EdgeInsets(top: 5, leading: 2, bottom: 0, trailing: 2))
        .frame(height: 60)
        .frame(maxWidth: .infinity)
        .background {
            if day.isToday {
                RoundedRectangle(cornerRadius: OnoffRadius.cell).fill(OnoffColor.card)
                RoundedRectangle(cornerRadius: OnoffRadius.cell).strokeBorder(OnoffColor.ink, lineWidth: 2)
            }
        }
        .overlay(alignment: .topTrailing) {
            if day.hasMemo {
                Circle().fill(OnoffColor.ink).frame(width: 6, height: 6).padding(.top, 6).padding(.trailing, 5)
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint(day.carryOverEnd.map { "전날 나이트가 \($0.hour)시 \($0.minute)분까지 이어짐" } ?? "")
    }
}

// MARK: - 다음 달

/// 22e 「11월 근무표 · 아직 안 넣었어요 · 넣기」
private struct NextMonthRow: View {
    let month: Int
    let onInput: () -> Void

    var body: some View {
        HStack(spacing: OnoffSpace.l) {
            UnregisteredPattern(cornerRadius: 8).frame(width: 32, height: 32)
            VStack(alignment: .leading, spacing: 1) {
                Text("\(month)월 근무표").onoffText(15, .bold)
                Text("아직 안 넣었어요").onoffText(13).foregroundStyle(OnoffColor.textSecondary)
            }
            Spacer()
            Button(action: onInput) {
                Text("넣기").onoffText(14, .bold)
                    .foregroundStyle(OnoffColor.onInk)
                    .padding(.horizontal, OnoffSpace.xl)
                    .frame(height: 36)
                    .background(OnoffColor.ink, in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(month)월 근무 넣기")
        }
        .padding(EdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 12))
        .background(OnoffColor.card, in: RoundedRectangle(cornerRadius: 18))
    }
}
