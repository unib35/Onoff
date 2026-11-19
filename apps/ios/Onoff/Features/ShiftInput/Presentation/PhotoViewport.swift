// REQ-014 · UI-IOS-22c · UI-IOS-22d — 사진 비율 좌표(PhotoPoint) ↔ 화면 좌표 변환.
import CoreGraphics

struct PhotoViewport: Equatable {
    /// 화면에 그린 사진의 왼쪽 위
    var origin: CGPoint
    /// 화면에 그린 사진 크기
    var size: CGSize

    /// 22c — 틀에 맞춰 다 보이게(scale 1) 그리고, 두 손가락 확대 · 끌기를 더한다
    static func fit(container: CGSize, image: CGSize, scale: CGFloat = 1, offset: CGSize = .zero) -> PhotoViewport {
        guard image.width > 0, image.height > 0 else { return PhotoViewport(origin: .zero, size: container) }
        let base = min(container.width / image.width, container.height / image.height)
        let size = CGSize(width: image.width * base * scale, height: image.height * base * scale)
        return PhotoViewport(origin: CGPoint(x: (container.width - size.width) / 2 + offset.width,
                                             y: (container.height - size.height) / 2 + offset.height),
                             size: size)
    }

    /// 22d — 칸 하나가 `cellWidth`가 되게 키우고 `point`를 화면 `anchor`에 둔다
    static func focus(on point: PhotoPoint, step: PhotoPoint, image: CGSize, cellWidth: CGFloat, anchor: CGPoint,
                      maxWidth: CGFloat = 12_000) -> PhotoViewport {
        guard image.width > 0, image.height > 0 else { return PhotoViewport(origin: .zero, size: .zero) }
        let aspect = image.height / image.width
        // 칸 간격(사진 비율)을 화면 너비 1일 때의 길이로 — 사진이 조금 기울어도 맞게
        let unit = (pow(step.x, 2) + pow(step.y * aspect, 2)).squareRoot()
        // 두 칸이 거의 겹치면 끝없이 커진다 — 그린 사진 너비는 maxWidth에서 멈춘다
        let width = unit > 0 ? min(cellWidth / unit, maxWidth) : image.width
        let size = CGSize(width: width, height: width * aspect)
        return PhotoViewport(origin: CGPoint(x: anchor.x - point.x * size.width, y: anchor.y - point.y * size.height), size: size)
    }

    func viewPoint(_ point: PhotoPoint) -> CGPoint {
        CGPoint(x: origin.x + point.x * size.width, y: origin.y + point.y * size.height)
    }

    func photoPoint(_ point: CGPoint) -> PhotoPoint {
        guard size.width > 0, size.height > 0 else { return PhotoPoint(x: 0, y: 0) }
        return PhotoPoint(x: (point.x - origin.x) / size.width, y: (point.y - origin.y) / size.height)
    }

    /// 화면에서 끈 거리 → 사진 비율
    func photoDelta(_ translation: CGSize) -> PhotoPoint {
        guard size.width > 0, size.height > 0 else { return PhotoPoint(x: 0, y: 0) }
        return PhotoPoint(x: translation.width / size.width, y: translation.height / size.height)
    }

    /// 칸 하나의 화면 크기 — 줄 높이는 재지 않으므로 너비의 0.82(22d 원본 34 × 28)
    func cellSize(step: PhotoPoint) -> CGSize {
        let width = (pow(step.x * size.width, 2) + pow(step.y * size.height, 2)).squareRoot()
        return CGSize(width: width, height: width * 0.82)
    }
}
