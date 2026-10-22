// 디자인 토큰 — 원본 `온오프 디자인 시스템.dc.html` 01 색 · 02 글자 · 03 간격 · 모서리 · 그림자 · 상태 색.
// 화면 코드에는 숫자 · 색을 직접 쓰지 않고 이 이름만 쓴다(code.md).
import SwiftUI

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

enum OnoffColor {
    // 01 색 · 기본
    static let background = Color(hex: 0xF4F1EA)   // 바탕 · 화면
    static let card = Color(hex: 0xFFFDF9)         // 카드 · 면
    static let ink = Color(hex: 0x1F1D1A)          // 먹 · 글자 · 주 버튼
    static let textSecondary = Color(hex: 0x4F4A43) // 보조 글자 · 4.5:1 이상
    static let line = Color(hex: 0xE4DFD5)         // 선 · 테두리
    static let canvas = Color(hex: 0xE9E5DD)       // 캔버스

    // 화면에서 쓰는 이름 없는 값(원본 캔버스) — 이름을 붙여 한 곳에 둔다
    static let textTertiary = Color(hex: 0x6E685F)  // 섹션 제목 · 연도
    static let divider = Color(hex: 0xEDE9E1)       // 목록 구분선
    static let handle = Color(hex: 0x9A948A)        // 끌기 손잡이
    static let sheetGrabber = Color(hex: 0xDAD4C9)  // 시트 손잡이 · 비활성
    static let hiddenOutline = Color(hex: 0xC9C2B6) // 숨긴 근무 테두리
    static let rowHighlight = Color(hex: 0xFBF9F4)  // 추가한 근무 행
    static let trackBackground = Color(hex: 0xF0ECE4) // 24시간 띠 바탕
    static let sunday = Color(hex: 0xC2412D)        // 일요일 · 경고 빨강
    static let scrim = Color(hex: 0x8C867D)         // 시트 뒤 어둡게

    // 미등록 빗금(OFF 아님)
    static let unregisteredFill = Color(hex: 0xF6F3ED)
    static let unregisteredHatch = Color(hex: 0xD6CFC3)

    // 상태
    static let conflictBackground = Color(hex: 0xF8E1DB) // 겹침
    static let conflictText = Color(hex: 0x8E2A1B)
    static let positive = Color(hex: 0x2F6B45)           // 통과 · 켜짐
    static let nightNextDay = Color(hex: 0xDADFF1)       // 나이트 다음 날
    static let nightNextDayText = Color(hex: 0x1B2350)
}

enum OnoffSpace {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let s: CGFloat = 6
    static let m: CGFloat = 8
    static let l: CGFloat = 12
    static let xl: CGFloat = 16
    static let xxl: CGFloat = 24
}

enum OnoffRadius {
    static let chip: CGFloat = 6
    static let button: CGFloat = 12
    static let card: CGFloat = 20
    static let sheet: CGFloat = 28
}

enum OnoffShadow {
    /// 떠 있는 바(탭바)
    static let floatingColor = Color(hex: 0x1F1D1A, opacity: 0.14)
    static let floatingRadius: CGFloat = 14
    static let floatingY: CGFloat = 10
    /// 시트
    static let sheetColor = Color(hex: 0x1F1D1A, opacity: 0.18)
}

/// 02 글자 — Pretendard Variable 본문, Instrument Serif는 근무 코드 · 시각 강조에만.
enum OnoffFont {
    static func sans(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .custom(pretendardName(weight), size: size)
    }

    static func serif(_ size: CGFloat) -> Font {
        .custom("InstrumentSerif-Regular", size: size)
    }

    /// 자간: 기본 -0.01em, 22px 이상 제목 -0.03em
    static func tracking(for size: CGFloat) -> CGFloat {
        size * (size >= 22 ? -0.03 : -0.01)
    }

    private static func pretendardName(_ weight: Font.Weight) -> String {
        switch weight {
        case .black: "PretendardVariable-Black"
        case .heavy: "PretendardVariable-ExtraBold"
        case .bold: "PretendardVariable-Bold"
        case .semibold: "PretendardVariable-SemiBold"
        case .medium: "PretendardVariable-Medium"
        case .light: "PretendardVariable-Light"
        default: "PretendardVariable-Regular"
        }
    }
}

extension View {
    /// 원본 글자 스타일: 크기 · 굵기 · 자간 · (숫자) tabular-nums
    func onoffText(_ size: CGFloat, _ weight: Font.Weight = .regular, numeric: Bool = false) -> some View {
        font(OnoffFont.sans(size, weight))
            .tracking(OnoffFont.tracking(for: size))
            .monospacedDigit(numeric)
    }

    @ViewBuilder fileprivate func monospacedDigit(_ on: Bool) -> some View {
        if on { self.monospacedDigit() } else { self }
    }
}
