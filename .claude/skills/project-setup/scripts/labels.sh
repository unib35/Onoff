#!/bin/sh
# GitHub 라벨 만들기 — .github/labels.txt 기준. 이미 있는 라벨은 건드리지 않는다(색 · 설명 덮어쓰기 없음).
# 사용: labels.sh [--dry-run]   종료 코드: 0 성공 · 1 실패
set -u
cd "$(git rev-parse --show-toplevel)" || exit 1
. ./.claude/lib.sh && load_project || exit 1
[ -n "$GH_REPO" ] || { echo "GitHub 저장소를 모름 — 원격을 먼저 만든다"; exit 1; }
dry=0; [ "${1:-}" = --dry-run ] && dry=1
have=$(gh label list -R "$GH_REPO" --limit 200 --json name -q '.[].name' 2>/dev/null) || { echo "gh label list 실패"; exit 1; }
TAB=$(printf '\t')
grep -v '^#' .github/labels.txt | while IFS="$TAB" read -r n c d; do
  [ -n "$n" ] || continue
  if printf '%s\n' "$have" | grep -qxF "$n"; then echo "있음  $n"
  elif [ $dry = 1 ]; then echo "만들 것 $n"
  else gh label create "$n" -R "$GH_REPO" --color "$c" --description "$d" >/dev/null && echo "만듦  $n" || echo "실패  $n"; fi
done
