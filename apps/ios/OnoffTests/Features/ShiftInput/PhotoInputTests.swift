// REQ-014 · UI-IOS-22c · UI-IOS-22d — 사진 보며 입력: 두 칸 나누기 · 끌어 맞추기 · 화면 좌표 · 화면 상태. 가짜 데이터만.
import CoreGraphics
import Foundation
import Testing
import UIKit
@testable import Onoff

private func point(_ x: Double, _ y: Double) -> PhotoPoint { PhotoPoint(x: x, y: y) }

private func close(_ a: PhotoPoint, _ b: PhotoPoint) -> Bool { abs(a.x - b.x) < 1e-9 && abs(a.y - b.y) < 1e-9 }

struct PhotoGridTests {
    @Test("1일 칸과 마지막 날 칸 사이를 날짜 수대로 똑같이 나눈다 — 기울어진 사진도")
    func divide() {
        let grid = PhotoGrid(first: point(0.1, 0.5), last: point(0.97, 0.529), dayCount: 30)
        #expect(close(grid.center(ofDay: 0), point(0.1, 0.5)))
        #expect(close(grid.center(ofDay: 29), point(0.97, 0.529)))
        #expect(close(grid.center(ofDay: 10), point(0.1 + 0.03 * 10, 0.5 + 0.001 * 10)))
        // 범위 밖은 끝 칸
        #expect(close(grid.center(ofDay: 40), grid.center(ofDay: 29)))
    }

    @Test("끌어 맞추면 그 날부터 뒤 칸이 같이 옮겨지고, 앞 칸은 그대로")
    func correct() {
        var grid = PhotoGrid(first: point(0, 0.5), last: point(0.29, 0.5), dayCount: 30)
        grid.correct(day: 13, by: point(0.005, -0.01))
        grid.correct(day: 20, by: point(0.002, 0))
        #expect(close(grid.center(ofDay: 12), point(0.12, 0.5)))
        #expect(close(grid.center(ofDay: 13), point(0.135, 0.49)))
        #expect(close(grid.center(ofDay: 25), point(0.257, 0.49)))
        // 같은 날을 또 맞추면 더한다
        grid.correct(day: 13, by: point(0.005, 0))
        #expect(close(grid.center(ofDay: 13), point(0.14, 0.49)))
    }
}

struct PhotoViewportTests {
    @Test("다 보이게 맞추기 — 사진 비율 ↔ 화면 좌표가 서로 돌아온다")
    func fitRoundTrip() {
        let viewport = PhotoViewport.fit(container: CGSize(width: 378, height: 372), image: CGSize(width: 1200, height: 800),
                                         scale: 2, offset: CGSize(width: 10, height: -5))
        #expect(viewport.size == CGSize(width: 756, height: 504))
        let p = point(0.3, 0.7)
        #expect(close(viewport.photoPoint(viewport.viewPoint(p)), p))
    }

    @Test("칸 하나를 34pt로 키우고 지금 칸을 정한 자리에 둔다")
    func focus() {
        let viewport = PhotoViewport.focus(on: point(0.5, 0.6), step: point(0.025, 0), image: CGSize(width: 1000, height: 500),
                                           cellWidth: 34, anchor: CGPoint(x: 200, y: 210))
        #expect(abs(viewport.size.width - 1360) < 1e-9)
        #expect(viewport.viewPoint(point(0.5, 0.6)) == CGPoint(x: 200, y: 210))
        #expect(abs(viewport.cellSize(step: point(0.025, 0)).width - 34) < 1e-9)
    }

    @Test("두 칸이 거의 겹쳐도 사진이 끝없이 커지지 않는다")
    func focusCapped() {
        let viewport = PhotoViewport.focus(on: point(0.5, 0.5), step: point(1e-7, 0), image: CGSize(width: 1000, height: 500),
                                           cellWidth: 34, anchor: .zero)
        #expect(viewport.size.width == 12_000)
    }
}

@MainActor
struct PhotoInputViewModelTests {
    private func day(_ d: Int) -> CalendarDay { TestSupport.day(2026, 11, d) }

    private func viewModel(_ duties: [CalendarDay: ShiftTypeID] = [:]) async -> PhotoInputViewModel {
        let repository = InMemoryDutyRepository(duties)
        let model = PhotoInputViewModel(input: ShiftInputViewModel(
            range: StartShiftInputUseCase.month(year: 2026, month: 11), cursor: nil,
            startShiftInput: StartShiftInputUseCase(shiftTypes: InMemoryShiftTypeRepository(SampleData.shiftTypes), duties: repository),
            applyShiftInput: ApplyShiftInputUseCase(duties: repository)))
        await model.input.load()
        return model
    }

