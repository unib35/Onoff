// REQ-014 · UI-IOS-22c · UI-IOS-22d — 사진 보며 입력. 22c 처음 맞추기(1일 칸 · 마지막 날 칸 누르기) → 22d 입력 중(지금 칸 테두리 · 키패드).
// 사진은 시스템 선택기(PhotosPicker)로 받아 사진 권한을 묻지 않고, 이 화면 메모리에만 둔다.
import PhotosUI
import SwiftUI

struct PhotoInputView: View {
    @State var viewModel: PhotoInputViewModel
    /// 닫기 — 저장했으면 true
    let onClose: (Bool) -> Void
    /// 근무를 불러온 뒤 한 번(개발용 표본)
    var onLoaded: ((PhotoInputViewModel) -> Void)?
    @State private var pickerShown = false
    @State private var pickedItem: PhotosPickerItem?
    @State private var confirmingCancel = false
    /// 고른 사진을 읽는 중
    @State private var loadingPhoto = false

    private var input: ShiftInputViewModel { viewModel.input }

    var body: some View {
        VStack(spacing: 10) {
            topBar
            switch (input.state, viewModel.phase) {
            case (.failed, _):
                LoadFailedView { Task { await input.load() } }
                    .padding(.horizontal, OnoffSpace.xl)
                Spacer()
            case (.loading, _), (_, .picking):
                Spacer()
                if loadingPhoto { ProgressView().frame(maxWidth: .infinity) }
                Spacer()
            case (.editing, .aligning):
                AlignStep(viewModel: viewModel)
            case (.editing, .entering):
                EnterStep(viewModel: viewModel)
            }
        }
        .padding(.top, OnoffSpace.l)
        .background(OnoffColor.background)
        .foregroundStyle(OnoffColor.ink)
        .task {
            if viewModel.photo == nil { pickerShown = true }
            await input.load()
            onLoaded?(viewModel)
        }
        .photosPicker(isPresented: $pickerShown, selection: $pickedItem, matching: .images, preferredItemEncoding: .current)
        .onChange(of: pickerShown) { _, shown in
            // 처음 사진을 고르지 않고 닫으면 화면도 닫는다 — 고른 사진이 닫힘보다 늦게 올 수 있어 한 박자 기다린다
            guard !shown else { return }
            Task {
                try? await Task.sleep(for: .milliseconds(400))
                if pickedItem == nil, !loadingPhoto, viewModel.photo == nil { onClose(false) }
            }
        }
        .onChange(of: pickedItem) { _, item in
            guard let item else { return }
            loadingPhoto = true
            Task { await load(item) }
        }
        // 문구: 14b와 같다(Android A1h)
        .confirmationDialog("적용 안 한 변경 \(input.changedCount)개", isPresented: $confirmingCancel, titleVisibility: .visible) {
            Button("적용") { apply() }
            Button("버리기", role: .destructive) { onClose(false) }
        }
        .alert("저장하지 못했어요", isPresented: Binding(get: { input.saveFailed }, set: { input.saveFailed = $0 })) {
            Button("확인", role: .cancel) {}
        }
        // 원본에 없는 문구 — 보류(진행 로그)
        .alert("사진을 열지 못했어요", isPresented: $viewModel.photoFailed) {
            Button("확인", role: .cancel) { if viewModel.photo == nil { onClose(false) } }
        }
    }

    // MARK: - 위 줄

    private var topBar: some View {
        ZStack {
            Text("사진 보며 입력").onoffText(17, .bold)
            HStack {
                Button("취소") {
                    if input.changedCount > 0 { confirmingCancel = true } else { onClose(false) }
                }
                .onoffText(16)
                .foregroundStyle(OnoffColor.textSecondary)
                .disabled(input.isSaving)
                Spacer()
                switch viewModel.phase {
                case .aligning:
                    Button("사진 바꾸기") { pickerShown = true }.onoffText(15, .semibold)
                case .entering:
                    Button("적용 \(input.changedCount)") { apply() }
                        .onoffText(16, .bold)
                        .monospacedDigit()
                        .disabled(input.isSaving)
                case .picking:
                    EmptyView()
                }
            }
        }
        .buttonStyle(.plain)
        .frame(height: 36)
        .padding(.horizontal, OnoffSpace.xl)
    }

