// REQ-014 · UI-IOS-22c · UI-IOS-22d — 사진 보며 입력: 사진 속 내 줄 칸 위치. 글자 인식은 없다(1.2 REQ-108).
// 1일 칸과 마지막 날 칸을 한 번씩 누르면 그 사이를 날짜 수대로 똑같이 나눈다(22c).
// 입력 중 어긋나 사진을 끌어 맞추면 그 날부터 뒤 칸이 모두 같이 옮겨진다(22d).
import Foundation

/// 사진 위 위치 — 사진 너비 · 높이에 대한 비율(0–1). 화면 크기 · 확대와 무관하다.
struct PhotoPoint: Hashable, Sendable {
    var x: Double
    var y: Double

    static func + (lhs: PhotoPoint, rhs: PhotoPoint) -> PhotoPoint { PhotoPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y) }
    static func - (lhs: PhotoPoint, rhs: PhotoPoint) -> PhotoPoint { PhotoPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y) }
}

struct PhotoGrid: Hashable, Sendable {
    /// 1일 칸 가운데
    var first: PhotoPoint
    /// 마지막 날 칸 가운데
    var last: PhotoPoint
    /// 그 달 날 수(2 이상)
    let dayCount: Int
    /// 끌어 맞춘 보정 — 키는 날 순서(0 = 1일). 그 날부터 뒤 칸에 더한다.
    private(set) var corrections: [Int: PhotoPoint] = [:]

    init(first: PhotoPoint, last: PhotoPoint, dayCount: Int) {
        self.first = first
        self.last = last
        self.dayCount = max(dayCount, 2)
    }

    /// 칸 하나의 간격(사진 비율) — 두 칸 사이를 날짜 수대로 나눈 것
    var step: PhotoPoint {
        let gaps = Double(dayCount - 1)
        return PhotoPoint(x: (last.x - first.x) / gaps, y: (last.y - first.y) / gaps)
    }

    /// `index`번째 날(0 = 1일) 칸 가운데
    func center(ofDay index: Int) -> PhotoPoint {
        let clamped = max(0, min(index, dayCount - 1))
        let gap = step
        var point = PhotoPoint(x: first.x + gap.x * Double(clamped), y: first.y + gap.y * Double(clamped))
        for (day, delta) in corrections where day <= clamped { point = point + delta }
        return point
    }

    /// 22d 「어긋나면 사진을 끌어 맞춰요」 — `index`번째 날 칸이 실제로는 `delta`만큼 떨어져 있다. 뒤 칸도 같이 옮긴다.
    mutating func correct(day index: Int, by delta: PhotoPoint) {
        guard (0..<dayCount).contains(index), delta != PhotoPoint(x: 0, y: 0) else { return }
        corrections[index] = (corrections[index] ?? PhotoPoint(x: 0, y: 0)) + delta
    }
}
