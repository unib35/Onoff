// DEC-006 — 「지금 시각」은 주입해서 테스트에서 고정한다(architecture.md)
import Foundation

protocol AppClock: Sendable {
    func now() -> Date
}

struct SystemClock: AppClock {
    func now() -> Date { Date() }
}

struct FixedClock: AppClock {
    let date: Date
    func now() -> Date { date }
}
