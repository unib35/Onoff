# 프로젝트 설정 — 스킬 · hook · 검증 스크립트가 모두 이 파일 하나를 읽는다(sh로 source).
# 프로젝트마다 다른 값은 여기에만 둔다. 스크립트 본체는 고치지 않는다.
# 처음 채우기: Claude Code에서 /project-setup

# 세션 시작 hook 출력 앞에 붙는 짧은 이름(영어 소문자)
PROJECT_TAG="onoff"

# GitHub 저장소 owner/name. 비우면 `gh repo view`로 알아낸다.
GH_REPO="unib35/Onoff"

# Git 전략 · 컨벤션 — 설치할 때 기존 저장소(브랜치 · 커밋 이력 · commitlint 등)에서 감지한 값.
# 바꾸려면 docs/conventions/git.md도 함께(/project-setup). 이미 쓰는 도구가 있으면 그 도구가 기준이다.
#   github-flow: 기본 브랜치 하나에서 작업 브랜치 → PR
#   git-flow:    develop에서 작업 브랜치 → PR, 배포 브랜치(main)는 release · hotfix로만
#   trunk:       기본 브랜치에 작은 커밋을 바로(브랜치는 선택)
GIT_STRATEGY="github-flow"
BASE_BRANCH="main"         # 작업 브랜치를 만들고 PR을 보내는 곳
RELEASE_BRANCH="main"   # 배포 브랜치 (github-flow · trunk면 BASE와 같음)
# 1: BASE_BRANCH에 직접 push 허용(git.md 조건) · 0: 항상 PR  (trunk는 1)
DIRECT_PUSH="0"

# 브랜치 컨벤션
BRANCH_TYPES="feat fix docs chore"       # 허용 접두어(공백 구분). hotfix · release는 RELEASE_BRANCH에서 갈라짐
ISSUE_STYLE="github"         # github: <type>/<번호>-<slug> · jira: <type>/<ABC-123>-<slug> · none: <type>/<slug>
BRANCH_REGEX=''       # 비우면 위 값으로 만든다. 기존 규칙이 특이하면 정규식(ERE)을 직접

# 커밋 컨벤션
COMMIT_STYLE="conventional"       # conventional · gitmoji · jira(ABC-123: …) · free(형식 검사 안 함)
COMMIT_TYPES="feat fix docs refactor test chore ci perf style build revert"       # conventional일 때 허용 type
COMMIT_SCOPE="optional"       # optional · required
COMMIT_LANG="ko"         # ko: 요약에 한글 필수 · any: 검사 안 함
COMMIT_TOOL=""         # 감지한 기존 도구(commitlint · husky 등). 있으면 그 설정이 기준

# 기획 원본 — /project-setup · /design-sync 가 읽는다. 둘 다 비면 대화로 기획 초안을 만든다.
# Claude Design 프로젝트 링크 (https://claude.ai/design/p/<id>)
DESIGN_URL="https://claude.ai/design/p/0397bbf3-8476-4802-8de8-86d2e42bc216"
# 로컬 기획 문서 경로(저장소 기준, 공백 구분). 예: "docs/spec"
SPEC_PATHS=""

# 이슈 본문에서 뽑아 안내할 연결 ID (grep -E). 예: REQ-012 · DEC-003 · UI-IOS-10t
# 화면 ID: UI-<IOS|AND|WEB|WRT|OPS|PRT>-<원본 ID> (docs/design/screen-index.md). 예: UI-IOS-16a · UI-AND-1c · UI-PRT-grid
REF_PATTERN='(REQ-[0-9]{3}|DEC-[0-9]{3}|UI-[A-Z]{3}-([0-9]+[a-z]*|[a-z]+))'

# 연결 ID 접두어 → 찾을 문서 (공백으로 구분, "접두어=경로")
REF_DOCS="REQ=docs/requirements.md DEC=docs/decisions.md UI=docs/design/screen-index.md"

