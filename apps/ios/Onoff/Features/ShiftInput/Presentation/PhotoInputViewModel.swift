// REQ-014 · UI-IOS-22c · UI-IOS-22d — 사진 보며 입력 상태. 근무 넣기 · 되돌리기 · 적용은 키패드 입력(ShiftInputViewModel)을 그대로 쓴다.
// 사진은 시스템 선택기로 받아 이 화면 메모리에만 둔다 — 저장 · 업로드 · 글자 인식 없음.
// 예외: UseCase 대신 키패드 입력 ViewModel을 받는다 — 초안 · 되돌리기 · 적용 규칙을 두 번 쓰지 않으려고.
import UIKit

@MainActor @Observable
final class PhotoInputViewModel {
    enum Phase: Equatable {
        /// 사진 고르는 중(시스템 선택기)
        case picking
        /// 22c 처음 맞추기
        case aligning
        /// 22d 입력 중
        case entering
    }

    enum Marker: Hashable {
        case first
        case last
    }

    /// 22d 아래 7일 띠 — 지금 날 앞 4일 · 뒤 2일
    static let weekLength = 7
    static let daysBefore = 4
    /// 두 칸이 이보다 가까우면(사진 비율) 같은 칸을 두 번 누른 것으로 보고 받지 않는다
    static let minimumSpan = 0.05

    let input: ShiftInputViewModel
    private(set) var phase: Phase = .picking
    private(set) var photo: UIImage?
    /// 22c에서 누른 1일 칸 · 마지막 날 칸
    private(set) var first: PhotoPoint?
    private(set) var last: PhotoPoint?
    /// 22d 칸 위치 — 입력을 시작할 때 두 칸으로 만든다
    private(set) var grid: PhotoGrid?
    /// 사진을 읽지 못함
    var photoFailed = false

    init(input: ShiftInputViewModel) {
        self.input = input
    }

    // MARK: - 사진

    /// 새 사진 — 맞춘 칸은 처음부터 다시
    func setPhoto(_ image: UIImage) {
        photo = image
        first = nil
        last = nil
        grid = nil
        phase = .aligning
    }

    // MARK: - 22c 처음 맞추기

    var lastDayNumber: Int { input.dayCount }
    var isAligned: Bool { first != nil && last != nil }

    /// 사진을 누름 — 1일 칸, 그다음 마지막 날 칸. 둘 다 있으면 표시를 끌어서 옮긴다.
    func place(_ point: PhotoPoint) {
        let point = Self.clamped(point)
        if first == nil {
            first = point
        } else if let first, last == nil, Self.distance(first, point) >= Self.minimumSpan {
            last = point
        }
    }

    /// 표시 끌기 — 사진 밖으로는 나가지 않고, 두 표시가 너무 가까워지면 멈춘다
    func move(_ marker: Marker, to point: PhotoPoint) {
        let point = Self.clamped(point)
        switch marker {
        case .first:
            if let last, Self.distance(last, point) < Self.minimumSpan { return }
            first = point
        case .last:
            if let first, Self.distance(first, point) < Self.minimumSpan { return }
            last = point
        }
    }

    nonisolated static func clamped(_ point: PhotoPoint) -> PhotoPoint {
        PhotoPoint(x: min(max(point.x, 0), 1), y: min(max(point.y, 0), 1))
    }

    nonisolated static func distance(_ a: PhotoPoint, _ b: PhotoPoint) -> Double {
        ((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y)).squareRoot()
    }

    /// 「처음부터 다시 맞추기」
    func resetAlignment() {
        first = nil
        last = nil
    }

    /// 맞춘 두 칸으로 나눈 칸 간격(입력 전 미리보기용)
    var alignedGrid: PhotoGrid? {
        guard let first, let last else { return nil }
        return PhotoGrid(first: first, last: last, dayCount: input.dayCount)
    }

    /// 입력을 시작할 날 — 처음은 1일(「11월 1일부터」), 다시 맞추고 돌아오면 하던 날
    var startDay: CalendarDay { grid == nil ? input.firstDay : input.cursorDay }

    /// 「이대로 입력 시작」
    func startEntering() {
        guard let alignedGrid else { return }
        let day = startDay
        // 두 표시를 그대로 두고 돌아오면 22d에서 끌어 맞춘 보정도 그대로
        if grid?.first != alignedGrid.first || grid?.last != alignedGrid.last { grid = alignedGrid }
        input.select(day)
        phase = .entering
    }

    // MARK: - 22d 입력 중

    /// 지금 날의 순서(0 = 1일)
    var cursorIndex: Int { SeoulCalendar.daysBetween(input.firstDay, input.cursorDay) }

    /// 지금 칸 가운데(사진 비율)
    var currentCenter: PhotoPoint? { grid?.center(ofDay: cursorIndex) }

    /// 「어긋나면 사진을 끌어 맞춰요」 — 지금 칸이 실제로 `delta`만큼 떨어져 있다. 뒤 칸도 같이.
    func realign(by delta: PhotoPoint) {
        grid?.correct(day: cursorIndex, by: delta)
    }

    /// 「다시 맞추기」 — 22c로. 두 표시는 그대로 두고 끌어서 고친다.
    func backToAligning() {
        phase = .aligning
    }

    /// 7일 띠 — 달 끝에서는 앞쪽 날을 더 보여 준다
    var weekCells: [ShiftInputViewModel.Cell] {
        let cells = input.cells
        guard cells.count > Self.weekLength else { return cells }
        let start = max(0, min(cursorIndex - Self.daysBefore, cells.count - Self.weekLength))
        return Array(cells[start..<(start + Self.weekLength)])
    }
}
