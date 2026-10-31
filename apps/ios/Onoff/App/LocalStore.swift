// DEC-013 — 기기 안 저장소(SwiftData). 저장 모델은 각 기능의 Data에 있고, 여기서는 한 저장소로 묶기만 한다.
// 위젯과 같이 쓰는 App Group 위치는 1.1 위젯 이슈에서(번들 ID · 개발 팀 확정 후) — 그때 기존 파일을 옮겨야 한다(옮기지 않으면 근무표가 비어 보임).
import Foundation
import SwiftData

enum LocalStore {
    static let schema = Schema([StoredShiftType.self, StoredDuty.self, StoredMemo.self])

    /// 앱 기본 위치(Application Support)의 저장소
    static func makeContainer() throws -> ModelContainer {
        try ModelContainer(for: schema, configurations: ModelConfiguration(
            "Onoff", schema: schema,
            // 기본값(.automatic)은 entitlement가 붙는 순간 저장 위치 · iCloud 동기화를 바꾼다 — 1.0 데이터가 사라져 보이지 않게 명시(DEC-013)
            groupContainer: .none, cloudKitDatabase: .none
        ))
    }

    /// 테스트용 — 기기에 파일을 만들지 않는다
    static func makeInMemoryContainer() throws -> ModelContainer {
        try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
    }

    /// 테스트용 — 정한 파일 위치(껐다 켜기 확인)
    static func makeContainer(at url: URL) throws -> ModelContainer {
        try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none))
    }
}
