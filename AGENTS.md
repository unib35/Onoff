# AGENTS.md — Onoff 공통 작업 규칙

간호사 듀티(근무표) 앱 — 근무표를 한 번 넣으면 오늘 · 내일 근무가 바로 보이고, 출근 알람이 근무에 맞게 울린다. 개인 앱(1.0)을 먼저 내고 공유 → 일정 → 그룹 → 병동(2.0) 순서로 넓힌다. iOS · Android 같이 출시, 무료.
이 파일이 모든 AI 도구의 기본 규칙 원본이다. 세부 규칙은 링크한 문서에 있다.

## 기준 문서 (충돌 시 위가 우선)

1. 사용자 결정 — `docs/decisions.md` (DEC-nnn)
2. 기획 · 디자인 원본 — Claude Design 「Onoff 간호사 듀티 앱」 https://claude.ai/design/p/0397bbf3-8476-4802-8de8-86d2e42bc216 (정리본 `docs/design/README.md`). 버전 범위는 그 안의 `온오프 출시 로드맵.dc.html`
3. 화면 — `docs/design/screen-index.md` (UI-<플랫폼>-<ID>)
4. 요구사항 — `docs/requirements.md` (REQ-nnn)
5. 이 저장소 규칙 — `docs/conventions/code.md`, `docs/conventions/git.md`

## 기술 스택

| 영역 | 스택 | 위치 |
|---|---|---|
| iOS 앱 | Swift · SwiftUI · WidgetKit (DEC-002) | `apps/ios/` |
| Android 앱 | Kotlin · Jetpack Compose (DEC-002) | `apps/android/` |
| 두 플랫폼 공유 테스트 표 | JSON | `apps/shared/fixtures/` |
| 서버 | 미결정 — 지금은 기기 안 저장만 (DEC-003) | (나중에 `server/`) |
| 작성자 웹 · 운영 콘솔 | 미결정 — 2.0 · 운영 시작 전 | (나중에 `apps/web/`) |

아키텍처(계층 · 폴더 · Router · 에이전트 역할): `docs/conventions/architecture.md`. 폴더 · 이름 규칙: `docs/conventions/code.md`.

## 반드시

- **원문대로 만든다.** 디자인 · 문구 · 값은 기준 문서와 토큰 · 설정 값만 쓴다(하드코딩 금지). 다르게 만들어야 하면 멈추고 묻는다.
- **도메인 규칙 (DEC-006)**
  - 시간대는 Asia/Seoul 고정. 근무는 시작한 날에 속하고 **N은 다음 날 종료 시각까지 이어진다** — 다음 날이 OFF여도 아침은 근무 중.
  - **미등록 · 검토 중 · 모르는 코드는 OFF가 아니다.** 「정보 없음」과 「근무 없음」을 섞지 않는다.
  - 이름 · 병원 · 근무표 · 메모 등 개인정보를 로그 · 분석 이벤트에 남기지 않는다. 테스트 데이터는 가짜만.
  - 서버가 없어도 근무표 보기 · 알람이 동작한다. 로컬 저장이 원본이다.
  - 광고 알림은 따로 동의한 경우만, 야간(21–08시)은 별도 동의.
  - 약속 · 개인 일정은 자동으로 옮기지 않는다. 통계 · 그룹 근무는 「공식 기록 아님」을 밝힌다.
- **정한 아키텍처를 지킨다**(`docs/conventions/architecture.md`). 기존 패턴을 먼저 재사용하고, 새 구조 · 라이브러리는 임의로 들이지 않는다.
- **작업 단위는 이슈 하나.** 코드 · 커밋에 관련 REQ · DEC ID를 적는다.
- **완료 보고 전에 검증한다.** 실제로 실행한 빌드 · 테스트 명령과 결과를 적고, 실행하지 않았으면 "미실행"이라고 쓴다.
- 결과 보고 순서: 수행 / 검증 / 차단 / 내가 할 일 / 다음 단계.

## 금지

- 승인 없는 디자인 · 문구 변경, 요청과 무관한 리팩터링 · 이름 변경 · 포맷 일괄 변경
- 운영 데이터 수정 · 운영 배포 · 결제 · 권한 확대 — 사용자 확인 필수
- 비밀값 노출 — 키 · 토큰 · 비밀번호를 코드 · 로그 · 커밋 · 이슈에 쓰지 않는다. 변수 이름만 `.env.example`
- 검증 없는 "완료" 보고, 읽지 않은 자료를 읽었다고 하기
- `git push --force`, `git reset --hard`, 남의 미커밋 변경 삭제

## Git

전략 `github-flow` · 작업 기준 `main` · 배포 `main` (새 저장소 기본값 — `.claude/project.sh`). 항상 PR · 브랜치 `<type>/<이슈번호>-<slug>`. Conventional Commits. 상세: `docs/conventions/git.md`.

## 미결정 (정해지기 전에 임의로 정하지 않는다)

- **홈 시안** — 12a · 12b · 12c · 1a · 1b · 1c 중 하나 (원본 제안 12a). REQ-016 착수 전
- **하단 탭 이름 「공유」 vs 「함께」**, 1.0에서 계획 · 공유 탭에 들어갈 화면
- **서버** (Supabase · Firebase · 직접 · 서버 없이) — 로그인 · 백업 · 계정 삭제 · 운영 콘솔(REQ-002 · 028 · 037) 착수 전 (DEC-003)
- **최소 OS 버전** — iOS 무음 · 집중 모드에서도 울리는 알람(시스템 알람 기능)의 지원 범위 확인 후. Android minSdk
- **로컬 저장소 라이브러리** (iOS SwiftData · Core Data · SQLite / Android Room · DataStore), Android 패키지 이름, Android DI(기본 수동)
- **디자인 토큰을 코드로 옮기는 방식** (손으로 · JSON에서 생성)
- **병원 통계 공개 기준 20명 vs 10명** (1.3 전)
- 야간 광고 알림 동의 · 약관 — 법률 검토
- 2.0 병동 기능 유료 여부 · 결제 시점