    private func load(_ item: PhotosPickerItem) async {
        defer {
            pickedItem = nil
            loadingPhoto = false
        }
        guard let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) else {
            viewModel.photoFailed = true
            return
        }
        // 큰 사진은 줄여서 메모리에만 — 칸을 보기에는 긴 변 3000px이면 충분하다(줄이기는 메인 밖에서)
        let thumbnail = await image.byPreparingThumbnail(ofSize: Self.fittedSize(image.size, longSide: 3000))
        viewModel.setPhoto(thumbnail ?? image)
    }

    static func fittedSize(_ size: CGSize, longSide: CGFloat) -> CGSize {
        let scale = min(1, longSide / max(size.width, size.height, 1))
        return CGSize(width: (size.width * scale).rounded(), height: (size.height * scale).rounded())
    }

    private func apply() {
        Task {
            if case let .close(saved) = await input.apply() { onClose(saved) }
        }
    }
}

// MARK: - 22c 처음 맞추기

private struct AlignStep: View {
    let viewModel: PhotoInputViewModel

    private var lastDay: Int { viewModel.lastDayNumber }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    StepChip(title: "1일 칸", done: viewModel.first != nil)
                    StepChip(title: "\(lastDay)일 칸", done: viewModel.last != nil)
                }
                Text(title).onoffText(20, .heavy)
                Text(detail)
                    .onoffText(13)
                    .lineSpacing(13 * 0.5)
                    .foregroundStyle(OnoffColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 20)
            .padding(.top, OnoffSpace.xxs)

            if let photo = viewModel.photo {
                AlignCanvas(photo: photo, viewModel: viewModel)
                    .frame(height: 372)
                    .padding(.horizontal, OnoffSpace.l)
            }

            Text("사진은 이 기기에만 둬요 · 백업하거나 올리지 않아요")
                .onoffText(12)
                .foregroundStyle(OnoffColor.textSecondary)
                .padding(.horizontal, 20)

            Spacer(minLength: 0)

            VStack(spacing: OnoffSpace.xxs) {
                Button(action: viewModel.startEntering) {
                    Text("이대로 입력 시작 · \(viewModel.startDay.month)월 \(viewModel.startDay.day)일부터")
                        .onoffText(16, .bold)
                        .foregroundStyle(OnoffColor.onInk)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(OnoffColor.ink, in: RoundedRectangle(cornerRadius: 16))
                }
                .disabled(!viewModel.isAligned)
                .opacity(viewModel.isAligned ? 1 : 0.4)
                Button(action: viewModel.resetAlignment) {
                    Text("처음부터 다시 맞추기")
                        .onoffText(14, .semibold)
                        .foregroundStyle(OnoffColor.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 40)
                }
                .disabled(viewModel.first == nil)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, OnoffSpace.xl)
            .padding(.bottom, OnoffSpace.m)
        }
    }

    // 원본 22c는 두 칸을 다 누른 뒤 모습만 있다 — 누르기 전 문구는 보류(진행 로그)
    private var title: String {
        if viewModel.first == nil { return "내 줄의 1일 칸을 눌러요" }
        if viewModel.last == nil { return "이번엔 \(lastDay)일 칸을 눌러요" }
        return "두 칸 사이를 \(lastDay)일로 나눴어요"
    }

    private var detail: String {
        if viewModel.first == nil { return "근무표에서 내 이름 줄을 찾아 1일 칸을 한 번 눌러요. 두 손가락으로 벌리면 커져요." }
        if viewModel.last == nil { return "같은 줄의 \(lastDay)일 칸을 누르면 그 사이를 날짜 수대로 똑같이 나눠요." }
        return "내 줄의 1일 칸과 \(lastDay)일 칸을 눌러서 맞췄어요. 칸이 어긋나 보이면 표시를 끌어서 옮겨요."
    }
}

