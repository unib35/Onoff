// 앱 탭바 — 원본 디자인 시스템 07 · 떠 있는 알약, 선택은 먹 색 알약, 아이콘 22 + 글자 12
import SwiftUI

struct FloatingTabItem: Identifiable {
    let id: String
    let title: String
    let icon: TabIcon
}

enum TabIcon {
    case home, roster

    /// 원본 SVG(24×24) 경로
    func path(in rect: CGRect) -> Path {
        let s = rect.width / 24
        var p = Path()
        switch self {
        case .home:
            p.move(to: CGPoint(x: 4 * s, y: 10.5 * s))
            p.addLine(to: CGPoint(x: 12 * s, y: 4 * s))
            p.addLine(to: CGPoint(x: 20 * s, y: 10.5 * s))
            p.addLine(to: CGPoint(x: 20 * s, y: 20 * s))
            p.addLine(to: CGPoint(x: 14.5 * s, y: 20 * s))
            p.addLine(to: CGPoint(x: 14.5 * s, y: 14.5 * s))
            p.addLine(to: CGPoint(x: 9.5 * s, y: 14.5 * s))
            p.addLine(to: CGPoint(x: 9.5 * s, y: 20 * s))
            p.addLine(to: CGPoint(x: 4 * s, y: 20 * s))
            p.closeSubpath()
        case .roster:
            p.addRoundedRect(in: CGRect(x: 3.5 * s, y: 5 * s, width: 17 * s, height: 15.5 * s), cornerSize: CGSize(width: 3 * s, height: 3 * s))
            p.move(to: CGPoint(x: 3.5 * s, y: 10 * s)); p.addLine(to: CGPoint(x: 20.5 * s, y: 10 * s))
            p.move(to: CGPoint(x: 8 * s, y: 3 * s)); p.addLine(to: CGPoint(x: 8 * s, y: 7 * s))
            p.move(to: CGPoint(x: 16 * s, y: 3 * s)); p.addLine(to: CGPoint(x: 16 * s, y: 7 * s))
        }
        return p
    }
}

private struct TabIconShape: Shape {
    let icon: TabIcon
    func path(in rect: CGRect) -> Path { icon.path(in: rect) }
}

struct FloatingTabBar: View {
    let items: [FloatingTabItem]
    @Binding var selection: String

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items) { item in
                let selected = item.id == selection
                Button { selection = item.id } label: {
                    VStack(spacing: 2) {
                        TabIconShape(icon: item.icon)
                            .stroke(style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
                            .frame(width: 22, height: 22)
                        Text(item.title).onoffText(12, selected ? .bold : .semibold)
                    }
                    .foregroundStyle(selected ? OnoffColor.onInk : OnoffColor.textSecondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background {
                        if selected { RoundedRectangle(cornerRadius: 26).fill(OnoffColor.ink) }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(6)
        .frame(height: 64)
        .background(OnoffColor.card.opacity(0.94), in: RoundedRectangle(cornerRadius: 32))
        .overlay(RoundedRectangle(cornerRadius: 32).stroke(OnoffColor.ink.opacity(0.06), lineWidth: 1))
        .shadow(color: OnoffShadow.floatingColor, radius: OnoffShadow.floatingRadius, y: OnoffShadow.floatingY)
    }
}
