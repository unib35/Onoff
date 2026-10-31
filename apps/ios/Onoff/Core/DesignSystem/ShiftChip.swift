// 근무 칩 · 미등록 칸 — 원본 디자인 시스템 04
import SwiftUI

/// 근무 코드 칩. 크기 · 모서리는 화면마다 달라 인자로 받는다.
struct ShiftChip: View {
    let code: String
    let colorKey: String
    var width: CGFloat?
    var height: CGFloat = 22
    var cornerRadius: CGFloat = 7
    var fontSize: CGFloat = 13
    var weight: Font.Weight = .bold
    var serif = false
    /// 너비를 글자에 맞출 때 좌우 여백(원본 OFF 칩 0 7px)
    var horizontalPadding: CGFloat = 0

    var body: some View {
        let colors = ShiftPalette.colors(for: colorKey)
        Group {
            if serif {
                Text(code).font(OnoffFont.serif(fontSize))
            } else {
                Text(code).onoffText(fontSize, weight)
            }
        }
        .foregroundStyle(colors.foreground)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .padding(.horizontal, horizontalPadding)
        .frame(width: width, height: height)
        .frame(maxWidth: width == nil ? .infinity : nil)
        .background(colors.background, in: RoundedRectangle(cornerRadius: cornerRadius))
    }
}

/// 미등록(정보 없음) 빗금 — OFF와 섞이지 않게(REQ-008). 135° 1.5px 선, 6px 간격.
struct UnregisteredPattern: View {
    var cornerRadius: CGFloat = 3

    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 6
            var path = Path()
            var x = -size.height
            while x < size.width + size.height {
                path.move(to: CGPoint(x: x, y: size.height))
                path.addLine(to: CGPoint(x: x + size.height, y: 0))
                x += spacing
            }
            context.stroke(path, with: .color(OnoffColor.unregisteredHatch), lineWidth: 1.5)
        }
        .background(OnoffColor.unregisteredFill)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}
