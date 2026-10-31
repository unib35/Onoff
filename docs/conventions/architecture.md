# 아키텍처 — Feature-based Lightweight Clean Architecture

결정: DEC-004 (후보 B). 앱은 네이티브 둘(DEC-002), 지금은 기기 안 저장만(DEC-003), 위치는 `apps/ios` · `apps/android`(DEC-005).
무거운 프레임워크(TCA · Redux 계열 등)는 쓰지 않는다. 기존 코드는 아직 없다 — 이 문서가 첫 구조다.

```text
View (화면)
    ↓
ViewModel (화면 상태)
    ↓
UseCase (비즈니스 로직)
    ↓
Repository (데이터 접근 추상화)
    ↓
로컬 저장소 (지금) · 서버 API (DEC-003 이후)
```

| 구성 | 맡는 일 |
|---|---|
| MVVM | UI와 화면 상태 분리 |
| UseCase | 도메인 규칙 · 계산 — **근무 시각 계산(N 날짜 넘김) · 알람 예약 계획(2주치 · 근무 변경 시 옮기기 · 나이트 다음 날 낮 끄기) · 입력 초안 적용 · 되돌리기 · 변경 영향** |
| Repository | 로컬 저장소(지금) · 서버(나중) 접근 추상화. 인터페이스는 Domain, 구현은 Data. 서버를 붙여도 Repository 구현만 바뀐다 |
| DI | 의존성 주입 — 조립은 앱 진입점 한 곳 |
| Router | 내비게이션 관리 — View는 목적지만 요청한다 |
| State Machine | 상태 전이: 입력 초안(편집 중 → 적용 → 되돌림), 알람 권한(허용 · 거부 · 제한), 2.0 근무 교환(요청 → 수락 → 승인 → 반영 · 거절 · 취소) |
| 시스템 연결 | 알람 · 위젯 · 알림 같은 OS 기능은 Data 계층의 구현으로 둔다(예: `AlarmScheduler` 인터페이스는 Domain, 구현은 Data). Domain은 OS API를 모른다 |

## 의존 방향 (어기면 아키텍처 위반)

- View → ViewModel → UseCase → Repository(인터페이스). 반대 방향 · 건너뛰기 금지.
- **View · ViewModel에 비즈니스 로직을 넣지 않는다.** 근무 시각 · 알람 시각 계산, 미등록/OFF 판정, 상태 전이는 UseCase · State Machine.
- Domain(UseCase · Entity · State Machine · Repository 인터페이스)은 UI 프레임워크 · 네트워크 · DB · OS 알람 라이브러리를 import하지 않는다 — 순수 코드로 단위 테스트한다.
- Data(Repository 구현 · 저장소 · DTO · 시스템 연결)는 저장 모델을 Domain Entity로 바꿔서 넘긴다. 저장 모델이 화면까지 올라가지 않는다.
- View는 내비게이션 구조(스택 · 경로)를 직접 만지지 않고 `router.navigate(.목적지)`만 부른다.
- 날짜 · 시각은 Domain에서 Asia/Seoul 기준으로 다룬다(DEC-006). 「지금 시각」은 `Clock` 같은 주입 가능한 의존으로 받아 테스트에서 고정한다.

## 폴더

기술 계층보다 **기능(Feature) 중심**으로 나눈다. 기능 안에서 계층을 나눈다.

### iOS — `apps/ios/`

```text
apps/ios/
├── project.yml                        XcodeGen 정의 (공통 파일 · .xcodeproj는 생성물 — DEC-010)
├── Onoff/
│   ├── App/                           진입점 · AppContainer(DI) · AppRouter · AppRoute   (공통 파일)
│   ├── Core/
│   │   ├── DesignSystem/              토큰 · 공통 컴포넌트(근무 칩 · 시간 띠 · 토스트)     (공통 파일)
│   │   └── Domain/                    여러 기능이 같이 쓰는 Entity · Repository 인터페이스 (공유 도메인)
│   └── Features/<Feature>/
│       ├── Presentation/              <Screen>View · <Screen>ViewModel · <Feature>Route
│       ├── Domain/                    UseCase · Entity · State Machine · Repository 인터페이스
│       └── Data/                      Live<Name>Repository · 저장 모델 · 시스템 연결
├── OnoffWidget/                       WidgetKit 확장 (App Group으로 같은 저장소를 읽기만)
└── OnoffTests/Features/<Feature>/     Domain · ViewModel 테스트
```

