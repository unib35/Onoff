# 결정 기록 (DEC)

사용자가 정한 것만 적는다. AI는 초안을 제안할 수 있지만 결정하지 않는다. 기준 문서끼리 충돌하면 여기가 가장 우선이다.

| ID | 날짜 | 결정 | 이유 · 대안 | 영향 문서 |
|---|---|---|---|---|
| DEC-001 | 2026-10-21 | 프로젝트 템플릿(ai-dev-starter)으로 작업 규칙 · 자동화를 시작한다 | 이슈 → 브랜치 → 검증 → PR 흐름을 첫날부터 쓰기 위해 | AGENTS.md |
| DEC-002 | 2026-10-21 | 앱은 네이티브 둘로 만든다 — iOS SwiftUI · Android Kotlin/Jetpack Compose | 1.0 핵심이 무음 · 집중 모드에서도 울리는 알람 · 위젯 · 잠금화면이라 OS 기능을 직접 쓴다. 비교: Flutter · React Native(Expo) — 화면은 한 번이지만 알람 · 위젯은 결국 네이티브 코드, iOS 먼저 — 로드맵 「같이 출시」와 다름 | AGENTS.md · architecture.md · code.md |
| DEC-003 | 2026-10-21 | 지금은 기기 안 저장만으로 만들고, 서버는 로그인 · 백업 이슈를 시작하기 전에 고른다 | 1.0 화면 대부분(근무 넣기 · 달력 · 알람 · 위젯 · 오프라인)은 서버가 필요 없고, 기획 원칙도 「서버가 멈춰도 보기 · 알람 동작」. 데이터는 처음부터 나중에 동기화할 수 있는 모양(Repository 뒤)으로 둔다. 비교: Supabase 지금 결정 · 완전히 서버 없이(15a · 15e · 15f 디자인 수정 필요). 다시 검토: REQ-002 · REQ-028 · REQ-037 착수 전 | requirements.md · architecture.md |
| DEC-004 | 2026-10-21 | 아키텍처는 B. Feature-based Lightweight Clean (View → ViewModel → UseCase → Repository, DI · Router · State Machine) | 근거: ① 규칙이 많다 — N 날짜 넘김, 근무 변경 시 2주치 알람 재예약, 나이트 다음 날 낮 알람 끄기, 입력 초안 → 적용 → 되돌리기 ② 같은 규칙을 iOS · Android에 각각 구현하므로 UseCase 단위 테스트로 결과를 맞춘다 ③ 서버(DEC-003) · 2.0 교환 상태 전이 · 배포 검사가 뒤에 붙는다. 비교: A. 가벼운 MVVM. 다시 검토: 1.0 기능 절반을 만든 뒤 파일 수 부담이 크면 단순 기능만 A 방식 허용 | architecture.md · agents.md |
| DEC-005 | 2026-10-21 | 앱 코드는 한 저장소의 `apps/ios` · `apps/android`. 작성자 웹은 `apps/web`, 서버는 `server/`(생길 때) | 이슈 · PR 하나로 두 플랫폼 변경을 같이 본다. 비교: 최상위 `ios/` · `android/` | code.md · project.sh |
| DEC-006 | 2026-10-21 | 도메인 규칙: ① 시간대 Asia/Seoul 고정, 근무는 시작한 날에 속하고 N은 다음 날 종료 시각까지 이어진다 ② 이름 · 병원 · 근무표 내용 등 개인정보를 로그 · 분석 이벤트에 남기지 않는다 ③ 서버가 없어도 근무표 보기 · 알람이 동작한다(로컬 저장이 원본) ④ 광고 알림은 따로 동의한 경우만, 야간(21–08시)은 별도 동의 | 기획 원칙(iOS 1d · 19c · 15b · 운영 1d)을 사용자가 확정 | AGENTS.md · requirements.md |
| DEC-007 | 2026-10-21 | GitHub 저장소는 public — `unib35/Onoff` | 사용자가 public으로 생성. 비교: private(추천했던 안). 영향: push한 내용은 곧바로 공개 — 비밀값은 `.env`에만, 기획 정리본(docs/design)도 공개됨 | git.md · project.sh |
