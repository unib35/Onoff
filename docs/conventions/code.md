# 코드 규칙 — 폴더 · 이름 · 오류 · 테스트

`AGENTS.md`의 세부 내용이다. 실제와 달라지면 이 문서를 먼저 고친다.

## 폴더 구조

기능 중심 · 계층 구조는 `docs/conventions/architecture.md`가 원본이다. 여기에는 실제 경로만 적는다.

```
apps/ios/Onoff/{App,Core/DesignSystem,Core/Domain}/
apps/ios/Onoff/Features/<Feature>/{Presentation,Domain,Data}/
apps/ios/OnoffWidget/
apps/ios/OnoffTests/Features/<Feature>/
apps/android/app/src/main/java/<pkg>/{app,core/designsystem,core/domain}/
apps/android/app/src/main/java/<pkg>/features/<feature>/{presentation,domain,data}/
apps/android/app/src/test/java/<pkg>/features/<feature>/
apps/shared/fixtures/<규칙>.json        두 플랫폼 Domain 테스트가 같이 읽는 테스트 표
```
iOS는 이슈 #3에서 위 경로로 만들었다(`apps/ios/project.yml` → `xcodegen generate`, `.xcodeproj`는 커밋 안 함 — DEC-010). Android는 아직 없다. `<pkg>`는 미결정.
- 공통 컴포넌트 · 설정은 한 곳에 두고 「공통 파일」로 취급한다(`docs/conventions/agents.md`).

## 이름

| 대상 | iOS (Swift) | Android (Kotlin) |
|---|---|---|
| 타입 · 파일 | `UpperCamelCase`, 파일 하나에 주 타입 하나, 파일 이름 = 타입 이름 | 같음 |
| 함수 · 변수 | `lowerCamelCase` | 같음 |
| 패키지 · 폴더 | 기능 폴더 `UpperCamelCase` (`Features/ShiftInput`) | 소문자 (`features/shiftinput`) |
| 화면 | `<Screen>View` + `<Screen>ViewModel` | `<Screen>Screen` + `<Screen>Route` + `<Screen>ViewModel` |
| UseCase | `<Verb><Noun>UseCase` — 두 플랫폼 같은 이름 | 같음 |
| Repository | `<Name>Repository`(Domain) · `Live<Name>Repository` · `InMemory<Name>Repository` | `<Name>Repository` · `Default<Name>Repository` · `Fake<Name>Repository` |
| 테스트 | `<대상>Tests` | `<대상>Test` |

- 화면 코드에는 화면 ID를 함께 적는다: `// REQ-020 · UI-IOS-16a`.
- 근무 코드(D · E · N · OFF)는 사용자가 정하는 값이다. 코드에서 특정 코드 문자열로 분기하지 않고 근무 유형의 속성(종류 · 시각)으로 판단한다.

- 파일 머리에 관련 ID를 적는다: `// REQ-012`.

## 값 · 토큰

- 색 · 간격 · 글자 · 시간 같은 값은 토큰 · 설정 이름으로만 쓴다. 화면 코드에 숫자를 직접 쓰지 않는다.
- 생성물은 손으로 고치지 않는다.

## 오류 처리

- 화면 상태: 로딩 · 빈 · 오류 · 오프라인 · 권한 없음을 구분한다.
- 사용자에게 보이는 문구는 기준 문서 문구를 쓴다. 내부 오류 메시지 · 스택을 화면에 보이지 않는다.
- 오류를 삼키지 않는다. 잡으면 기록하거나 사용자에게 알린다.
- 로그에 개인정보 · 토큰을 남기지 않는다.
- 되돌리기 어려운 동작은 확인 단계를 거친다.

## 테스트

| 대상 | 최소 기준 | 명령 (`.claude/project.sh` verify_<영역>) |
|---|---|---|
| iOS Domain · ViewModel | 규칙마다 단위 테스트(Swift Testing), 공유 테스트 표 통과 | `verify_ios` — XcodeGen 생성 후 `xcodebuild test` (시뮬레이터 `SIM`, 기본 「Onoff iPhone 17」) |
| Android Domain · ViewModel | 같음 | `verify_android` — 미실행(코드 없음, 뼈대 이슈에서 추가) |
| 알람 실제 동작 | 1.0 출시 조건(REQ-036)을 기기에서 수동 확인, 결과를 PR에 붙임 | 수동 |
| 아키텍처 | 의존 방향 grep | `verify_arch` |

- 테스트 데이터는 가짜만 쓴다(실제 이름 · 번호 · 계좌 금지).
- 보고에는 실행한 명령과 결과를 그대로 붙인다. 못 돌렸으면 "미실행"과 이유.
- 검사를 약하게 만들어 통과시키지 않는다(테스트 삭제 · 기대값 변경 · `continue-on-error` 금지).
