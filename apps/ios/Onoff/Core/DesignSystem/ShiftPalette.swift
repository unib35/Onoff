// 근무 색 — 원본 디자인 시스템 01 색 「근무」 9색(바탕 · 글자)
import SwiftUI

struct ShiftColors: Sendable {
    let background: Color
    let foreground: Color

    init(_ background: UInt32, _ foreground: UInt32) {
        self.background = Color(hex: background)
        self.foreground = Color(hex: foreground)
    }

    init(background: Color, foreground: Color) {
        self.background = background
        self.foreground = foreground
    }
}

enum ShiftPalette {
    /// 근무 유형 colorKey → 색. 키는 원본 근무 이름(코드)과 같다.
    static func colors(for key: String) -> ShiftColors {
        switch key {
        case "D": ShiftColors(0xF5C451, 0x2A1F00)
        case "E": ShiftColors(0xF08A5D, 0x2A1006)
        case "N": ShiftColors(0x2E3A6E, 0xFFFFFF)
        case "OFF": ShiftColors(0xDCEBDF, 0x2F5D3C)
        case "연차": ShiftColors(0xA58BC9, 0x1E1230)
        case "M": ShiftColors(0x6FA79A, 0x0E2A24)
        case "S": ShiftColors(0x8C9BB0, 0x121A2A)
        case "교육": ShiftColors(0xCDBA8E, 0x2E2410)
        case "반차": ShiftColors(0xE09AAE, 0x3A1020)
        // 색이 정해지지 않은 근무 — 숨긴 근무처럼 테두리만(5b 「숨김」)
        default: ShiftColors(background: .clear, foreground: OnoffColor.textSecondary)
        }
    }
}
