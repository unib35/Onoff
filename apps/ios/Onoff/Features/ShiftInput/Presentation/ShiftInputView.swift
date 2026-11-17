// REQ-009 · REQ-010 · UI-IOS-14b · UI-IOS-5a — 입력 화면: 위 줄은 14b(취소 · 초안 N칸 · 되돌리기 · 적용),
// 달력 · 상태 줄 · 키패드는 5a. 1.0 방법은 키패드뿐이라 방법 바는 칠하기(11c)가 들어올 때 보인다.
// 패턴 제안 · 「키 편집」(5c)은 이번 범위 밖.
import SwiftUI

struct ShiftInputView: View {
    @State var viewModel: ShiftInputViewModel
    /// 닫기 — 저장했으면 true
    let onClose: (Bool) -> Void
    @State private var confirmingCancel = false

    var body: some View {
        VStack(spacing: 10) {
            topBar
            switch viewModel.state {
            case .loading:
                Spacer()
            case .failed:
                LoadFailedView { Task { await viewModel.load() } }
                    .padding(.horizontal, OnoffSpace.xl)
                Spacer()
            case .editing:
                ScrollView {
                    VStack(spacing: 10) {
                        InputCalendar(cells: viewModel.cells, leadingBlanks: viewModel.leadingBlanks, onSelect: viewModel.select)
                        statusLine
                    }
                    .padding(.horizontal, OnoffSpace.xl)
                    .padding(.bottom, OnoffSpace.xl)
                }
                .scrollIndicators(.hidden)
                .safeAreaInset(edge: .bottom, spacing: 0) { keypad }
            }
        }
        .padding(.top, OnoffSpace.l)
        .background(OnoffColor.background)
        .foregroundStyle(OnoffColor.ink)
        .task { await viewModel.load() }
        // 문구: Android A1h 「적용 안 한 변경 3개」 · 「버리기」 · 「적용」
        .confirmationDialog("적용 안 한 변경 \(viewModel.changedCount)개", isPresented: $confirmingCancel, titleVisibility: .visible) {
            Button("적용") { apply() }
            Button("버리기", role: .destructive) { onClose(false) }
        }
        .alert("저장하지 못했어요", isPresented: $viewModel.saveFailed) {
            Button("확인", role: .cancel) {}
        }
    }

    // MARK: - 위 줄 (14b)

    private var topBar: some View {
        HStack(spacing: OnoffSpace.l) {
            Button("취소") {
                if viewModel.changedCount > 0 { confirmingCancel = true } else { onClose(false) }
            }
            .onoffText(16)
            .foregroundStyle(OnoffColor.textSecondary)

            Spacer()
            Text("\(viewModel.month)월 · 초안 \(viewModel.changedCount)칸").onoffText(17, .bold, numeric: true)
            Spacer()

            Button(action: viewModel.undo) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 32, height: 32)
                    .background(OnoffColor.card, in: Circle())
            }
            .disabled(!viewModel.canUndo)
            .opacity(viewModel.canUndo ? 1 : 0.4)
            .accessibilityLabel("되돌리기")

            Button("적용") { apply() }
                .onoffText(16, .bold)
                .disabled(viewModel.state != .editing || viewModel.isSaving)
        }
        .buttonStyle(.plain)
        .frame(height: 36)
        .padding(.horizontal, OnoffSpace.xl)
    }

    // MARK: - 상태 줄 (5a)

    private var statusLine: some View {
        HStack(spacing: 0) {
            Text("\(ShiftFormat.dayWithWeekday(viewModel.cursorDay)) 입력 중 ").onoffText(15, .bold)
            Text("· \(viewModel.filledCount)/\(viewModel.dayCount)").onoffText(15, numeric: true)
                .foregroundStyle(OnoffColor.textSecondary)
            Spacer()
        }
        .padding(.horizontal, OnoffSpace.xs)
    }

    // MARK: - 키패드 (5a)

    private var keypad: some View {
        VStack(spacing: OnoffSpace.m) {
            Text(hint).onoffText(12).foregroundStyle(OnoffColor.textSecondary)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 6) {
                ForEach(viewModel.keypadTypes) { type in
                    Button { viewModel.enter(type) } label: { KeypadKey(type: type) }
                        .buttonStyle(.plain)
                }
            }
            HStack(spacing: 6) {
                AuxKey(title: "이전", leading: "chevron.left", action: viewModel.previousDay)
                AuxKey(title: "건너뛰기", trailing: "chevron.right", action: viewModel.skipDay)
                AuxKey(title: "지우기", leading: "delete.left", action: viewModel.backspace)
            }
        }
        .padding(.horizontal, OnoffSpace.l)
        .padding(.top, 10)
        .padding(.bottom, OnoffSpace.l)
        .background(
            UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24)
                .fill(OnoffColor.card)
                .shadow(color: OnoffShadow.sheetColor.opacity(0.45), radius: 10, y: -6)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    /// 「누르면 14일에 넣고 15일로 넘어가요」 — 마지막 날은 넘어갈 날이 없다
    private var hint: String {
        let day = viewModel.cursorDay
        if viewModel.isCursorOnLastDay { return "누르면 \(day.day)일에 넣어요" }
        return "누르면 \(day.day)일에 넣고 \(SeoulCalendar.adding(days: 1, to: day).day)일로 넘어가요"
    }

    private func apply() {
        Task {
            let saved = viewModel.changedCount > 0
            if await viewModel.apply() { onClose(saved) }
        }
    }
}

