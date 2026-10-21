#!/bin/sh
# start-feature: 이슈 확인 → 갈라질 브랜치 최신화 → 작업 브랜치 생성.
# 사용: start.sh <type> <issue|-> <slug>
#   type  = .claude/project.sh BRANCH_TYPES 중 하나 (예: feat · fix / feature · bugfix · hotfix)
#   issue = ISSUE_STYLE=github: GitHub 이슈 번호 · jira: 이슈 키(ABC-123) · none: "-"(번호를 줘도 됨)
#   slug  = 영어 소문자·숫자·하이픈, 2–5단어 (release는 버전 1.2.0도 가능)
# 갈라질 곳: hotfix · release → RELEASE_BRANCH, 나머지 → BASE_BRANCH
# 종료 코드: 0 성공 · 1 입력 오류 · 2 작업 트리 변경 있음 · 3 이슈 문제 · 4 git 실패
set -u
cd "$(git rev-parse --show-toplevel)" || exit 4
. ./.claude/lib.sh && load_project || exit 1

if [ $# -ne 3 ]; then
  echo "사용: start.sh <$(echo "$BRANCH_TYPES" | tr ' ' '|')> <issue|-> <slug>" >&2; exit 1
fi
type=$1 issue=$2 slug=$3

echo " $BRANCH_TYPES " | grep -q " $type " || { echo "type은 $BRANCH_TYPES 중 하나: $type" >&2; exit 1; }
case "$ISSUE_STYLE:$issue" in
  *:-) [ "$type" = release ] || [ "$ISSUE_STYLE" = none ] || { echo "이 저장소는 브랜치에 이슈($ISSUE_STYLE)가 필요하다 — .claude/project.sh ISSUE_STYLE" >&2; exit 1; } ;;
  jira:*) echo "$issue" | grep -Eq '^[A-Z][A-Z0-9]+-[0-9]+$' || { echo "issue는 Jira 키(ABC-123): $issue" >&2; exit 1; } ;;
  *) echo "$issue" | grep -Eq '^[1-9][0-9]*$' || { echo "issue는 숫자 또는 -: $issue" >&2; exit 1; } ;;
esac
if [ "$type" = release ]; then
  echo "$slug" | grep -Eq '^[a-z0-9]+([-.][a-z0-9]+)*$' || { echo "release 이름 형식 오류: $slug" >&2; exit 1; }
else
  echo "$slug" | grep -Eq '^[a-z0-9]+(-[a-z0-9]+){1,4}$' || { echo "slug는 소문자·숫자·하이픈 2–5단어: $slug" >&2; exit 1; }
fi

if [ "$issue" = - ]; then branch="$type/$slug"; else branch="$type/$issue-$slug"; fi
echo "$branch" | grep -Eq "$(branch_regex)" || { echo "브랜치 이름이 이 저장소 규칙과 다름: $branch (규칙 $(branch_regex))" >&2; exit 1; }
from=$(target_of "$branch")

# 1. 커밋하지 않은 변경이 있으면 멈춘다(브랜치 전환 시 변경이 따라가거나 충돌하므로).
dirty=$(git status --porcelain)
if [ -n "$dirty" ]; then
  echo "중단: 커밋하지 않은 변경이 있다. 정리 방법은 사용자가 정한다(커밋 · stash · 그대로 두기)." >&2
  echo "$dirty" | head -20 >&2
  exit 2
fi

# 2. GitHub 이슈가 있고 열려 있는지 (jira 키는 확인하지 않는다)
info=""
if [ "$issue" != - ] && [ "$ISSUE_STYLE" != jira ]; then
  [ -n "$GH_REPO" ] || { echo "중단: GitHub 저장소를 모름 — .claude/project.sh GH_REPO" >&2; exit 3; }
  info=$(gh issue view "$issue" -R "$GH_REPO" --json number,title,state,labels,body 2>&1) || {
    echo "중단: 이슈 #$issue 조회 실패 — $info" >&2; exit 3; }
  state=$(printf '%s' "$info" | jq -r .state)
  [ "$state" = "OPEN" ] || { echo "중단: 이슈 #$issue 상태가 $state" >&2; exit 3; }
fi

# 3. 같은 이름 브랜치가 이미 있으면 멈춘다
if git show-ref --verify --quiet "refs/heads/$branch"; then
  echo "중단: 브랜치 $branch 가 이미 있다. 이어서 하려면 git switch $branch" >&2; exit 4
fi

# 4. 갈라질 브랜치를 최신으로 받고 거기서 생성
git switch "$from" >/dev/null 2>&1 || { echo "중단: $from 전환 실패(로컬에 없으면: git switch -c $from origin/$from)" >&2; exit 4; }
if git remote get-url origin >/dev/null 2>&1 && git fetch -q origin "$from" 2>/dev/null; then
  git merge --ff-only -q "origin/$from" 2>/dev/null || { echo "중단: $from 을 origin/$from 으로 fast-forward 못 함(로컬이 갈라졌을 수 있음)" >&2; exit 4; }
fi
git switch -c "$branch" >/dev/null || exit 4

# 5. 결과 출력(짧게)
echo "branch: $branch (from: $from @ $(git rev-parse --short HEAD) · PR 대상: $from)"
if [ -n "$info" ]; then
  printf '%s' "$info" | jq -r '"issue: #\(.number) \(.title)  labels: \([.labels[].name] | join(",") | if . == "" then "-" else . end)"'
  ids=$(printf '%s' "$info" | jq -r .body | grep -Eo "$REF_PATTERN" | sort -u | tr '\n' ' ')
  echo "refs: ${ids:--(이슈 본문에 연결 ID 없음)}"
  [ -n "$REF_DOCS" ] && echo "ref-docs: $REF_DOCS"
else
  [ "$issue" = - ] && echo "issue: -(이슈 없이 시작)" || echo "issue: $issue ($ISSUE_STYLE — GitHub에서 확인하지 않음)"
fi
[ "$GIT_STRATEGY" = git-flow ] && [ "$from" = "$RELEASE_BRANCH" ] && echo "note: $type 은 $RELEASE_BRANCH 에 병합한 뒤 $BASE_BRANCH 에도 되돌려 병합해야 한다(git.md)"
exit 0