### Android — `apps/android/`

```text
apps/android/
├── settings.gradle.kts · build.gradle.kts · gradle/   (공통 파일)
└── app/src/
    ├── main/java/<pkg>/
    │   ├── app/                       Application · AppContainer(DI) · AppRouter · AppRoute (공통 파일)
    │   ├── core/designsystem/         토큰 · 공통 컴포저블                                 (공통 파일)
    │   ├── core/domain/               공유 Entity · Repository 인터페이스                  (공유 도메인)
    │   └── features/<feature>/
    │       ├── presentation/          <Screen>Screen · <Screen>Route · <Screen>ViewModel
    │       ├── domain/                UseCase · Entity · State Machine · Repository 인터페이스
    │       └── data/                  Default<Name>Repository · 저장 모델 · 시스템 연결
    └── test/java/<pkg>/features/<feature>/   Domain · ViewModel 테스트
```

`<pkg>`(패키지 이름)는 미결정 — 프로젝트 뼈대 이슈에서 정한다.

### 두 플랫폼이 같은 규칙을 지키게

- 근무 시각 · 알람 계획 같은 규칙은 **같은 테스트 표**로 검사한다: `apps/shared/fixtures/<규칙>.json`(입력 → 기대 결과). iOS · Android Domain 테스트가 같은 파일을 읽는다. 규칙을 바꾸면 이 파일부터 고친다.
- 이름도 맞춘다: 같은 UseCase는 두 플랫폼에서 같은 이름(`PlanAlarmsUseCase` 등).

### 기능 목록

버전은 로드맵 2026-10-22 기준. 1.0은 기록만 — 알람 · 위젯은 1.1.

| Feature | 화면 (screen-index) | 핵심 도메인 | 버전 | REQ |
|---|---|---|---|---|
| `Onboarding` | 15a · 15b · 15d (15c는 1.1) | 처음 실행 · 첫 홈 두 단계 | 1.0 | 001–004 |
| `ShiftType` | 1d · 5b · 5c | 근무 유형 · 시각 · 날짜 넘김 | 1.0 | 005–007 |
| `ShiftInput` | 14a · 14b · 5a · 11b · 11c (11a · 11d는 1.2) | 입력 초안 · 되돌리기 한 줄 · 순서 반복 · 지난달 복사 | 1.0 | 009–015 |
| `Roster` | 1f · 3c · 1l (1g는 1.1) | 월간 근무표 · 미등록 판정 · 변경 이력 | 1.0 | 008 · 017 · 018 · 026 |
| `Home` | 12a | 오늘 · 내일 · 다음 OFF · 이번 주 | 1.0 | 016 |
| `Memo` | 4b | 빠른 메모 | 1.0 | 019 |
| `Settings` | 15e · 15f | 계정 · 데이터(서버 결정 후) | 1.0 | 028 |
| `AppStatus` | 19c · 19f | 오프라인 · 업데이트 필요 | 1.0 | 029 · 030 |
| `Alarm` | 16a–16c · 1m · 1g · AND 1c · 1d · 1f | 알람 예약 계획 · 근무 변경 시 옮기기 · 권한 상태 | 1.1 | 020–025 · 033 · 111 |
| `Widget` | 3e · AND 1b | 오늘 · 내일 요약(읽기 전용) | 1.1 | 027 · 035 |

