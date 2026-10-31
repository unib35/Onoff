// DEC-013 — 기기 안 저장소(SwiftData). 저장 모델은 각 기능의 Data에 있고, 여기서는 한 저장소로 묶기만 한다.
// 위젯과 같이 쓰는 App Group 위치는 1.1 위젯 이슈에서(번들 ID · 개발 팀 확정 후).
import Foundation
import SwiftData

enum LocalStore {
    static let schema = Schema([StoredShiftType.self, StoredDuty.self, StoredMemo.self])

    /// 앱 기본 위치(Application Support)의 저장소
    static func makeContainer() throws -> ModelContainer {
        try ModelContainer(for: schema, configurations: ModelConfiguration("Onoff", schema: schema))
    }

    /// 테스트용 — 기기에 파일을 만들지 않는다
    static func makeInMemoryContainer() throws -> ModelContainer {
        try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
    }

    /// 테스트용 — 정한 파일 위치(껐다 켜기 확인)
    static func makeContainer(at url: URL) throws -> ModelContainer {
        try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, url: url))
    }
}

enum LocalStoreError: Error {
    /// 저장된 값을 Domain 값으로 바꿀 수 없음(손상 · 모르는 값). 값 자체는 오류에 담지 않는다(DEC-006 개인정보)
    case corrupted
}

extension CalendarDay {
    /// 저장 · 범위 조회용 정렬 가능한 키(yyyymmdd)
    var storageKey: Int { year * 10_000 + month * 100 + day }

    init(storageKey: Int) {
        self.init(year: storageKey / 10_000, month: storageKey / 100 % 100, day: storageKey % 100)
    }
}
