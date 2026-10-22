// REQ-018 · REQ-019 · REQ-038 · UI-IOS-3c — 1.0은 근무 · 메모만(알람 · 일정 줄 숨김)
import SwiftUI

struct DayDetailSheet: View {
    @State var viewModel: DayDetailViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Capsule()
                .fill(OnoffColor.sheetGrabber)
                .frame(width: 38, height: 5)
                .frame(maxWidth: .infinity)

            Text(ShiftFormat.titleDate(viewModel.day)).onoffText(24, .bold)
            // 「10/8 변경됨 · 이력」 배지는 변경 이력(1l) 이슈에서

            if case .failed = viewModel.state {
                LoadFailedView { Task { await viewModel.load() } }
            }
            if case let .loaded(detail) = viewModel.state {
                shiftRow(detail.duty)
                band(detail)
                if !detail.memos.isEmpty { memoSection(detail.memos) }
                quickChange(detail)
            }
            Spacer(minLength: 0)
        }
        .padding(EdgeInsets(top: 10, leading: 20, bottom: 34, trailing: 20))
        .foregroundStyle(OnoffColor.ink)
        .presentationDetents([.fraction(0.83), .large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(30)
        .presentationBackground(OnoffColor.card)
        .task { await viewModel.load() }
    }

    @ViewBuilder
    private func shiftRow(_ duty: DutyDay) -> some View {
        HStack(spacing: 14) {
            if let type = duty.state.shiftType {
                ShiftChip(code: type.code, colorKey: type.colorKey, width: 60, height: 60, cornerRadius: 16,
                          fontSize: type.code.count == 1 ? 42 : 20, serif: type.code.count == 1)
                VStack(alignment: .leading, spacing: 2) {
                    if !type.isAllDay {
                        Text(ShiftFormat.wideTime(type)).onoffText(26, .bold, numeric: true)
                    }
                    Text(ShiftFormat.nameAndDuration(type)).onoffText(14).foregroundStyle(OnoffColor.textSecondary)
                }
            } else {
                UnregisteredPattern(cornerRadius: 16).frame(width: 60, height: 60)
                Text("근무표 미등록").onoffText(26, .bold)
            }
        }
    }

    private func band(_ detail: DayDetail) -> some View {
        let colors = detail.duty.state.shiftType.map { ShiftPalette.colors(for: $0.colorKey) }
        return VStack(spacing: 5) {
            DayTimeBand(
                segments: detail.bandSegments,
                trackColor: OnoffColor.trackBackground,
                barColor: colors?.background ?? .clear
            )
            HStack {
                Text("0시")
                Spacer()
                // 「11:30 · 13:40 알람」은 1.1 — REQ-038
                Text("24시")
            }
            .onoffText(12, numeric: true)
            .foregroundStyle(OnoffColor.textTertiary)
        }
    }

    private func memoSection(_ items: [DayDetail.MemoItem]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("일정 · 메모")
                .onoffText(13, .bold)
                .foregroundStyle(OnoffColor.textTertiary)
                .padding(.bottom, 4)
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                HStack(spacing: 10) {
                    if let time = item.memo.time {
                        Text("\(DurationText.clock(time)) \(item.memo.text)").onoffText(16, .semibold, numeric: true)
                    } else {
                        Text(item.memo.text).onoffText(16)
                    }
                    Spacer()
                    if item.overlapsShift {
                        Text("근무와 겹침")
                            .onoffText(12, .bold)
                            .foregroundStyle(OnoffColor.conflictText)
                            .padding(.horizontal, 8)
                            .frame(height: 24)
                            .background(OnoffColor.conflictBackground, in: RoundedRectangle(cornerRadius: 7))
                    } else if item.memo.isPrivate {
                        HStack(spacing: 4) {
                            Image(systemName: "lock")
                                .font(.system(size: 10, weight: .bold))
                            Text("나만 보기").onoffText(12)
                        }
                        .foregroundStyle(OnoffColor.textSecondary)
                    }
                }
                .padding(.vertical, 10)
                .overlay(alignment: .bottom) {
                    if index < items.count - 1 { Rectangle().fill(OnoffColor.divider).frame(height: 1) }
                }
            }
        }
    }

    private func quickChange(_ detail: DayDetail) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("이 날 근무 바꾸기").onoffText(13, .bold).foregroundStyle(OnoffColor.textTertiary)
            HStack(spacing: 6) {
                ForEach(detail.quickOptions) { type in
                    let selected = detail.duty.state.shiftType?.id == type.id
                    // 바꾸기 · 변경 확인은 근무 입력 이슈에서 — 지금은 현재 근무만 표시
                    ShiftChip(code: type.code, colorKey: type.colorKey, height: 44, cornerRadius: OnoffRadius.button,
                              fontSize: type.code.count > 1 ? 13 : 15)
                        .overlay {
                            if selected {
                                RoundedRectangle(cornerRadius: OnoffRadius.button + 4)
                                    .strokeBorder(OnoffColor.ink, lineWidth: 2)
                                    .padding(-4)
                            }
                        }
                        .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
            // 「바꾸면 알람·일정·공유를 한 번에 확인해요」는 1.1 이후 — REQ-038
        }
    }
}