1.0에서 숨기는 부분(REQ-038)은 화면을 따로 만들지 않고 같은 화면에서 기능 플래그(버전별 켜기)로 숨긴다 — 플래그 위치는 `App/`의 설정 한 곳.

공유 도메인(`Core/Domain` · `core/domain`): `ShiftType` · `DutyDay`(날짜별 근무 · 미등록 · 검토 중) · `ShiftTimeline`(실제 시각 구간) · `Clock`. 여러 기능이 쓰므로 바꿀 때는 계약 먼저(아래).
작은 기능은 `Domain/` · `Data/`를 만들지 않아도 된다. 필요해질 때 이 구조로 들인다.

## 내비게이션 — Router

```text
View
  └── router.navigate(.roster(.day(date)))
                ↓
             AppRouter
                ↓
       NavigationStack (iOS) · NavHost (Android)
```

- `AppRoute`는 기능별 Route를 감싼다: `AppRoute ├ OnboardingRoute ├ HomeRoute ├ RosterRoute ├ ShiftInputRoute ├ AlarmRoute ├ SettingsRoute`
- 탭 이름: 홈 · 근무표 · 계획 · 공유(DEC-009). 1.0은 홈 · 근무표 두 개, 공유는 1.2 · 계획은 1.3에 추가(DEC-011).
- 각 `<Feature>Route`는 그 기능 폴더에 두고, 목적지 → 화면 생성을 맡는다.
- `AppRouter`는 스택 · 탭 · 시트 · 뒤로 가기(`navigate` · `back` · `backToRoot` · `replace`)만 다룬다.

## 에이전트 오케스트레이션

한 에이전트가 모든 일을 하지 않고 **Orchestrator + 계층별 에이전트**로 나눈다(정의: `.claude/agents/`, 규칙: `docs/conventions/agents.md`).

| 역할 | 맡는 일 | 소유 경로 |
|---|---|---|
| Orchestrator | 요구사항 · 기존 코드 분석, 작업 분해, **계약(인터페이스) 먼저 확정**, 배정, 통합, 최종 검증 | 공통 파일 (`App/` · `Core/DesignSystem` · 프로젝트 · 설정 · 문서) |
| feature-agent | View, ViewModel, 기능 컴포넌트, `<Feature>Route` 연결 | `Features/<F>/Presentation/` · `features/<f>/presentation/` + 그 테스트 |
| domain-agent | UseCase, 규칙, State Machine, Entity, Repository 인터페이스, Domain 단위 테스트, 공유 테스트 표 | `Features/<F>/Domain/` · `features/<f>/domain/` · `Core/Domain` · `core/domain` · `apps/shared/fixtures/` + 그 테스트 |
| data-agent | Repository 구현, 로컬 저장소, 시스템 연결(알람 · 위젯 · 알림) | `Features/<F>/Data/` · `features/<f>/data/` · `OnoffWidget/` + 그 테스트 |
| reviewer | 아키텍처 위반 · 회귀 · 원문 불일치 · 빠진 테스트 (읽기 전용) | — |
| 빌드 · 테스트 실행 | `verify.sh` (스크립트, AI가 아님) | — |

- 플랫폼도 나눌 수 있다: 같은 기능의 iOS · Android는 소유 경로가 달라 병렬 가능. 단, 같은 기능은 **Domain 계약(이름 · 테스트 표)을 먼저 한 번** 정하고 두 플랫폼이 따른다.

## 운영 원칙

- 모든 에이전트는 이 문서와 기존 코드를 먼저 확인하고, **기존 패턴을 먼저 재사용**한다.
- 새 아키텍처 · 라이브러리를 임의로 들이지 않는다(필요하면 멈추고 DEC 초안으로 묻는다). 로컬 저장소는 DEC-013(iOS SwiftData · Android Room). 아직 정하지 않은 것: Android minSdk · Android DI(기본은 수동 `AppContainer`) — `AGENTS.md` 미결정.
- 병렬은 **소유 경로가 겹치지 않을 때만**. 한 기능을 나눌 때 순서: ① domain-agent가 Entity · UseCase · Repository 인터페이스 · 테스트 표를 먼저 커밋(계약) → ② feature-agent · data-agent가 그 계약에 맞춰 병렬 → ③ 오케스트레이터가 DI · Route 조립.
- 모델: 단순 화면 · 데이터 연결은 sonnet, 복잡한 Domain(알람 계획 · 날짜 넘김) · State Machine · 리뷰는 opus, 조회는 haiku.

