// REQ-005 · UI-IOS-5b — 근무 유형 관리: 키패드 순서 = 이 목록 순서 · 안 쓰는 건 숨김
import SwiftUI

struct ShiftTypeListView: View {
    @State var viewModel: ShiftTypeListViewModel
    let onBack: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                navigationBar
                if case let .loaded(list) = viewModel.state {
                    HStack {
                        Text("키패드에 보이는 근무 · \(list.visible.count)").onoffText(13, .bold)
                        Spacer()
                        HStack(spacing: 5) {
                            Circle().fill(OnoffColor.ink).frame(width: 6, height: 6)
                            Text("추가한 근무").onoffText(13)
                        }
                    }
                    .foregroundStyle(OnoffColor.textTertiary)
                    .padding(EdgeInsets(top: 2, leading: 2, bottom: 0, trailing: 2))

                    VStack(spacing: 0) {
                        ForEach(Array(list.visible.enumerated()), id: \.element.id) { index, type in
                            ShiftTypeRow(type: type, showsDivider: index < list.visible.count - 1)
                        }
                    }
                    .padding(.horizontal, 14)
                    .background(OnoffColor.card, in: RoundedRectangle(cornerRadius: OnoffRadius.card))

                    if !list.hidden.isEmpty { hiddenSection(list.hidden) }

                    // 새 근무 만들기(5c)는 다음 이슈
                    Text("+ 새 근무 만들기")
                        .onoffText(15, .bold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(OnoffColor.ink, in: RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .background(OnoffColor.background)
        .foregroundStyle(OnoffColor.ink)
        .task { await viewModel.load() }
    }

    private var navigationBar: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .frame(width: 40, height: 40, alignment: .leading)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("뒤로")
            Spacer()
            Text("근무 유형").onoffText(16, .bold)
            Spacer()
            Color.clear.frame(width: 40, height: 40)
        }
        .frame(height: 40)
    }

    private func hiddenSection(_ hidden: [ShiftType]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("숨김 · 키패드에 안 보여요")
                .onoffText(13, .bold)
                .foregroundStyle(OnoffColor.textTertiary)
                .padding(EdgeInsets(top: 4, leading: 2, bottom: 0, trailing: 2))
            HStack(spacing: 10) {
                ForEach(hidden) { type in
                    Text(type.code)
                        .onoffText(12, .heavy)
                        .foregroundStyle(OnoffColor.textSecondary)
                        .frame(width: 34, height: 30)
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(OnoffColor.hiddenOutline, lineWidth: 1.5))
                }
                Text("\(hidden.count)개").onoffText(14).foregroundStyle(OnoffColor.textSecondary)
                Spacer()
                // 「보이기」(숨김 풀기)는 근무 유형 편집 이슈에서
                Text("보이기").onoffText(13, .bold).underline()
            }
            .padding(.vertical, 11)
            .padding(.horizontal, 14)
            .background(OnoffColor.card, in: RoundedRectangle(cornerRadius: 18))
        }
    }
}

/// 끌기 손잡이 — 원본 SVG(24×24) `M5 9h14M5 15h14`
private struct DragHandleIcon: Shape {
    func path(in rect: CGRect) -> Path {
        let s = rect.width / 24
        var p = Path()
        p.move(to: CGPoint(x: 5 * s, y: 9 * s)); p.addLine(to: CGPoint(x: 19 * s, y: 9 * s))
        p.move(to: CGPoint(x: 5 * s, y: 15 * s)); p.addLine(to: CGPoint(x: 19 * s, y: 15 * s))
        return p
    }
}

private struct ShiftTypeRow: View {
    let type: ShiftType
    let showsDivider: Bool

    var body: some View {
        HStack(spacing: 10) {
            ShiftChip(code: type.code, colorKey: type.colorKey, width: 38, height: 38, cornerRadius: 10,
                      fontSize: chipFontSize, weight: .heavy)
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text(type.name).onoffText(15, .bold)
                    if type.isCustom { Circle().fill(OnoffColor.ink).frame(width: 6, height: 6) }
                }
                Text(ShiftFormat.compactTime(type))
                    .onoffText(13, numeric: true)
                    .foregroundStyle(OnoffColor.textSecondary)
            }
            Spacer()
            Text(kindLabel).onoffText(12, .semibold).foregroundStyle(OnoffColor.textSecondary)
            // 순서 바꾸기(끌기)는 근무 유형 편집 이슈에서
            DragHandleIcon()
                .stroke(OnoffColor.handle, style: StrokeStyle(lineWidth: 2.2 * 16 / 24, lineCap: .round))
                .frame(width: 16, height: 16)
        }
        .padding(.vertical, 9)
        .overlay(alignment: .bottom) {
            if showsDivider { Rectangle().fill(OnoffColor.divider).frame(height: 1) }
        }
    }

    /// 원본: 한 글자 15 · OFF 12 · 두 글자 한글 13
    private var chipFontSize: CGFloat {
        if type.code.count == 1 { return 15 }
        return type.code.allSatisfy(\.isASCII) ? 12 : 13
    }

    private var kindLabel: String {
        switch type.kind {
        case .work: "근무"
        case .off: "휴무"
        case .leave: "휴가"
        }
    }
}
