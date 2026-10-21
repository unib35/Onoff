#!/bin/sh
# finish-feature 사전 검사(읽기 전용): 브랜치 이름 · 미커밋 변경 · 커밋 메시지 · 비밀값 · 바뀐 영역.
# 사용: check.sh [base]   (기본 base = origin/<이 브랜치의 PR 대상> — hotfix · release는 RELEASE_BRANCH, 나머지는 BASE_BRANCH)
# 출력: 줄마다 OK|WARN|FAIL, 끝에서 두 번째 줄 "target: <PR 대상>", 마지막 줄 "areas: …"
# 종료 코드: 0 = FAIL 없음 · 1 = FAIL 있음
set -u
cd "$(git rev-parse --show-toplevel)" || exit 1
. ./.claude/lib.sh && load_project || exit 1
br=$(git rev-parse --abbrev-ref HEAD)
target=$(target_of "$br")
base=${1:-origin/$target}
git fetch -q origin "$target" 2>/dev/null || echo "WARN origin fetch 실패 — 로컬 $base 기준으로 검사"
git rev-parse -q --verify "$base" >/dev/null || base=$target
fail=0
ok()   { echo "OK   $*"; }
warn() { echo "WARN $*"; }
bad()  { echo "FAIL $*"; fail=1; }

# 1. 브랜치 (형식 · 직접 push 허용 여부는 .claude/project.sh)
if [ "$br" = "$BASE_BRANCH" ] || [ "$br" = "$RELEASE_BRANCH" ]; then
  if [ "$br" = "$BASE_BRANCH" ] && [ "$DIRECT_PUSH" = 1 ]; then warn "$br 브랜치 — 직접 push 예외(git.md 조건)일 때만"
  else bad "$br 에서 직접 작업하지 않는다($GIT_STRATEGY) — /start-feature로 작업 브랜치를 만든다"; fi
elif echo "$br" | grep -Eq "$(branch_regex)"; then ok "브랜치 $br → PR 대상 $target"
else bad "브랜치 이름 형식 아님: $br (규칙 $(branch_regex))"; fi
issue=""; [ "$ISSUE_STYLE" = github ] && issue=$(echo "$br" | sed -nE 's#^[a-z]+/([0-9]+)-.*#\1#p')

# 2. 미커밋 변경 — push되는 것은 커밋뿐이라 막지 않는다. 이 작업의 파일이 빠졌는지만 알린다.
n=$(git status --porcelain | wc -l | tr -d ' ')
[ "$n" -eq 0 ] && ok "작업 트리 깨끗함" || warn "커밋하지 않은 변경 ${n}개 — push에 안 들어감. 이 작업 파일이 빠지지 않았는지 확인"

# 3. 커밋 메시지 (base..HEAD)
commits=$(git rev-list --no-merges "$base..HEAD" 2>/dev/null | wc -l | tr -d ' ')
if [ "$commits" -eq 0 ]; then bad "$base 이후 커밋 없음"
else
  msgs=$(git log --no-merges --format='%h%x09%s' "$base..HEAD" | while IFS="$(printf '\t')" read -r h subj; do
    why=$(commit_problem "$subj") || echo "FAIL 커밋 $h $why: $subj"
  done)
  if [ -n "$msgs" ]; then echo "$msgs"; fail=1; else ok "커밋 ${commits}개 형식 통과($COMMIT_STYLE${COMMIT_TOOL:+ · 기존 도구 ${COMMIT_TOOL}도 기준})"; fi
  if [ -n "$issue" ] && ! git log --format=%B "$base..HEAD" | grep -Eq "(Refs|Closes|Fixes) #$issue\b"; then
    warn "커밋 꼬리말에 Refs/Closes #$issue 없음(PR 본문에 넣어도 됨)"
  fi
fi

# 4. 비밀값 — 추가된 줄만 검사. 값은 출력하지 않고 파일:패턴만 알린다.
hits=$(git diff "$base...HEAD" --unified=0 --no-color | perl -ne '
  if (/^\+\+\+ b\/(.*)/) { $f=$1; next }
  next unless /^\+/;
  for my $p ("gh[pousr]_[A-Za-z0-9]{20,}", "sk-[A-Za-z0-9_-]{20,}", "AKIA[0-9A-Z]{16}", "AIza[0-9A-Za-z_-]{30,}",
             "xox[baprs]-[A-Za-z0-9-]{10,}", "-----BEGIN [A-Z ]*PRIVATE KEY", "eyJ[A-Za-z0-9_-]{10,}\\.eyJ",
             "(?i)(password|passwd|secret|api_?key|service_role)[\"'\'' ]*[:=][\"'\'' ]*[^\"'\'' ]{8,}") {
    if (/$p/) { print "$f: $p\n"; last }
  }' | sort -u)
[ -z "$hits" ] && ok "비밀값 패턴 없음" || { bad "비밀값 의심(값은 숨김):"; echo "$hits" | sed 's/^/     /'; }
envs=$(git diff --name-only "$base...HEAD" | grep -E '(^|/)\.env($|\.)' | grep -v '\.env\.example$')
[ -n "$envs" ] && { echo "$envs" | sed 's/^/FAIL .env 파일 포함: /'; fail=1; }

# 5. 바뀐 영역 → verify.sh 인자 (규칙은 .claude/project.sh AREAS)
areas=$(git diff --name-only "$base...HEAD" | areas_of)
echo "target: $target"
echo "areas: ${areas:-none}"
exit $fail