/// 「✓ 1일 칸」
private struct StepChip: View {
    let title: String
    let done: Bool

    var body: some View {
        HStack(spacing: OnoffSpace.xs) {
            if done {
                Image(systemName: "checkmark").font(.system(size: 10, weight: .heavy)).foregroundStyle(OnoffColor.positive)
            }
            Text(title).onoffText(12, .bold)
        }
        .foregroundStyle(done ? OnoffColor.ink : OnoffColor.textSecondary)
        .padding(.horizontal, 10)
        .frame(height: 26)
        .background(OnoffColor.card, in: Capsule())
        .overlay(Capsule().strokeBorder(OnoffColor.line, lineWidth: 1))
        .accessibilityAddTraits(done ? .isSelected : [])
    }
}

/// 22c 사진 — 다 보이게 맞추고, 두 손가락 확대 · 한 손가락 끌기, 누르면 칸 표시
private struct AlignCanvas: View {
    let photo: UIImage
    let viewModel: PhotoInputViewModel

    @State private var scale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @GestureState private var pinch: CGFloat = 1
    @GestureState private var pan: CGSize = .zero
    /// 끄는 중인 표시의 처음 자리 — 손짓이 끊겨도 저절로 비워진다
    @GestureState private var grabbed: [PhotoInputViewModel.Marker: PhotoPoint] = [:]

    private static let space = "align-canvas"

