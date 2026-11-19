// 개발용 — 시뮬레이터 스크린샷용 가짜 근무표 사진(22c · 22d). 이름 · 근무는 모두 지어낸 것. 출시 빌드에는 없다.
#if DEBUG
import UIKit

@MainActor
enum DebugSamplePhoto {
    struct Sample {
        let image: UIImage
        let first: PhotoPoint
        let last: PhotoPoint
    }

    private static let names = ["박○○", "이○○", "최○○", "정○○", "강○○", "조○○", "김서윤", "윤○○", "장○○", "임○○"]
    private static let myRow = 6
    private static let days = 30

    /// 한 번만 그린다
    static let sample = make()

    private static func make() -> Sample {
        let nameWidth: CGFloat = 150, cellWidth: CGFloat = 34, rowHeight: CGFloat = 52, top: CGFloat = 80
        let size = CGSize(width: nameWidth + cellWidth * CGFloat(days) + 40, height: top + rowHeight * CGFloat(names.count + 1) + 90)
        let codes = Array("EDEODDODENNNODDEEDDDOEDODDOONNNODDDODEEDODOENNNONNODOODODO")
        let image = UIGraphicsImageRenderer(size: size).image { context in
            UIColor(red: 0.965, green: 0.953, blue: 0.929, alpha: 1).setFill()
            context.fill(CGRect(origin: .zero, size: size))
            let ink = UIColor(red: 0.31, green: 0.29, blue: 0.26, alpha: 1)
            let line = UIColor(red: 0.79, green: 0.76, blue: 0.71, alpha: 1)
            ("2026년 11월 7병동 근무표" as NSString).draw(at: CGPoint(x: 20, y: 24), withAttributes: [
                .font: UIFont.systemFont(ofSize: 30, weight: .heavy), .foregroundColor: ink,
            ])
            let text: [NSAttributedString.Key: Any] = [.font: UIFont.monospacedSystemFont(ofSize: 20, weight: .bold), .foregroundColor: ink]
            for row in 0...names.count {
                let y = top + rowHeight * CGFloat(row)
                line.setFill()
                context.fill(CGRect(x: 20, y: y, width: size.width - 40, height: 1.5))
                if row > 0 {
                    (names[row - 1] as NSString).draw(at: CGPoint(x: 30, y: y + 14), withAttributes: [
                        .font: UIFont.systemFont(ofSize: 20, weight: .bold), .foregroundColor: ink,
                    ])
                }
                for day in 0..<days {
                    let x = 20 + nameWidth + cellWidth * CGFloat(day)
                    let label = row == 0 ? "\(day + 1)" : String(codes[(day * 7 + row * 11) % codes.count])
                    let width = (label as NSString).size(withAttributes: text).width
                    (label as NSString).draw(at: CGPoint(x: x + (cellWidth - width) / 2, y: y + 14), withAttributes: text)
                }
            }
            for column in 0...days {
                line.setFill()
                context.fill(CGRect(x: 20 + nameWidth + cellWidth * CGFloat(column), y: top, width: 1.5, height: rowHeight * CGFloat(names.count + 1)))
            }
            ("※ 근무 변경은 수간호사와 상의해 주세요" as NSString).draw(at: CGPoint(x: 20, y: size.height - 60), withAttributes: [
                .font: UIFont.systemFont(ofSize: 20), .foregroundColor: ink,
            ])
        }
        let y = (top + rowHeight * CGFloat(myRow + 1) + rowHeight / 2) / size.height
        func x(_ day: Int) -> Double { (20 + nameWidth + cellWidth * (CGFloat(day) + 0.5)) / size.width }
        return Sample(image: image, first: PhotoPoint(x: x(0), y: y), last: PhotoPoint(x: x(days - 1), y: y))
    }

    /// 22c — 두 칸을 누른 뒤
    static func place(_ viewModel: PhotoInputViewModel, sample: Sample) {
        guard viewModel.photo == nil else { return }
        viewModel.setPhoto(sample.image)
        viewModel.place(sample.first)
        viewModel.place(sample.last)
    }

    /// 22d — 1–13일을 넣고 14일 입력 중
    static func prepare(_ viewModel: PhotoInputViewModel, entering: Bool) {
        guard entering else { return }
        viewModel.startEntering()
        let keys = viewModel.input.keypadTypes
        let order = ["E", "E", "OFF", "D", "N", "N", "OFF", "OFF", "E", "E", "D", "OFF", "D"]
        for code in order { if let type = keys.first(where: { $0.code == code }) { viewModel.input.enter(type) } }
    }
}
#endif
