// REQ-009 · REQ-010 · REQ-011 · UI-IOS-14b · UI-IOS-5a · UI-IOS-11c — 입력 화면: 위 줄 · 방법 바는 14b(취소 · 초안 N칸 · 되돌리기 · 적용),
// 키패드 방법은 5a(달력 · 상태 줄 · 키패드), 칠하기 방법은 11c(달력 끌기 · 안내 · 붓). 방법을 바꿔도 초안 · 커서 · 되돌리기는 그대로.
// 11c 단독 시안의 위 줄(「11월 · 칠하기」 · 「적용 5」)은 14b의 공통 위 줄로 대신한다.
// 패턴 제안 · 「키 편집」 · 「⋯」(5c)은 이번 범위 밖.
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
                        calendar
                        switch viewModel.method {
                        case .keypad: statusLine
                        case .paint: paintHint
                        }
                    }
                    .padding(.horizontal, OnoffSpace.xl)
                    .padding(.bottom, OnoffSpace.xl)
                }
                .scrollIndicators(.hidden)
                .safeAreaInset(edge: .bottom, spacing: 0) { bottomPanel }
                .disabled(viewModel.isSaving)
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
            .disabled(!viewModel.canUndo || viewModel.isSaving)
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

    // MARK: - 달력

    @ViewBuilder private var calendar: some View {
        switch viewModel.method {
        case .keypad:
            InputCalendar(cells: viewModel.cells, leadingBlanks: viewModel.leadingBlanks, cursorStyle: .typing,
                          onSelect: viewModel.select)
        case .paint:
            InputCalendar(cells: viewModel.cells, leadingBlanks: viewModel.leadingBlanks, cursorStyle: .resting,
                          stroke: PaintGesture(begin: viewModel.beginStroke, move: viewModel.moveStroke,
                                               end: viewModel.endStroke, cancel: viewModel.cancelStroke))
                .overlay(alignment: .topTrailing) {
                    if let summary = viewModel.strokeSummary { StrokePill(text: summary) }
                }
        }
    }

    // MARK: - 아래 판 (14b 방법 바 + 5a 키패드 · 11c 붓)

    private var bottomPanel: some View {
        VStack(spacing: OnoffSpace.l) {
            MethodBar(selection: $viewModel.method)
            switch viewModel.method {
            case .keypad: keypad
            case .paint: palette
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, OnoffSpace.l)
        .padding(.bottom, OnoffSpace.l)
        .background(
            UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24)
                .fill(OnoffColor.card)
                .shadow(color: OnoffShadow.sheetColor.opacity(0.45), radius: 10, y: -6)
                .ignoresSafeArea(edges: .bottom)
        )
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
    }

    // MARK: - 칠하기 (11c)

    private var paintHint: some View {
        Text("길게 누른 칸부터 끌면 지나간 날이 모두 칠해져요. 되돌아가면 지워지고, 손을 떼면 한 번에 적용돼요. 스크롤은 두 손가락으로 해요.")
            .onoffText(13)
            .lineSpacing(13 * 0.5)
            .foregroundStyle(OnoffColor.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, OnoffSpace.l)
            .padding(.horizontal, 14)
            .background(OnoffColor.card, in: RoundedRectangle(cornerRadius: 16))
    }

    private var palette: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 6), spacing: 6) {
            ForEach(viewModel.keypadTypes) { type in
                BrushKey(kind: .shift(type), isSelected: viewModel.brush == .shift(type.id)) {
                    viewModel.brush = .shift(type.id)
                }
            }
            BrushKey(kind: .eraser, isSelected: viewModel.brush == .eraser) { viewModel.brush = .eraser }
        }
        .padding(.bottom, OnoffSpace.xs)
    }

    /// 「누르면 14일에 넣고 15일로 넘어가요」 — 마지막 날은 넘어갈 날이 없다
    private var hint: String {
        let day = viewModel.cursorDay.day
        guard let next = viewModel.nextDay else { return "누르면 \(day)일에 넣어요" }
        return "누르면 \(day)일에 넣고 \(next.day)일로 넘어가요"
    }

    private func apply() {
        Task {
            if case let .close(saved) = await viewModel.apply() { onClose(saved) }
        }
    }
}