    var body: some View {
        GeometryReader { proxy in
            let viewport = PhotoViewport.fit(container: proxy.size, image: photo.size,
                                             scale: scale * pinch,
                                             offset: CGSize(width: offset.width + pan.width, height: offset.height + pan.height))
            let cell = viewModel.alignedGrid.map { viewport.cellSize(step: $0.step) }
            ZStack(alignment: .topLeading) {
                OnoffColor.photoBackdrop
                Image(uiImage: photo)
                    .resizable()
                    .frame(width: viewport.size.width, height: viewport.size.height)
                    // offset이 아니라 position — 키운 사진이 틀 크기를 늘리지 않게
                    .position(x: viewport.origin.x + viewport.size.width / 2, y: viewport.origin.y + viewport.size.height / 2)
                    .accessibilityHidden(true)

                if let grid = viewModel.alignedGrid, let cell {
                    RowBand(from: viewport.viewPoint(grid.first), to: viewport.viewPoint(grid.last), cell: cell,
                            left: viewport.origin.x)
                }
                if let first = viewModel.first {
                    marker(.first, label: "1일", at: viewport.viewPoint(first), cell: cell, viewport: viewport)
                }
                if let last = viewModel.last {
                    marker(.last, label: "\(viewModel.lastDayNumber)일", at: viewport.viewPoint(last), cell: cell, viewport: viewport)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .contentShape(Rectangle())
            .coordinateSpace(.named(Self.space))
            // 끌기 · 확대가 먼저, 움직이지 않고 떼면 누르기(칸 표시)
            .gesture(
                SimultaneousGesture(
                    MagnifyGesture()
                        .updating($pinch) { value, state, _ in state = value.magnification }
                        .onEnded { value in scale = min(max(scale * value.magnification, 1), 8) },
                    DragGesture(minimumDistance: 8)
                        .updating($pan) { value, state, _ in state = value.translation }
                        .onEnded { value in
                            offset.width += value.translation.width
                            offset.height += value.translation.height
                        }
                )
                .exclusively(before: SpatialTapGesture(coordinateSpace: .named(Self.space)).onEnded { tap in
                    viewModel.place(viewport.photoPoint(tap.location))
                })
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(alignment: .bottomLeading) {
            PhotoPill(text: "두 손가락으로 벌리면 커져요").padding(10)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("근무표 사진")
    }

    /// 칸 테두리 + 위 막대 + 「1일」 알약. 끌면 옮겨진다.
    private func marker(_ which: PhotoInputViewModel.Marker, label: String, at point: CGPoint, cell: CGSize?,
                        viewport: PhotoViewport) -> some View {
        let size = cell ?? CGSize(width: 12, height: 18)
        return VStack(spacing: 0) {
            // 잡는 곳은 알약 · 막대만 — 칸 테두리 위에서는 사진 끌기 · 확대가 된다
            VStack(spacing: 0) {
                Text(label)
                    .onoffText(10, .heavy)
                    .foregroundStyle(OnoffColor.onInk)
                    .padding(.horizontal, 6)
                    .frame(height: 18)
                    .background(OnoffColor.ink, in: Capsule())
                    .fixedSize()
                Rectangle().fill(OnoffColor.ink).frame(width: 2, height: 10)
            }
            .contentShape(Rectangle().inset(by: -6))
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .named(Self.space))
                    .updating($grabbed) { drag, state, _ in
                        let origin = state[which] ?? viewport.photoPoint(point)
                        state[which] = origin
                        viewModel.move(which, to: origin + viewport.photoDelta(drag.translation))
                    }
            )
            RoundedRectangle(cornerRadius: 2)
                .stroke(OnoffColor.ink, lineWidth: 2)
                .frame(width: max(size.width, 8), height: max(size.height, 12))
                .allowsHitTesting(false)
        }
        // 칸 가운데가 point에 오게 — 알약 · 막대 높이(28)만큼 위로
        .position(x: point.x, y: point.y - 14)
        .accessibilityElement()
        .accessibilityLabel("\(label) 칸 표시")
    }
}

/// 내 줄 노란 띠 — 사진 왼쪽(이름 칸)부터 마지막 날 칸 끝까지
private struct RowBand: View {
    let from: CGPoint
    let to: CGPoint
    let cell: CGSize
    let left: CGFloat

    var body: some View {
        let start = min(left, from.x - cell.width / 2)
        let end = to.x + cell.width / 2
        let angle = atan2(to.y - from.y, to.x - from.x)
        Rectangle()
            .fill(OnoffColor.photoRow)
            .overlay(Rectangle().stroke(OnoffColor.ink, lineWidth: 1.5))
            .frame(width: max(end - start, 0), height: cell.height)
            .rotationEffect(.radians(angle), anchor: UnitPoint(x: (from.x - start) / max(end - start, 1), y: 0.5))
            .position(x: (start + end) / 2, y: from.y)
            .allowsHitTesting(false)
    }
}

private struct PhotoPill: View {
    let text: String

    var body: some View {
        Text(text)
            .onoffText(12, .bold)
            .foregroundStyle(OnoffColor.onInk)
            .padding(.horizontal, 10)
            .frame(height: 26)
            .background(OnoffColor.photoPill, in: Capsule())
            .allowsHitTesting(false)
    }
}

// MARK: - 22d 입력 중

private struct EnterStep: View {
    let viewModel: PhotoInputViewModel

    private var input: ShiftInputViewModel { viewModel.input }

    var body: some View {
        VStack(spacing: 10) {
            if let photo = viewModel.photo {
                FocusCanvas(photo: photo, viewModel: viewModel)
                    .frame(height: 300)
                    .padding(.horizontal, OnoffSpace.l)
            }
            WeekStrip(cells: viewModel.weekCells)
                .padding(.horizontal, OnoffSpace.l)
            HStack(spacing: 0) {
                Text(ShiftFormat.dayWithWeekday(input.cursorDay)).onoffText(13, .bold).foregroundStyle(OnoffColor.ink)
                Text(" 입력 중 · \(input.filledCount)/\(input.dayCount)").onoffText(13, numeric: true)
                    .foregroundStyle(OnoffColor.textSecondary)
                Spacer()
            }
            .padding(.horizontal, 18)
            Spacer(minLength: 0)
            keypad
        }
        .disabled(input.isSaving)
    }

    /// 22d 키 — D · E · N · OFF 큰 키, 둘째 줄 휴가 · 다른 근무 · 되돌리기 · 건너뛰기
    private var keypad: some View {
        let big = Array(input.keypadTypes.prefix(4))
        let rest = Array(input.keypadTypes.dropFirst(4))
        let leave = rest.first { $0.kind == .leave }
        let others = rest.filter { $0.id != leave?.id }
        return Grid(horizontalSpacing: OnoffSpace.m, verticalSpacing: OnoffSpace.m) {
            GridRow {
                ForEach(big) { type in
                    Button { input.enter(type) } label: {
                        EditKey(type: type, height: 58, cornerRadius: 14, fontSize: type.code.count == 1 ? 22 : 16, isSelected: false)
                    }
                    .buttonStyle(.plain)
                }
            }
            GridRow {
                if let leave {
                    Button { input.enter(leave) } label: {
                        EditKey(type: leave, height: 46, cornerRadius: OnoffRadius.button, fontSize: 14, isSelected: false)
                    }
                    .buttonStyle(.plain)
                } else {
                    Color.clear.frame(height: 46)
                }
                // 원본은 이 자리에 M 하나 — 근무가 더 있으면 「⋯」로 묶는다(보류)
                if others.count == 1, let only = others.first {
                    Button { input.enter(only) } label: {
                        EditKey(type: only, height: 46, cornerRadius: OnoffRadius.button, fontSize: 14, isSelected: false)
                    }
                    .buttonStyle(.plain)
                } else {
                    Menu {
                        ForEach(others) { type in Button(type.name) { input.enter(type) } }
                    } label: {
                        Text("⋯").onoffText(16, .heavy)
                            .frame(maxWidth: .infinity, minHeight: 46)
                            .background(OnoffColor.trackBackground, in: RoundedRectangle(cornerRadius: OnoffRadius.button))
                    }
                    .disabled(others.isEmpty)
                    .accessibilityLabel("다른 근무")
                }
                AuxButton(title: "되돌리기", enabled: input.canUndo, action: input.undo)
                AuxButton(title: "건너뛰기", enabled: !input.isCursorOnLastDay, action: input.skipDay)
            }
        }
        .foregroundStyle(OnoffColor.ink)
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .padding(.bottom, OnoffSpace.l)
        .background(
            UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24)
                .fill(OnoffColor.card)
                .shadow(color: OnoffShadow.sheetColor.opacity(0.55), radius: 12, y: -8)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

private struct AuxButton: View {
    let title: String
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title).onoffText(14, .bold)
                .frame(maxWidth: .infinity, minHeight: 46)
                .background(OnoffColor.trackBackground, in: RoundedRectangle(cornerRadius: OnoffRadius.button))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.4)
    }
}

/// 22d 사진 — 칸 하나를 34pt로 키워 지금 칸을 테두리 자리에 둔다. 날이 바뀌면 사진을 밀어 주고, 끌면 다시 맞춘다.
private struct FocusCanvas: View {
    let photo: UIImage
    let viewModel: PhotoInputViewModel
    @GestureState private var drag: CGSize = .zero

    /// 원본 22d: 칸 34 × 28, 지금 칸 가운데는 틀의 가로 56.3% · 세로 74.7%(위에 날짜 줄이 보이게)
    private static let cellWidth: CGFloat = 34
    private static let anchor = UnitPoint(x: 0.563, y: 0.747)

    var body: some View {
        GeometryReader { proxy in
            let anchor = CGPoint(x: proxy.size.width * Self.anchor.x, y: proxy.size.height * Self.anchor.y)
            let center = viewModel.currentCenter ?? PhotoPoint(x: 0.5, y: 0.5)
            let step = viewModel.grid?.step ?? PhotoPoint(x: 0.03, y: 0)
            let viewport = PhotoViewport.focus(on: center, step: step, image: photo.size, cellWidth: Self.cellWidth, anchor: anchor)
            let cell = viewport.cellSize(step: step)
            ZStack(alignment: .topLeading) {
                OnoffColor.photoPaper
                Image(uiImage: photo)
                    .resizable()
                    .frame(width: viewport.size.width, height: viewport.size.height)
                    .position(x: viewport.origin.x + viewport.size.width / 2 + drag.width,
                              y: viewport.origin.y + viewport.size.height / 2 + drag.height)
                    .animation(.easeOut(duration: 0.22), value: viewModel.input.cursorDay)
                    .accessibilityHidden(true)

                // 지금 날짜 세로 띠 · 내 줄 띠 · 지금 칸 테두리 · 위 날짜
                Rectangle().fill(OnoffColor.photoColumn)
                    .frame(width: cell.width, height: proxy.size.height)
                    .position(x: anchor.x, y: proxy.size.height / 2)
                Rectangle().fill(OnoffColor.photoRow)
                    .frame(width: proxy.size.width, height: cell.height)
                    .position(x: proxy.size.width / 2, y: anchor.y)
                RoundedRectangle(cornerRadius: 3)
                    .stroke(OnoffColor.ink, lineWidth: 2.5)
                    .frame(width: cell.width, height: cell.height)
                    .position(anchor)
                Text("\(viewModel.input.cursorDay.day)")
                    .onoffText(13, .bold, numeric: true)
                    .foregroundStyle(OnoffColor.onInk)
                    .frame(width: 30, height: 24)
                    .background(OnoffColor.ink, in: RoundedRectangle(cornerRadius: 5))
                    .position(x: anchor.x, y: 28)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 4)
                    .updating($drag) { value, state, _ in state = value.translation }
                    .onEnded { value in
                        // 사진을 t만큼 끌어 맞췄다 → 지금 칸은 원래 자리에서 -t에 있었다
                        let delta = viewport.photoDelta(value.translation)
                        viewModel.realign(by: PhotoPoint(x: -delta.x, y: -delta.y))
                    }
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(alignment: .bottom) {
            HStack {
                PhotoPill(text: "어긋나면 사진을 끌어 맞춰요")
                Spacer()
                Button(action: viewModel.backToAligning) {
                    Text("다시 맞추기")
                        .onoffText(12, .bold)
                        .padding(.horizontal, 10)
                        .frame(height: 26)
                        .background(OnoffColor.photoButton, in: Capsule())
                        .overlay(Capsule().strokeBorder(OnoffColor.line, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            .padding(10)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("근무표 사진 확대 · \(viewModel.input.cursorDay.day)일 칸")
    }
}

/// 22d 7일 띠 — 지금 날은 빈 칸에 먹 테두리, 미등록은 빗금
private struct WeekStrip: View {
    let cells: [ShiftInputViewModel.Cell]

    var body: some View {
        HStack(spacing: OnoffSpace.xs) {
            ForEach(cells) { cell in
                VStack(spacing: OnoffSpace.xs) {
                    Text("\(cell.date.day)").onoffText(11, .bold, numeric: true)
                    Group {
                        if cell.isCursor {
                            RoundedRectangle(cornerRadius: 8).fill(cell.shift.map { ShiftPalette.colors(for: $0.colorKey).background } ?? OnoffColor.card)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(OnoffColor.ink, lineWidth: 2))
                        } else if let shift = cell.shift {
                            RoundedRectangle(cornerRadius: 8).fill(ShiftPalette.colors(for: shift.colorKey).background)
                        } else {
                            UnregisteredPattern(cornerRadius: 8)
                        }
                    }
                    .frame(height: 30)
                }
                .foregroundStyle(cell.isCursor ? OnoffColor.ink : OnoffColor.textSecondary)
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(cell.date.day)일 \(cell.shift?.name ?? "미등록")")
            }
        }
        .padding(.horizontal, OnoffSpace.l)
        .padding(.vertical, 10)
        .background(OnoffColor.card, in: RoundedRectangle(cornerRadius: 16))
    }
}
