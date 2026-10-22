// REQ-007 · REQ-008 · REQ-017 · UI-IOS-1f — 이번 달 근무표 + 다음 달 「미등록」
import SwiftUI

struct MonthlyRosterView: View {
    @State var viewModel: MonthlyRosterViewModel
    let onSelectDay: (CalendarDay) -> Void

    var body: some View {
        ScrollView {
            if case let .loaded(roster) = viewModel.state {
                VStack(alignment: .leading, spacing: 12) {
                    header(roster)
                    MonthGrid(roster: roster, onSelectDay: onSelectDay)
                    if roster.nextMonth.isAllUnregistered {
                        NextMonthCard(nextMonth: roster.nextMonth)
                    }
                    Text(summaryText(roster))
                        .onoffText(13, numeric: true)
                        .foregroundStyle(OnoffColor.textSecondary)
                        .padding(.horizontal, 6)
                }
                .padding(.horizontal, OnoffSpace.xl)
                .padding(.top, OnoffSpace.xs)
                .padding(.bottom, 120)
            }
        }
        .scrollIndicators(.hidden)
        .background(OnoffColor.background)
        .foregroundStyle(OnoffColor.ink)
        .task { await viewModel.loadCurrentMonth() }
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
            // 「사진」 버튼은 1.2(사진으로 넣기) — REQ-038
        }
        .padding(.horizontal, OnoffSpace.xs)
    }

    /// 「10월 예정 · D 8 · E 6 · N 7 · OFF 10 · 182시간」
    private func summaryText(_ roster: MonthlyRoster) -> String {
        let counts = roster.counts.map { "\($0.type.code) \($0.count)" }
        return (["\(roster.month)월 예정"] + counts + [DurationText.hoursMinutes(roster.workMinutes)]).joined(separator: " · ")
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
            legend
        }
        .padding(EdgeInsets(top: 12, leading: 8, bottom: 8, trailing: 8))
        .background(OnoffColor.card, in: RoundedRectangle(cornerRadius: 22))
    }

    private var legend: some View {
        HStack(spacing: 12) {
            HStack(spacing: 5) {
                Circle().fill(OnoffColor.ink).frame(width: 6, height: 6)
                Text("개인 일정")
            }
            HStack(spacing: 5) {
                Text("~7:30").fontWeight(.bold).foregroundStyle(ShiftPalette.colors(for: "N").background)
                Text("전날 나이트가 이어짐")
            }
            Spacer()
        }
        .onoffText(12)
        .foregroundStyle(OnoffColor.textSecondary)
        .padding(EdgeInsets(top: 6, leading: 6, bottom: 2, trailing: 6))
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
            if let type = day.duty.state.shiftType {
                ShiftChip(code: type.code, colorKey: type.colorKey, height: 22, cornerRadius: 7,
                          fontSize: type.code.count > 1 ? 12 : 13)
            } else {
                // 미등록 — OFF로 보이지 않게(REQ-008)
                UnregisteredPattern(cornerRadius: 7).frame(height: 22)
            }
            if let end = day.carryOverEnd {
                Text("~\(end.hour):\(String(format: "%02d", end.minute))")
                    .onoffText(12, .bold, numeric: true)
                    .foregroundStyle(ShiftPalette.colors(for: "N").background)
                    .frame(height: 12)
            }
            Spacer(minLength: 0)
        }
        .padding(EdgeInsets(top: 5, leading: 2, bottom: 0, trailing: 2))
        .frame(height: 60)
        .frame(maxWidth: .infinity)
        .background {
            if day.isToday {
                RoundedRectangle(cornerRadius: 10).fill(OnoffColor.card)
                RoundedRectangle(cornerRadius: 10).strokeBorder(OnoffColor.ink, lineWidth: 2)
            }
        }
        .overlay(alignment: .topTrailing) {
            if day.hasMemo {
                Circle().fill(OnoffColor.ink).frame(width: 6, height: 6).padding(.top, 6).padding(.trailing, 5)
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

// MARK: - 다음 달

private struct NextMonthCard: View {
    let nextMonth: MonthlyRoster.NextMonth

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(nextMonth.month)월").onoffText(17, .bold)
                Spacer()
                Text("근무표 미등록")
                    .onoffText(12, .bold)
                    .foregroundStyle(OnoffColor.textSecondary)
                    .padding(.horizontal, 10)
                    .frame(height: 26)
                    .background(UnregisteredPattern(cornerRadius: 8))
            }
            HStack(spacing: 2) {
                ForEach(nextMonth.days, id: \.date) { _ in
                    UnregisteredPattern(cornerRadius: 3).frame(height: 26)
                }
            }
            HStack {
                Text("1")
                Spacer()
                // 「14–17 희망 듀티」는 1.3 — REQ-038
                Text("\(nextMonth.days.count)")
            }
            .onoffText(12, numeric: true)
            .foregroundStyle(OnoffColor.textTertiary)
            .padding(.top, -4)
            // 「희망 듀티 4건 준비 중 · 신청 마감」은 1.3 — REQ-038
            Text("OFF가 아니라 아직 정보가 없는 상태예요.")
                .onoffText(14, .bold)
                .lineSpacing(14 * 0.5)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, OnoffSpace.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OnoffColor.card, in: RoundedRectangle(cornerRadius: 22))
    }
}