// MARK: - 달력 (5a)

/// 커서 모양 — 키패드는 먹 테두리(5a), 다른 방법일 때는 회색 테두리(14b 「키패드로 돌아가면 10일(회색 테두리)부터」)
private enum CursorStyle {
    case typing
    case resting
}

/// 칠하기 손짓 — 길게 누른 칸에서 시작해 끌고, 떼면 넣는다(11c)
private struct PaintGesture {
    let begin: (CalendarDay) -> Void
    let move: (CalendarDay?) -> Void
    let end: () -> Void
    let cancel: () -> Void
}

private struct InputCalendar: View {
    let cells: [ShiftInputViewModel.Cell]
    let leadingBlanks: Int
    let cursorStyle: CursorStyle
    var onSelect: ((CalendarDay) -> Void)?
    var stroke: PaintGesture?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: InputGridLayout.spacing), count: 7)
    @State private var gridWidth: CGFloat = 0
    @State private var dragging = false

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
            grid
        }
        .padding(.horizontal, OnoffSpace.m)
        .padding(.top, 10)
        .padding(.bottom, OnoffSpace.m)
        .background(OnoffColor.card, in: RoundedRectangle(cornerRadius: OnoffRadius.card))
    }

    @ViewBuilder private var grid: some View {
        let base = LazyVGrid(columns: columns, spacing: InputGridLayout.spacing) {
            ForEach(0..<leadingBlanks, id: \.self) { _ in Color.clear.frame(height: InputGridLayout.rowHeight) }
            ForEach(cells) { cell in
                if let onSelect {
                    Button { onSelect(cell.date) } label: { InputCell(cell: cell, cursorStyle: cursorStyle) }
                        .buttonStyle(.plain)
                } else {
                    InputCell(cell: cell, cursorStyle: cursorStyle)
                }
            }
        }
        .contentShape(Rectangle())
        .onGeometryChange(for: CGFloat.self, of: { $0.size.width }) { gridWidth = $0 }

        if let stroke {
            // 길게 눌러야 시작 — 짧게 쓸면 스크롤(두 손가락 스크롤도 그대로 된다)
            base.gesture(
                LongPressGesture(minimumDuration: 0.25)
                    .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .local))
                    .onChanged { value in
                        guard case let .second(true, drag?) = value else { return }
                        if !dragging {
                            dragging = true
                            if let anchor = day(at: drag.startLocation) { stroke.begin(anchor) }
                        }
                        stroke.move(day(at: drag.location))
                    }
                    .onEnded { _ in
                        if dragging { stroke.end() } else { stroke.cancel() }
                        dragging = false
                    }
            )
        } else {
            base
        }
    }

    private func day(at point: CGPoint) -> CalendarDay? {
        guard let index = InputGridLayout.dayIndex(at: point, width: gridWidth, leadingBlanks: leadingBlanks,
                                                   dayCount: cells.count) else { return nil }
        return cells[index].date
    }
}

/// 달력 칸 자리 계산 — 손가락 위치 → 몇 번째 날(0부터). 칸 밖 · 앞 빈칸이면 nil
enum InputGridLayout {
    static let rowHeight: CGFloat = 52
    static let spacing: CGFloat = 2

    static func dayIndex(at point: CGPoint, width: CGFloat, leadingBlanks: Int, dayCount: Int) -> Int? {
        guard width > 0, point.x >= 0, point.y >= 0, point.x < width else { return nil }
        let columnWidth = (width - spacing * 6) / 7
        let column = min(6, Int(point.x / (columnWidth + spacing)))
        let row = Int(point.y / (rowHeight + spacing))
        let index = row * 7 + column - leadingBlanks
        return (0..<dayCount).contains(index) ? index : nil
    }
}

