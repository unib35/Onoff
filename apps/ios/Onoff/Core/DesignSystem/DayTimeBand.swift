// 24시간 띠 — 근무를 글자가 아니라 하루 위의 실제 시간으로 그린다(원본 시각 언어)
import SwiftUI

struct DayTimeBand: View {
    /// 0...1 비율 구간들(ShiftTimeline.dayFractions)
    let segments: [ClosedRange<Double>]
    let trackColor: Color
    let barColor: Color
    var height: CGFloat = 22
    var cornerRadius: CGFloat = 6
    /// 막대 위아래 여백(12a는 4)
    var barInset: CGFloat = 0
    var barCornerRadius: CGFloat = 6
    /// 지금 시각 표시(0...1)
    var nowFraction: Double?
    var nowColor: Color = OnoffColor.ink

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: cornerRadius).fill(trackColor)
                ForEach(Array(segments.enumerated()), id: \.offset) { _, range in
                    RoundedRectangle(cornerRadius: barCornerRadius)
                        .fill(barColor)
                        .frame(width: w * (range.upperBound - range.lowerBound), height: height - barInset * 2)
                        .offset(x: w * range.lowerBound, y: barInset)
                }
                if let nowFraction {
                    Rectangle()
                        .fill(nowColor)
                        .frame(width: 2, height: height + 8)
                        .offset(x: w * nowFraction, y: -4)
                }
            }
        }
        .frame(height: height)
    }
}