## 플랫폼별 구현

### iOS — Swift · SwiftUI

| 구성 | 구현 |
|---|---|
| View | SwiftUI `View`. 상태는 ViewModel에서 받고, 사용자 행동은 ViewModel 메서드 호출 |
| ViewModel | `@MainActor @Observable final class <Screen>ViewModel` — UseCase를 생성자 주입. 화면 상태(`state`)와 행동 메서드만 |
| UseCase | `struct` 또는 `final class`, `func callAsFunction(...) async throws -> T` 또는 이름 있는 메서드. SwiftUI · UIKit · 네트워킹 · AlarmKit · WidgetKit import 금지 |
| Repository | Domain: `protocol <Name>Repository: Sendable`. Data: `final class Live<Name>Repository` · 테스트: `InMemory<Name>Repository` |
| DI | `App/AppContainer.swift` 하나에서 Live 구현 조립, `@Environment`로 내려준다. 프리뷰 · 테스트는 InMemory 구현 |
| Router | `@MainActor @Observable final class AppRouter` + `NavigationStack(path:)`. `enum AppRoute: Hashable { case roster(RosterRoute) … }`, 기능별 `enum <F>Route: Hashable` + `@ViewBuilder func view(router:)` |
| State Machine | `enum <Name>State` + `func transition(_ event:) throws -> <Name>State` — 허용 안 되는 전이는 오류 |
| 테스트 | Domain · ViewModel: Swift Testing(`@Test`). UI: XCUITest(핵심 흐름만) |

### Android — Kotlin · Jetpack Compose

| 구성 | 구현 |
|---|---|
| View | `@Composable fun <Screen>Screen(state, onAction)` — 상태를 받아 그리기만. `<Screen>Route` Composable이 ViewModel을 연결 |
| ViewModel | `class <Screen>ViewModel(...) : ViewModel()` — `StateFlow<UiState>` 노출, 행동은 `fun onAction(action)`. UseCase 생성자 주입 |
| UseCase | `class <Verb><Noun>UseCase(private val repo: …) { suspend operator fun invoke(...): T }` — `android.*` · Compose · Room import 금지 |
| Repository | Domain: `interface <Name>Repository`. Data: `class Default<Name>Repository` · 테스트: `Fake<Name>Repository` |
| DI | 수동 `AppContainer`(Application에서 생성). Hilt · Koin 도입은 DEC로 결정 |
| Router | Navigation Compose `NavHost` + `sealed interface AppRoute`(type-safe `@Serializable` 목적지), 기능별 `<F>Route` + `NavGraphBuilder.<f>Graph(router)`. 화면은 `router.navigate(...)` 람다만 받는다 |
| State Machine | `sealed interface <Name>State` + `fun transition(event): <Name>State` — 허용 안 되는 전이는 예외 · `Result.failure` |
| 시스템 연결 | 알람 `AlarmManager`(정확한 알람) · 위젯 · 알림 채널은 `data/` 구현. Android 전용 화면(AND 1c · 1f · 1h)은 해당 기능의 `presentation/` |
| 테스트 | Domain · ViewModel: JUnit + kotlinx-coroutines-test. UI: Compose UI Test(핵심 흐름만) |

## 아키텍처 검사

`.claude/project.sh`의 `verify_arch` — `apps/ios` · `apps/android` 안에서 위 의존 방향을 grep으로 검사한다(코드가 없으면 통과).
