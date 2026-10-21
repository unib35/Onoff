# 공통 함수 — 스크립트가 source 한다. 수정 대신 .claude/project.sh를 고친다.
# 사용 전 현재 디렉터리가 저장소 루트여야 한다.

_unset_placeholder() { case "$1" in "{{"*) echo "";; *) echo "$1";; esac; }

load_project() {
  [ -f .claude/project.sh ] || { echo "중단: .claude/project.sh 없음" >&2; return 1; }
  PROJECT_TAG="" GH_REPO="" GIT_STRATEGY="" BASE_BRANCH="" RELEASE_BRANCH="" DIRECT_PUSH=""
  BRANCH_TYPES="" ISSUE_STYLE="" ISSUE_IN_BRANCH="" BRANCH_REGEX=""
  COMMIT_STYLE="" COMMIT_TYPES="" COMMIT_SCOPE="" COMMIT_LANG="" COMMIT_TOOL=""
  DESIGN_URL="" SPEC_PATHS="" REF_PATTERN='(REQ-[0-9]{3}|DEC-[0-9]{3})' REF_DOCS="" AREAS=""
  . ./.claude/project.sh
  for v in PROJECT_TAG GH_REPO GIT_STRATEGY BASE_BRANCH RELEASE_BRANCH DIRECT_PUSH BRANCH_TYPES ISSUE_STYLE \
           ISSUE_IN_BRANCH BRANCH_REGEX COMMIT_STYLE COMMIT_TYPES COMMIT_SCOPE COMMIT_LANG COMMIT_TOOL DESIGN_URL SPEC_PATHS; do
    eval "$v=\$(_unset_placeholder \"\$$v\")"
  done
  GIT_STRATEGY=${GIT_STRATEGY:-github-flow}
  BASE_BRANCH=${BASE_BRANCH:-main}
  RELEASE_BRANCH=${RELEASE_BRANCH:-$BASE_BRANCH}
  if [ -z "$BRANCH_TYPES" ]; then
    [ "$GIT_STRATEGY" = git-flow ] && BRANCH_TYPES="feature bugfix hotfix release docs chore" || BRANCH_TYPES="feat fix docs chore"
  fi
  # 예전 설정(ISSUE_IN_BRANCH 1/0) 호환
  if [ -z "$ISSUE_STYLE" ]; then [ "$ISSUE_IN_BRANCH" = 0 ] && ISSUE_STYLE=none || ISSUE_STYLE=github; fi
  if [ -z "$DIRECT_PUSH" ]; then [ "$GIT_STRATEGY" = trunk ] && DIRECT_PUSH=1 || DIRECT_PUSH=0; fi
  COMMIT_STYLE=${COMMIT_STYLE:-conventional}
  COMMIT_TYPES=${COMMIT_TYPES:-feat fix docs refactor test chore ci perf style build revert}
  COMMIT_SCOPE=${COMMIT_SCOPE:-optional}
  COMMIT_LANG=${COMMIT_LANG:-ko}
  [ -n "$GH_REPO" ] || GH_REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || true)
  [ -n "$PROJECT_TAG" ] || PROJECT_TAG=$(basename "$PWD" | tr 'A-Z' 'a-z')
}

# 브랜치 이름 형식(ERE)
branch_regex() {
  [ -n "$BRANCH_REGEX" ] && { echo "$BRANCH_REGEX"; return; }
  types=$(printf '%s' "$BRANCH_TYPES" | tr -s ' ' '|')
  rel='|^release/v?[0-9a-z]+([.-][0-9a-z]+)*$'   # release/1.2.0 는 이슈 없이도 허용
  case "$ISSUE_STYLE" in
    github) echo "^($types)/[0-9]+-[a-z0-9]+([-.][a-z0-9]+)*\$$rel" ;;
    jira)   echo "^($types)/[A-Z][A-Z0-9]+-[0-9]+(-[a-z0-9]+)*\$$rel" ;;
    *)      echo "^($types)/([0-9]+-)?[a-z0-9]+([-.][a-z0-9]+)*\$$rel" ;;
  esac
}

# 커밋 요약 한 줄 검사 → 문제가 있으면 이유를 출력하고 1
commit_problem() {
  s=$1
  case "$COMMIT_STYLE" in
    conventional)
      types=$(printf '%s' "$COMMIT_TYPES" | tr -s ' ' '|')
      if [ "$COMMIT_SCOPE" = required ]; then re="^($types)\\([a-z0-9._/-]+\\)!?: .+"; else re="^($types)(\\([a-z0-9._/-]+\\))?!?: .+"; fi
      echo "$s" | grep -Eq "$re" || { echo "형식 아님(<type>$( [ "$COMMIT_SCOPE" = required ] && echo '(<scope>)' || echo '[(scope)]'): 요약, type: $COMMIT_TYPES)"; return 1; } ;;
    gitmoji)
      printf '%s' "$s" | perl -CS -ne 'exit(/^(:[a-z0-9_+-]+:|[\x{1F000}-\x{1FAFF}\x{2600}-\x{27BF}])/ ? 0 : 1)' || { echo "gitmoji로 시작하지 않음"; return 1; } ;;
    jira)
      echo "$s" | grep -Eq '^\[?[A-Z][A-Z0-9]+-[0-9]+\]?[: ]' || { echo "이슈 키(ABC-123)로 시작하지 않음"; return 1; } ;;
    *) return 0 ;;
  esac
  if [ "$COMMIT_LANG" = ko ] && ! printf '%s' "$s" | perl -CS -ne 'exit(/\p{Hangul}/ ? 0 : 1)'; then echo "요약이 한국어 아님"; return 1; fi
  [ "$(printf '%s' "$s" | perl -CS -ne 'print length')" -gt 72 ] && { echo "요약 72자 초과"; return 1; }
  echo "$s" | grep -q '\.$' && { echo "요약 끝 마침표"; return 1; }
  return 0
}

# 브랜치 종류 → 갈라질 곳 · PR 보낼 곳
target_of() {
  case "${1%%/*}" in
    hotfix|release) echo "$RELEASE_BRANCH" ;;
    *) echo "$BASE_BRANCH" ;;
  esac
}

# 파일 경로(표준 입력, 줄마다) → 영역 이름(공백 구분, 중복 없음)
areas_of() {
  printf '%s\n' "$AREAS" | awk 'NF==2 { print }' > "${TMPDIR:-/tmp}/areas.$$"
  awk -v rules="${TMPDIR:-/tmp}/areas.$$" '
    BEGIN { while ((getline l < rules) > 0) { split(l, p, /[ \t]+/); n++; re[n]=p[1]; ar[n]=p[2] } }
    NF { hit="other"; for (i=1; i<=n; i++) if ($0 ~ re[i]) { hit=ar[i]; break } a[hit]=1 }
    END { for (k in a) printf "%s ", k }'
  rm -f "${TMPDIR:-/tmp}/areas.$$"
}
