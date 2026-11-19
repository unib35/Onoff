// UI-IOS-22b · UI-IOS-22d — 근무 키(큰 키 · 둘째 줄 키)와 지금 칸 고리. 순서 칸 고치기와 사진 보며 입력이 같이 쓴다.
import SwiftUI

/// 지금 고치는 칸 · 고른 키 고리(2px 틈 + 먹 1.5px)
struct CurrentRing: View {
    let cornerRadius: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius + 2.75)
            .stroke(OnoffColor.ink, lineWidth: 1.5)
            .padding(-2.75)
    }
}

struct EditKey: View {
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
