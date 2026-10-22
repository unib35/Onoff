// REQ-016 · REQ-038 · DEC-012 · UI-IOS-12a — 12a에서 알람(오늘의 순서) · 「확인할 일」을 뺀 버전
import SwiftUI

struct HomeView: View {
    @State var viewModel: HomeViewModel
    let onProfile: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                header
                if case .failed = viewModel.state {
                    LoadFailedView { Task { await viewModel.load() } }
                }
                if case let .loaded(summary) = viewModel.state {
                    TodayCard(summary: summary)
                    HStack(spacing: 10) {
                        tomorrowCard(summary.tomorrow)
                        nextOffCard(summary.nextOff)
                    }
                    WeekStrip(week: summary.week, today: summary.today.date)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, OnoffSpace.m)
            .padding(.bottom, 120) // 떠 있는 탭바에 가리지 않게
        }
        .scrollIndicators(.hidden)
        .background(OnoffColor.background)
        .foregroundStyle(OnoffColor.ink)
        .task { await viewModel.load() }
    }

    private var header: some View {
        HStack {
            if case let .loaded(summary) = viewModel.state {
                Text(ShiftFormat.longDate(summary.today.date)).onoffText(16, .bold)
            }
            Spacer()
            // 종(알림 목록)은 1.2 — REQ-038
            Button(action: onProfile) {
                Text(viewModel.profileInitial)
                    .onoffText(15, .bold)
                    .foregroundStyle(OnoffColor.onInk)
                    .frame(width: 38, height: 38)
                    .background(OnoffColor.avatar, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("내 정보")
        }
        .frame(height: 40)
    }

    private func tomorrowCard(_ duty: DutyDay) -> some View {
        SmallCard(title: "내일 (\(ShiftFormat.weekday(duty.date)))") {
            if let type = duty.state.shiftType {
                SmallShiftChip(type: type)
                Text(ShiftFormat.compactTime(type)).onoffText(16, .bold, numeric: true)
            } else {
                UnregisteredPattern(cornerRadius: 8).frame(width: 26, height: 26)
                Text("근무표 미등록").onoffText(16, .bold)
            }
        }
    }

    private func nextOffCard(_ nextOff: HomeSummary.NextOff?) -> some View {
        SmallCard(title: nextOff.map { "다음 OFF · \($0.daysFromToday)일 후" } ?? "다음 OFF") {
            if let nextOff {
                SmallShiftChip(type: nextOff.type)
                Text(ShiftFormat.shortDate(nextOff.date)).onoffText(16, .bold)
            } else {
                Text("근무표 미등록").onoffText(16, .bold)
            }
        }
    }
}

// MARK: - 오늘 카드

private struct TodayCard: View {
    let summary: HomeSummary

    var body: some View {
        let type = summary.today.state.shiftType
        let colors = type.map { ShiftPalette.colors(for: $0.colorKey) }
            ?? ShiftColors(background: OnoffColor.card, foreground: OnoffColor.ink)

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("오늘 근무")
                    .onoffText(13, .bold)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 11)
                    .background(OnoffColor.card.opacity(0.45), in: Capsule())
                Spacer()
                if let minutes = summary.minutesUntilStart {
                    Text("출근까지 \(ShiftFormat.remaining(minutes))").onoffText(14, .semibold, numeric: true)
                } else if let end = summary.workingUntil {
                    // 근무 중 — 전날 N이 이어지는 아침 포함(REQ-007). 예정과 실제 구분(디자인 시스템 10)
                    Text("퇴근 예정 \(DurationText.clock(end))").onoffText(14, .semibold, numeric: true)
                }
            }

            if let type {
                HStack(alignment: .bottom, spacing: 14) {
                    // 원본 line-height 0.74 — 글자 위아래 여백을 줄인다
                    Text(type.code)
                        .font(OnoffFont.serif(96))
                        .lineLimit(1)
                        .fixedSize()
                        .padding(.vertical, -96 * 0.13)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(ShiftFormat.nameAndDuration(type)).onoffText(15, .bold, numeric: true)
                        if !type.isAllDay {
                            Text(ShiftFormat.wideTime(type)).onoffText(28, .bold, numeric: true)
                        }
                    }
                }
                DayTimeBand(
                    segments: summary.todayBand,
                    trackColor: OnoffColor.card.opacity(0.4),
                    barColor: colors.foreground,
                    height: 24,
                    cornerRadius: 8,
                    barInset: 4,
                    barCornerRadius: 5,
                    nowFraction: summary.nowFraction,
                    nowColor: colors.foreground
                )
            } else {
                Text("근무표 미등록").onoffText(28, .bold)
            }
        }
        .foregroundStyle(colors.foreground)
        .padding(EdgeInsets(top: 18, leading: 18, bottom: 14, trailing: 18))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            if type == nil {
                UnregisteredPattern(cornerRadius: OnoffRadius.sheet)
            } else {
                RoundedRectangle(cornerRadius: OnoffRadius.sheet).fill(colors.background)
            }
        }
    }
}

// MARK: - 작은 카드

private struct SmallCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).onoffText(13, .semibold).foregroundStyle(OnoffColor.textSecondary)
            HStack(spacing: 8) { content }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OnoffColor.card, in: RoundedRectangle(cornerRadius: OnoffRadius.card))
    }
}

/// 26×26 근무 칩 — 근무는 Instrument Serif, OFF · 휴가처럼 글자가 긴 코드는 본문 글자
private struct SmallShiftChip: View {
    let type: ShiftType

    var body: some View {
        if type.code.count == 1 {
            ShiftChip(code: type.code, colorKey: type.colorKey, width: 26, height: 26, cornerRadius: 8, fontSize: 19, serif: true)
        } else {
            ShiftChip(code: type.code, colorKey: type.colorKey, height: 26, cornerRadius: 8, fontSize: 12, horizontalPadding: 7)
                .fixedSize()
        }
    }
}

// MARK: - 이번 주

private struct WeekStrip: View {
    let week: [DutyDay]
    let today: CalendarDay

    var body: some View {
        HStack(spacing: 4) {
            ForEach(week, id: \.date) { duty in
                let isSunday = SeoulCalendar.weekdayIndex(duty.date) == 0
                VStack(spacing: 4) {
                    Text("\(ShiftFormat.weekday(duty.date)) \(duty.date.day)")
                        .onoffText(11, .semibold, numeric: true)
                        .foregroundStyle(isSunday ? OnoffColor.sunday : OnoffColor.textSecondary)
                    if let type = duty.state.shiftType {
                        ShiftChip(code: type.code, colorKey: type.colorKey, width: 32, height: 22,
                                  cornerRadius: OnoffRadius.chip, fontSize: type.code.count > 1 ? 11 : 12)
                    } else {
                        UnregisteredPattern(cornerRadius: OnoffRadius.chip).frame(width: 32, height: 22)
                    }
                }
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity)
                .overlay {
                    if duty.date == today {
                        RoundedRectangle(cornerRadius: OnoffRadius.cell).strokeBorder(OnoffColor.ink, lineWidth: 2)
                    }
                }
            }
        }
        .padding(EdgeInsets(top: 12, leading: 12, bottom: 10, trailing: 12))
        .background(OnoffColor.card, in: RoundedRectangle(cornerRadius: OnoffRadius.card))
    }
}
