// DEC-013 — 여러 기능의 Data가 같이 쓰는 저장소 도움 코드. Domain · 화면은 쓰지 않는다.
import Foundation

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