// MARK: - 달력 (5a)

private struct InputCalendar: View {
    let cells: [ShiftInputViewModel.Cell]
    let leadingBlanks: Int
    let onSelect: (CalendarDay) -> Void

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
                ForEach(0..<leadingBlanks, id: \.self) { _ in Color.clear.frame(height: 52) }
                ForEach(cells) { cell in
                    Button { onSelect(cell.date) } label: { InputCell(cell: cell) }
                        .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, OnoffSpace.m)
        .padding(.top, 10)
        .padding(.bottom, OnoffSpace.m)
        .background(OnoffColor.card, in: RoundedRectangle(cornerRadius: OnoffRadius.card))
    }
}

private struct InputCell: View {
    let cell: ShiftInputViewModel.Cell

    private var isSunday: Bool { SeoulCalendar.weekdayIndex(cell.date) == 0 }

    var body: some View {
        VStack(spacing: OnoffSpace.xs) {
            Text("\(cell.date.day)")
                .onoffText(13, cell.isCursor ? .heavy : .semibold, numeric: true)
                .foregroundStyle(cell.isCursor ? OnoffColor.ink : (isSunday ? OnoffColor.sunday : OnoffColor.textSecondary))
            chip
        }
        .padding(.top, 5)
        .padding(.horizontal, OnoffSpace.xxs)
        .frame(maxWidth: .infinity, minHeight: 52, maxHeight: 52, alignment: .top)
        .background(cell.isCursor ? OnoffColor.background : .clear, in: RoundedRectangle(cornerRadius: OnoffRadius.cell))
        .overlay {
            if cell.isCursor {
                RoundedRectangle(cornerRadius: OnoffRadius.cell).strokeBorder(OnoffColor.ink, lineWidth: 2.5)
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(cell.date.day)일 \(cell.shift?.name ?? "미등록")")
    }

    @ViewBuilder private var chip: some View {
        if let shift = cell.shift {
            ShiftChip(code: shift.code, colorKey: shift.colorKey, height: 24, cornerRadius: 7, fontSize: 12)
        } else if cell.isCursor {
            RoundedRectangle(cornerRadius: 7)
                .strokeBorder(OnoffColor.ink, style: StrokeStyle(lineWidth: 1.5, dash: [3, 2]))
                .frame(height: 24)
        } else {
            // 입력 중 빈칸은 원본 5a대로 테두리만(빗금 아님)
            RoundedRectangle(cornerRadius: 7).strokeBorder(OnoffColor.line, lineWidth: 1).frame(height: 24)
        }
    }
}

// MARK: - 키

private struct KeypadKey: View {
    let type: ShiftType

    /// 원본 5a: 한 글자 18 · OFF 16 · 한글 두 글자 15
    private var codeSize: CGFloat {
        if type.code.count == 1 { return 18 }
        return type.code.allSatisfy(\.isASCII) ? 16 : 15
    }

    var body: some View {
        let colors = ShiftPalette.colors(for: type.colorKey)
        VStack(spacing: 1) {
            Text(type.code).onoffText(codeSize, .bold)
            Text(ShiftFormat.keypadCaption(type)).onoffText(12, .semibold, numeric: true)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .foregroundStyle(colors.foreground)
        .frame(maxWidth: .infinity, minHeight: 52)
        .background(colors.background, in: RoundedRectangle(cornerRadius: 13))
        .contentShape(Rectangle())
        .accessibilityLabel("\(type.name) 넣기")
    }
}

private struct AuxKey: View {
    let title: String
    var leading: String?
    var trailing: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: OnoffSpace.xs) {
                if let leading { Image(systemName: leading).font(.system(size: 12, weight: .bold)) }
                Text(title).onoffText(13, .bold)
                if let trailing { Image(systemName: trailing).font(.system(size: 12, weight: .bold)) }
            }
            .frame(maxWidth: .infinity, minHeight: 42)
            .background(OnoffColor.background, in: RoundedRectangle(cornerRadius: OnoffRadius.button))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