    private var photo: UIImage { UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10)).image { _ in } }

    @Test("22c: 1일 칸 → 마지막 날 칸 순서로 누르고, 다 누른 뒤 누르기는 무시 · 다시 맞추기")
    func align() async {
        let model = await viewModel()
        #expect(model.phase == .picking)
        model.setPhoto(photo)
        #expect(model.phase == .aligning)
        model.place(point(0.1, 0.5))
        #expect(!model.isAligned)
        model.place(point(0.9, 0.5))
        model.place(point(0.4, 0.4))
        #expect(model.isAligned)
        #expect(model.last == point(0.9, 0.5))
        model.move(.first, to: point(0.12, 0.5))
        #expect(model.first == point(0.12, 0.5))
        model.resetAlignment()
        #expect(model.first == nil && model.last == nil)
    }

    @Test("22c → 22d: 처음은 1일부터(첫 미등록 날이 아니어도), 다시 맞추고 돌아오면 하던 날부터")
    func startDay() async throws {
        let model = await viewModel([day(1): ShiftTypeID(rawValue: "D")])
        model.setPhoto(photo)
        model.startEntering() // 두 칸이 없으면 시작하지 않는다
        #expect(model.phase == .aligning)
        model.place(point(0.1, 0.5))
        model.place(point(0.97, 0.5))
        #expect(model.startDay == day(1))
        model.startEntering()
        #expect(model.phase == .entering)
        #expect(model.input.cursorDay == day(1))

        let e = try #require(model.input.keypadTypes.first { $0.code == "E" })
        model.input.enter(e)
        model.input.enter(e)
        #expect(model.cursorIndex == 2)
        #expect(model.currentCenter.map { close($0, point(0.16, 0.5)) } == true)

        model.backToAligning()
        #expect(model.startDay == day(3))
        model.startEntering()
        #expect(model.input.cursorDay == day(3))
        #expect(model.input.changedCount == 2) // 초안은 그대로
    }

    @Test("22d: 끌어 맞추면 지금 날부터 옮겨진다 · 7일 띠는 앞 4일 뒤 2일, 달 끝에서는 앞을 더")
    func entering() async {
        let model = await viewModel()
        model.setPhoto(photo)
        model.place(point(0.1, 0.5))
        model.place(point(0.97, 0.5))
        model.startEntering()
        #expect(model.weekCells.map(\.date.day) == [1, 2, 3, 4, 5, 6, 7])
        model.input.select(day(14))
        #expect(model.weekCells.map(\.date.day) == [10, 11, 12, 13, 14, 15, 16])
        model.realign(by: point(0.01, 0))
        #expect(model.currentCenter.map { close($0, point(0.1 + 0.03 * 13 + 0.01, 0.5)) } == true)
        #expect(model.grid.map { close($0.center(ofDay: 12), point(0.1 + 0.03 * 12, 0.5)) } == true)
        model.input.select(day(30))
        #expect(model.weekCells.map(\.date.day) == [24, 25, 26, 27, 28, 29, 30])
    }

    @Test("새 사진을 고르면 맞춘 칸은 처음부터")
    func newPhoto() async {
        let model = await viewModel()
        model.setPhoto(photo)
        model.place(point(0.1, 0.5))
        model.place(point(0.9, 0.5))
        model.startEntering()
        model.setPhoto(photo)
        #expect(model.phase == .aligning)
        #expect(model.first == nil && model.grid == nil)
    }

    @Test("22c: 같은 칸을 두 번 누르면 마지막 날 칸으로 받지 않는다 · 사진 밖은 끝으로 · 표시를 겹치게 끌 수 없다")
    func tooClose() async {
        let model = await viewModel()
        model.setPhoto(photo)
        model.place(point(-0.2, 0.5))
        #expect(model.first == point(0, 0.5))
        model.place(point(0.01, 0.5))
        #expect(model.last == nil)
        model.place(point(0.9, 1.3))
        #expect(model.last == point(0.9, 1))
        model.move(.last, to: point(0.02, 0.5))
        #expect(model.last == point(0.9, 1))
    }

    @Test("22d에서 끌어 맞춘 보정은 「다시 맞추기」 뒤 표시를 그대로 두면 남고, 표시를 옮기면 처음부터")
    func correctionsKept() async {
        let model = await viewModel()
        model.setPhoto(photo)
        model.place(point(0.1, 0.5))
        model.place(point(0.97, 0.5))
        model.startEntering()
        model.input.select(day(14))
        model.realign(by: point(0.01, 0))
        let corrected = model.currentCenter
        model.backToAligning()
        model.startEntering()
        #expect(model.currentCenter == corrected)
        model.backToAligning()
        model.move(.last, to: point(0.96, 0.5))
        model.startEntering()
        #expect(model.grid?.corrections.isEmpty == true)
    }
}