private struct InputCell: View {
    let cell: ShiftInputViewModel.Cell
    let cursorStyle: CursorStyle

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
        .frame(maxWidth: .infinity, minHeight: InputGridLayout.rowHeight, maxHeight: InputGridLayout.rowHeight, alignment: .top)
        .background(cell.isCursor ? OnoffColor.background : .clear, in: RoundedRectangle(cornerRadius: OnoffRadius.cell))
        .overlay {
            if cell.isCursor {
                switch cursorStyle {
                case .typing:
                    RoundedRectangle(cornerRadius: OnoffRadius.cell).strokeBorder(OnoffColor.ink, lineWidth: 2.5)
                case .resting:
                    RoundedRectangle(cornerRadius: OnoffRadius.cell).strokeBorder(OnoffColor.handle, lineWidth: 1.5)
                }
            }
        }
        .opacity(cell.isUnderFinger ? 0.55 : 1)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(cell.date.day)일 \(cell.shift?.name ?? "미등록")")
    }

    @ViewBuilder private var chip: some View {
        if let shift = cell.shift {
            ShiftChip(code: shift.code, colorKey: shift.colorKey, height: 24, cornerRadius: 7, fontSize: 12)
                .overlay {
                    // 칠한 칸 — 먹 2px 테두리(11c · 14b)
                    if cell.isPainted { RoundedRectangle(cornerRadius: 7).strokeBorder(OnoffColor.ink, lineWidth: 2) }
                }
        } else if cell.isPainted {
            // 지우개로 끄는 중
            RoundedRectangle(cornerRadius: 7).strokeBorder(OnoffColor.ink, lineWidth: 2).frame(height: 24)
        } else if cell.isCursor && cursorStyle == .typing {
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

/// 11c 붓 — 근무 색 칸 또는 「지우개」. 고른 붓은 바깥 고리(2px 틈 + 먹 2px)
private struct BrushKey: View {
    enum Kind {
        case shift(ShiftType)
        case eraser
    }

    let kind: Kind
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            label
                .frame(maxWidth: .infinity, minHeight: 48)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .overlay {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 15).stroke(OnoffColor.ink, lineWidth: 2).padding(-3)
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder private var label: some View {
        switch kind {
        case let .shift(type):
            let colors = ShiftPalette.colors(for: type.colorKey)
            // 원본 11c: 한 글자 16 · 그 밖 13, 굵기 800
            Text(type.code)
                .onoffText(type.code.count == 1 ? 16 : 13, .heavy)
                .foregroundStyle(colors.foreground)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(colors.background, in: RoundedRectangle(cornerRadius: OnoffRadius.button))
                .accessibilityLabel("\(type.name) 붓")
        case .eraser:
            Text("지우개")
                .onoffText(13, .bold)
                .foregroundStyle(OnoffColor.textSecondary)
                .frame(maxWidth: .infinity, minHeight: 48)
                .overlay(RoundedRectangle(cornerRadius: OnoffRadius.button).strokeBorder(OnoffColor.hiddenOutline, lineWidth: 1.5))
        }
    }
}

/// 11c 끄는 동안 뜨는 수 「연차 × 5일 · 11/12–16」
private struct StrokePill: View {
    let text: String

    var body: some View {
        Text(text)
            .onoffText(13, .bold, numeric: true)
            .foregroundStyle(OnoffColor.onInk)
            .padding(.horizontal, OnoffSpace.l)
            .frame(height: 30)
            .background(OnoffColor.ink, in: Capsule())
            .shadow(color: OnoffShadow.sheetColor, radius: 8, y: 6)
            .padding(.trailing, OnoffSpace.l)
            .offset(y: -8)
            .allowsHitTesting(false)
    }
}

/// 14b 방법 바 — 회색 판 위 고른 칸만 흰 판
private struct MethodBar: View {
    @Binding var selection: ShiftInputMethod

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ShiftInputMethod.allCases, id: \.self) { method in
                let selected = method == selection
                Button { selection = method } label: {
                    Text(method.title)
                        .onoffText(13, selected ? .heavy : .semibold)
                        .foregroundStyle(selected ? OnoffColor.ink : OnoffColor.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 34)
                        .background {
                            if selected {
                                RoundedRectangle(cornerRadius: 9)
                                    .fill(OnoffColor.card)
                                    .shadow(color: OnoffShadow.sheetColor.opacity(0.67), radius: 1.5, y: 1)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(3)
        .background(OnoffColor.canvas, in: RoundedRectangle(cornerRadius: OnoffRadius.button))
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
