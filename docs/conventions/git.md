# Git 규칙 — GitHub Flow

저장소: [unib35/Onoff](https://github.com/unib35/Onoff) (public) · 기본 브랜치 `main` · 설정: `.claude/project.sh`(`GIT_STRATEGY=github-flow`)

## 흐름

1. 작업마다 GitHub 이슈를 먼저 만든다. 이슈 번호가 브랜치 이름에 들어간다. (`/start-feature`)
2. 최신 `main`에서 브랜치를 만든다.
3. 작은 단위로 커밋한다(아래 Conventional Commits).
4. 브랜치를 push하고 `main`으로 PR을 연다. PR 템플릿을 채운다. (`/finish-feature`)
5. 검토 → 확인 항목 통과 → **Squash and merge** → 브랜치 삭제.
6. `main`은 언제나 배포 가능한 상태로 둔다. 항상 PR을 거친다.


## 브랜치 · 커밋 컨벤션

| 항목 | 규칙 | 예 |
|---|---|---|
| 브랜치 | `<type>/<이슈번호>-<slug>` — type: feat · fix · docs · chore. hotfix · release는 `main`에서 | `feat/12-login-form` |
| 커밋 | Conventional Commits `<type>[(<scope>)]: <요약>` — type: feat · fix · docs · refactor · test · chore · ci · perf · style · build · revert, 요약은 한국어, 72자 이내, 마침표 없음. 꼬리말 `Refs #N` · AI가 함께 쓴 커밋은 `Co-Authored-By:` | `feat(auth): 로그인 화면 추가` |

근거: 새 저장소 — 기본값(추천), 2026-10-21 사용자가 그대로 쓰기로 함. 값은 `.claude/project.sh`, 바꾸려면 `/project-setup`.

## 금지

- 공유 브랜치(`main`)에 `--force` / `--force-with-lease`.
- `git reset --hard`, `git clean -fd` 등으로 아직 커밋하지 않은 변경을 지우는 것.
- 비밀값 커밋. 실수로 커밋했다면 **지우기보다 먼저 그 값을 폐기 · 재발급**한다. public 저장소는 push된 순간 노출된 것으로 본다.

## 검증과 병합

- `verify.sh`의 종료 코드를 확인한 **뒤에만** PR 생성 · 병합한다. `verify …; gh pr merge …`처럼 `;`로 잇지 않는다. 이을 거면 `&&`.
- CI가 돌리지 않는 검사(예: 느린 모바일 빌드)는 로컬 결과를 PR 본문에 붙인다.
