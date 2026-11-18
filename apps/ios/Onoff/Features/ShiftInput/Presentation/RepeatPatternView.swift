// REQ-013 · UI-IOS-22a · UI-IOS-22b — 순서 반복: 프리셋 칩 · 순서 칸 · 첫날 위치 · 미리보기(− N달 +) ·
// 휴가 뒤 순서 · 이미 넣은 근무 · 「N월까지 채우기 · N일」(바로 저장). 칸을 누르면 22b 칸 고치기 키패드.
// 「병동 근무표 오면 비교」 줄은 2.0(REQ-411)이라 없다.
import SwiftUI

struct RepeatPatternView: View {
    @State var viewModel: RepeatPatternViewModel
    /// 닫기 — 저장했으면 결과(되돌리기 안내에 씀)
    let onClose: (ApplyShiftInputUseCase.Result?) -> Void

    var body: some View {
        VStack(spacing: OnoffSpace.l) {
            topBar
            switch viewModel.state {
            case .loading:
                Spacer()
            case .failed:
                LoadFailedView { Task { await viewModel.load() } }
                Spacer()
            case .editing:
                ScrollView {
                    VStack(spacing: OnoffSpace.l) {
                        presets
                        patternCard
                        previewCard
                        optionsCard
                        if !viewModel.isEditing { fillButton }
                    }
                    .padding(.bottom, OnoffSpace.xl)
                }
                .scrollIndicators(.hidden)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if viewModel.isEditing { editPanel.padding(.horizontal, -OnoffSpace.xl) }
                }
                .disabled(viewModel.isSaving)
            }
        }
        .padding(.horizontal, OnoffSpace.xl)
        .padding(.top, OnoffSpace.l)
        .background(OnoffColor.background)
        .foregroundStyle(OnoffColor.ink)
        .task { await viewModel.load() }
        .alert("저장하지 못했어요", isPresented: $viewModel.saveFailed) {
            Button("확인", role: .cancel) {}
        }
    }

    // MARK: - 위 줄

    private var topBar: some View {
        ZStack {
            Text("순서 반복").onoffText(17, .bold)
            HStack {
                Button("취소") { onClose(nil) }
                    .onoffText(16)
                    .foregroundStyle(OnoffColor.textSecondary)
                Spacer()
            }
        }
        .buttonStyle(.plain)
        .frame(height: 36)
    }

    // MARK: - 프리셋 칩

    private var presets: some View {
        HStack(spacing: 6) {
            ForEach(RepeatPreset.allCases.filter(viewModel.isAvailable), id: \.self) { preset in
                let selected = preset == viewModel.preset
                Button { viewModel.choose(preset) } label: {
                    Text(preset.title)
                        .onoffText(13, selected ? .bold : .semibold)
                        .foregroundStyle(selected ? OnoffColor.onInk : OnoffColor.ink)
                        .padding(.horizontal, OnoffSpace.l)
                        .frame(height: 32)
                        .background(selected ? OnoffColor.ink : OnoffColor.card, in: Capsule())
                        .overlay { if !selected { Capsule().strokeBorder(OnoffColor.line, lineWidth: 1) } }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: - 순서 칸

    private var patternCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("순서 · \(viewModel.plan.pattern.count)일마다 반복").onoffText(13, .bold).foregroundStyle(OnoffColor.textTertiary)
                Spacer()
                if let index = viewModel.editingIndex {
                    Text("\(index + 1)번째 칸 고치는 중").onoffText(12, .bold)
                } else {
                    Text("칸을 누르면 고쳐요").onoffText(12).foregroundStyle(OnoffColor.textTertiary)
                }
            }

            HStack(alignment: .top, spacing: 4) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 0), spacing: 4), count: 8), spacing: 3) {
                    ForEach(viewModel.patternCells) { cell in
                        VStack(spacing: 3) {
                            Button { viewModel.edit(cell.index) } label: {
                                PatternKey(shift: cell.shift, isCurrent: viewModel.editingIndex == cell.index)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(cell.index + 1)번째 칸 \(cell.shift?.name ?? "모르는 근무")")
                            Text(cell.index == viewModel.startIndex ? "\(viewModel.firstDay.month)/\(viewModel.firstDay.day)" : " ")
                                .onoffText(11, .heavy, numeric: true)
                                .frame(height: 14)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                Button { viewModel.edit(viewModel.plan.pattern.count) } label: {
                    Text("+")
                        .onoffText(18)
                        .foregroundStyle(OnoffColor.textSecondary)
                        .frame(width: 30, height: 44)
                        .overlay {
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(OnoffColor.hiddenOutline, lineWidth: 1.5)
                            if viewModel.editingIndex == viewModel.plan.pattern.count { CurrentRing(cornerRadius: 10) }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("칸 추가")
            }

            VStack(alignment: .leading, spacing: OnoffSpace.xs) {
                HStack {
                    Text("\(viewModel.firstDay.month)월 \(viewModel.firstDay.day)일 근무").onoffText(14).foregroundStyle(OnoffColor.textSecondary)
                    Spacer()
                    startMenu
                }
                if viewModel.firstDayChanged {
                    Text("순서를 고쳐서 \(viewModel.firstDay.month)월 \(viewModel.firstDay.day)일 근무가 바뀌었어요 · 맞는지 봐 주세요")
                        .onoffText(12, .semibold)
                        .foregroundStyle(OnoffColor.caution)
                }
            }
            .padding(.top, 10)
            .overlay(alignment: .top) { Rectangle().fill(OnoffColor.divider).frame(height: 1) }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, OnoffSpace.xl)
        .background(OnoffColor.card, in: RoundedRectangle(cornerRadius: OnoffRadius.card))
    }

    /// 「D · 2번째 ›」 — 누르면 첫날이 몇 번째 칸인지 고른다
    private var startMenu: some View {
        Menu {
            ForEach(viewModel.patternCells) { cell in
                Button("\(cell.index + 1)번째 · \(cell.shift?.code ?? "?")") { viewModel.chooseStart(cell.index) }
            }
        } label: {
            Text("\(viewModel.firstDayShift?.code ?? "?") · \(viewModel.startIndex + 1)번째 ›")
                .onoffText(14, .bold)
                .foregroundStyle(OnoffColor.ink)
        }
    }

    // MARK: - 미리보기

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: OnoffSpace.m) {
            HStack {
                Text(previewTitle).onoffText(13, .bold).foregroundStyle(OnoffColor.textTertiary)
                Spacer()
                if viewModel.isEditing {
                    Text("고치는 대로 바로 바뀌어요").onoffText(12).foregroundStyle(OnoffColor.textTertiary)
                } else {
                    monthStepper
                }
            }
            ForEach(viewModel.previewMonths) { month in
                HStack(spacing: OnoffSpace.m) {
                    Text("\(month.month)월").onoffText(12, .bold).frame(width: 30, alignment: .leading)
                    PreviewBar(days: month.days)
                }
            }
            if let note = viewModel.keptLeaveNote {
                Text(note).onoffText(12).foregroundStyle(OnoffColor.textSecondary)
            }
        }
        .padding(.top, OnoffSpace.l)
        .padding(.bottom, 14)
        .padding(.horizontal, OnoffSpace.xl)
        .background(OnoffColor.card, in: RoundedRectangle(cornerRadius: OnoffRadius.card))
    }

    private var previewTitle: String {
        let first = viewModel.firstDay.month
        return viewModel.months == 1 ? "미리보기 · \(first)월" : "미리보기 · \(first)월–\(viewModel.lastMonth)월"
    }

    private var monthStepper: some View {
        HStack(spacing: OnoffSpace.m) {
            StepButton(symbol: "−", label: "한 달 줄이기", action: viewModel.removeMonth)
                .disabled(viewModel.months <= RepeatPatternViewModel.monthRange.lowerBound)
            Text("\(viewModel.months)달").onoffText(14, .heavy, numeric: true).frame(minWidth: 30)
            StepButton(symbol: "+", label: "한 달 늘리기", action: viewModel.addMonth)
                .disabled(viewModel.months >= RepeatPatternViewModel.monthRange.upperBound)
        }
    }

    // MARK: - 휴가 뒤 · 이미 넣은 근무

    private var optionsCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text("휴가 뒤 순서").onoffText(15, .semibold)
                Spacer()
                SmallSegment(options: [("이어서", DutyDraft.AfterLeave.continue), ("밀어서", .push)],
                             selection: viewModel.afterLeave, onSelect: viewModel.setAfterLeave)
            }
            .padding(.vertical, OnoffSpace.l)
            .overlay(alignment: .bottom) { Rectangle().fill(OnoffColor.divider).frame(height: 1) }

            HStack {
                VStack(alignment: .leading, spacing: OnoffSpace.xxs) {
                    Text("이미 넣은 근무").onoffText(15, .semibold)
                    Text("휴가는 언제나 그대로예요").onoffText(12).foregroundStyle(OnoffColor.textSecondary)
                }
                Spacer()
                SmallSegment(options: [("그대로", true), ("덮어쓰기", false)],
                             selection: viewModel.keepExisting, onSelect: viewModel.setKeepExisting)
            }
            .padding(.vertical, OnoffSpace.l)
        }
        .padding(.vertical, OnoffSpace.xs)
        .padding(.horizontal, OnoffSpace.xl)
        .background(OnoffColor.card, in: RoundedRectangle(cornerRadius: OnoffRadius.card))
    }

    // MARK: - 채우기

    private var fillButton: some View {
        VStack(spacing: 6) {
            Button {
                Task { if let result = await viewModel.fill() { onClose(result) } }
            } label: {
                Text("\(viewModel.lastMonth)월까지 채우기 · \(viewModel.fillCount)일")
                    .onoffText(16, .bold)
                    .foregroundStyle(OnoffColor.onInk)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(OnoffColor.ink, in: RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .disabled(viewModel.fillCount == 0 || viewModel.isSaving)
            .opacity(viewModel.fillCount == 0 ? 0.4 : 1)
            Text("바로 저장돼요 · 저장한 뒤 ‘되돌리기’ 한 번으로 모두 취소")
                .onoffText(12)
                .foregroundStyle(OnoffColor.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - 22b 칸 고치기 키패드

    private var editPanel: some View {
        let big = Array(viewModel.keypadTypes.prefix(4))
        let rest = Array(viewModel.keypadTypes.dropFirst(4))
        // 원본 22b 둘째 줄: 휴가 하나 · ⋯ · 지우기
        let leave = rest.first { $0.kind == .leave }
        let others = rest.filter { $0.id != leave?.id }
        return VStack(spacing: 10) {
            HStack {
                if let index = viewModel.editingIndex {
                    (Text("\(index + 1)번째 칸").foregroundStyle(OnoffColor.ink).bold()
                        + Text(" · 누르면 바꾸고 다음 칸으로"))
                        .onoffText(13)
                        .foregroundStyle(OnoffColor.textSecondary)
                }
                Spacer()
                Button("완료", action: viewModel.finishEditing).onoffText(15, .bold).buttonStyle(.plain)
            }
            .padding(.horizontal, OnoffSpace.xxs)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: OnoffSpace.m), count: 4), spacing: OnoffSpace.m) {
                ForEach(big) { type in
                    Button { viewModel.put(type) } label: {
                        EditKey(type: type, height: 58, cornerRadius: 14, fontSize: type.code.count == 1 ? 22 : 16,
                                isSelected: viewModel.editingShift == type.id)
                    }
                    .buttonStyle(.plain)
                }
                if let leave {
                    Button { viewModel.put(leave) } label: {
                        EditKey(type: leave, height: 46, cornerRadius: OnoffRadius.button, fontSize: 14,
                                isSelected: viewModel.editingShift == leave.id)
                    }
                    .buttonStyle(.plain)
                }
                if !others.isEmpty {
                    Menu {
                        ForEach(others) { type in Button(type.name) { viewModel.put(type) } }
                    } label: {
                        Text("⋯").onoffText(16, .heavy)
                            .frame(maxWidth: .infinity, minHeight: 46)
                            .background(OnoffColor.trackBackground, in: RoundedRectangle(cornerRadius: OnoffRadius.button))
                    }
                    .accessibilityLabel("다른 근무")
                }
                Button(action: viewModel.removeEditing) {
                    Text("지우기 · 이 칸 빼기").onoffText(14, .bold)
                        .frame(maxWidth: .infinity, minHeight: 46)
                        .background(OnoffColor.trackBackground, in: RoundedRectangle(cornerRadius: OnoffRadius.button))
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.canRemove)
                .opacity(viewModel.canRemove ? 1 : 0.4)
                .gridCellColumns(2)
            }
        }
        .foregroundStyle(OnoffColor.ink)
        .padding(.horizontal, 14)
        .padding(.top, OnoffSpace.l)
        .padding(.bottom, OnoffSpace.l)
        .background(
            UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24)
                .fill(OnoffColor.card)
                .shadow(color: OnoffShadow.sheetColor.opacity(0.55), radius: 12, y: -8)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

// MARK: - 부품

/// 지금 고치는 칸 · 고른 키 고리(2px 틈 + 먹 1.5px)
private struct CurrentRing: View {
    let cornerRadius: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius + 2.75)
            .stroke(OnoffColor.ink, lineWidth: 1.5)
            .padding(-2.75)
    }
}

private struct PatternKey: View {
    let shift: ShiftType?
    let isCurrent: Bool

    var body: some View {
        let colors = shift.map { ShiftPalette.colors(for: $0.colorKey) }
        Text(shift?.code ?? "?")
            .onoffText((shift?.code.count ?? 1) == 1 ? 16 : 12, .heavy)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .foregroundStyle(colors?.foreground ?? OnoffColor.textSecondary)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(colors?.background ?? OnoffColor.unregisteredFill, in: RoundedRectangle(cornerRadius: 10))
            .overlay { if isCurrent { CurrentRing(cornerRadius: 10) } }
            .contentShape(Rectangle())
    }
}

private struct EditKey: View {
    let type: ShiftType
    let height: CGFloat
    let cornerRadius: CGFloat
    let fontSize: CGFloat
    let isSelected: Bool

    var body: some View {
        let colors = ShiftPalette.colors(for: type.colorKey)
        Text(type.code)
            .onoffText(fontSize, .heavy)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .foregroundStyle(colors.foreground)
            .frame(maxWidth: .infinity, minHeight: height)
            .background(colors.background, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay { if isSelected { CurrentRing(cornerRadius: cornerRadius) } }
            .contentShape(Rectangle())
            .accessibilityLabel(type.name)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// 미리보기 한 달 띠 — 날마다 근무 색, 미등록은 빗금 바탕색
private struct PreviewBar: View {
    let days: [ShiftType?]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, shift in
                Rectangle().fill(shift.map { ShiftPalette.colors(for: $0.colorKey).background } ?? OnoffColor.unregisteredFill)
            }
        }
        .frame(height: 18)
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .accessibilityHidden(true)
    }
}

private struct StepButton: View {
    let symbol: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(symbol).onoffText(18, .bold)
                .frame(width: 30, height: 30)
                .background(OnoffColor.trackBackground, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

/// 22a 작은 두 칸 고르기(휴가 뒤 순서 · 이미 넣은 근무)
private struct SmallSegment<Value: Equatable>: View {
    let options: [(String, Value)]
    let selection: Value
    let onSelect: (Value) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(options.enumerated()), id: \.offset) { _, option in
                let selected = option.1 == selection
                Button { onSelect(option.1) } label: {
                    Text(option.0)
                        .onoffText(13, selected ? .bold : .semibold)
                        .foregroundStyle(selected ? OnoffColor.ink : OnoffColor.textSecondary)
                        .padding(.horizontal, 10)
                        .frame(height: 28)
                        .background(selected ? OnoffColor.card : .clear, in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(3)
        .background(OnoffColor.canvas, in: RoundedRectangle(cornerRadius: 10))
    }
}