# 바뀐 경로 → 검증 영역. 한 줄에 "정규식(ERE, 공백 없이) 영역". 위에서부터 첫 일치.
# 아무 줄에도 안 맞으면 영역 other.
AREAS='
^apps/ios/        ios
^apps/android/    android
^apps/shared/     shared
^\.claude/        claude
^\.github/        claude
^docs/            docs
\.md$             docs
'

# 영역별 검증 — verify_<영역> 함수가 있으면 실행, 없으면 SKIP으로 보고한다.
# 종료 코드 0 = PASS. 출력은 로그 파일로 간다. 없는 명령을 성공 처리하지 않는다.
# 예시(주석 해제 후 수정):
# verify_web()  { npm --prefix apps/web test --silent && npm --prefix apps/web run typecheck --silent; }
# verify_ios()  { xcodebuild test -quiet -project App/App.xcodeproj -scheme App \
#                   -destination "platform=iOS Simulator,name=${SIM:-iPhone 17}" -parallel-testing-enabled NO; }
# verify_api()  { (cd server && go test ./...); }
#
# iOS — XcodeGen으로 프로젝트를 만든 뒤 단위 테스트(DEC-010). 시뮬레이터는 SIM으로 바꾼다.
# 기본은 이 프로젝트 전용 「Onoff iPhone 17」(다른 앱이 쓰는 시뮬레이터를 건드리지 않게), 없으면 「iPhone 17」.
verify_ios() {
  sim=${SIM:-}
  if [ -z "$sim" ]; then
    if xcrun simctl list devices available | grep -q "Onoff iPhone 17 ("; then sim="Onoff iPhone 17"; else sim="iPhone 17"; fi
  fi
  (cd apps/ios && xcodegen generate --quiet && xcodebuild test -quiet -project Onoff.xcodeproj -scheme Onoff \
    -destination "platform=iOS Simulator,name=$sim" -parallel-testing-enabled NO \
    -derivedDataPath "${TMPDIR:-/tmp}/onoff-ios-dd")
}
# Android — 코드가 아직 없어 정의하지 않는다(SKIP으로 보고). Android 뼈대 이슈에서 주석을 푼다.
# verify_android() { (cd apps/android && ./gradlew --quiet testDebugUnitTest); }
verify_shared()  { for f in apps/shared/fixtures/*.json; do [ -f "$f" ] || continue; jq empty "$f" || return 1; done; }

# 아키텍처 검사 — 프리셋 clean-apple-swiftui · clean-android-compose (DEC-004). docs/conventions/architecture.md
# check.sh가 코드 영역을 찾으면 verify.sh <영역> arch 로 함께 돌린다. 코드가 없으면 통과.
verify_arch() {
  bad=0
  if [ -d apps/ios ]; then
    # Domain은 UI · 네트워크 · OS 알람 · 위젯을 모른다
    grep -rlE '^import (SwiftUI|UIKit|AppKit|AlarmKit|WidgetKit|SwiftData|CoreData|UserNotifications)' --include=*.swift apps/ios 2>/dev/null | grep '/Domain/' && bad=1
    grep -rlE 'URLSession|JSONDecoder' --include=*.swift apps/ios 2>/dev/null | grep '/Domain/' && bad=1
    # 화면은 Data 계층을 직접 쓰지 않는다
    grep -rlE 'Live[A-Za-z]*Repository|URLSession' --include=*.swift apps/ios 2>/dev/null | grep '/Presentation/' && bad=1
    # View가 내비게이션 경로를 직접 만지지 않는다
    grep -rlE 'NavigationPath\(|\.append\(.*Route' --include=*View.swift apps/ios 2>/dev/null | grep '/Presentation/' && bad=1
  fi
  if [ -d apps/android ]; then
    grep -rlE '^import (android\.|androidx\.|retrofit2|io\.ktor)' --include=*.kt apps/android 2>/dev/null | grep '/domain/' && bad=1
    grep -rlE 'Default[A-Za-z]*Repository|Retrofit|HttpClient|AlarmManager' --include=*.kt apps/android 2>/dev/null | grep '/presentation/' && bad=1
    grep -rlE 'NavController' --include=*Screen.kt apps/android 2>/dev/null | grep '/presentation/' && bad=1
  fi
  [ $bad -eq 0 ]
}
