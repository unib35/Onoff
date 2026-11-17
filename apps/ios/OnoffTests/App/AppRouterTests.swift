// 라우터 — 시트를 닫은 뒤 전체 화면 · 데이터 변경 신호
import Testing
@testable import Onoff

@MainActor
struct AppRouterTests {
    @Test("시트가 떠 있으면 닫고, 닫힌 뒤에 전체 화면을 띄운다")
    func coverAfterSheet() {
        let router = AppRouter()
        router.present(AppSheet.shiftInput(.start(year: 2026, month: 11)))
        let editor = AppCover.shiftInput(.editor(year: 2026, month: 11, day: nil))
        router.present(editor)
        #expect(router.sheet == nil)
        #expect(router.cover == nil)
        router.sheetDidDismiss()
        #expect(router.cover == editor)
        router.sheetDidDismiss() // 두 번 불려도 그대로
        #expect(router.cover == editor)
        router.dismissCover()
        #expect(router.cover == nil)
    }

    @Test("시트가 없으면 바로 띄우고, 데이터가 바뀌면 신호가 올라간다")
    func coverDirectlyAndRevision() {
        let router = AppRouter()
        router.present(AppCover.shiftInput(.editor(year: 2026, month: 11, day: nil)))
        #expect(router.cover != nil)
        let before = router.dataRevision
        router.dataDidChange()
        #expect(router.dataRevision == before + 1)
    }
}
