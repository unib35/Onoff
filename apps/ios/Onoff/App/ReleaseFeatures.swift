// REQ-038 · REQ-039 · DEC-011 — 1.0에서 덜어낸 부분을 버전별로 켜는 한 곳(architecture.md).
// 화면을 따로 만들지 않고 같은 화면에서 이 값으로 숨긴다. 버전 근거: 온오프 출시 로드맵(2026-10-22).
import Foundation

struct ReleaseFeatures: Sendable {
    /// 1.1 알람 — 12a 오늘의 순서 · 띠의 알람 표시, 3c 알람 줄 · 안내 문구
    var alarms = false
    /// 1.2 알림 목록 — 12a 종 아이콘
    var notifications = false
    /// 1.2 사진으로 넣기 — 1f 「사진」 버튼
    var photoImport = false
    /// 1.3 희망 듀티 계획 — 1f 다음 달 희망 칸 · 문구
    var wishDuty = false
    /// 1.2 공유 탭 · 1.3 계획 탭
    var shareTab = false
    var planTab = false

    /// 1.0 MVP
    static let mvp = ReleaseFeatures()
}
