# Git 규칙 — git-flow (develop 기반)

저장소:  · 작업 기준 `main` · 배포 `main` · 설정: `.claude/project.sh`(`GIT_STRATEGY=git-flow`)

이 저장소는 템플릿을 얹기 전부터 git-flow를 썼다. 기존 방식을 그대로 따른다. 바꾸려면 DEC로 결정한 뒤 이 문서와 `.claude/project.sh`를 함께 고친다.

## 브랜치

| 브랜치 | 갈라지는 곳 | 병합하는 곳 | 용도 |
|---|---|---|---|
| `main` | — | — | 배포된 코드만. 직접 커밋 · push 금지 |
| `main` | — | — | 다음 배포를 모으는 곳. 직접 커밋 · push 금지 |
| `feature/<…>` · `bugfix/<…>` · `docs/<…>` · `chore/<…>` | `main` | `main` (PR) | 기능 · 버그 · 문서 · 설정 |
| `release/<버전>` | `main` | `main` (PR) → 태그 → `main`에 되돌려 병합 | 배포 준비(버전 · 문구 · 작은 수정만) |
| `hotfix/<…>` | `main` | `main` (PR) → 태그 → `main`에 되돌려 병합 | 배포본 긴급 수정 |

- 실제 접두어 · 이슈 표기는 아래 「브랜치 · 커밋 컨벤션」(설치할 때 기존 브랜치 이름에서 감지).
- 템플릿 파일(`.claude/` 등)은 `main`에 커밋되고 다음 release 때 `main`에 들어간다. 그 전에 만든 hotfix 브랜치에는 스크립트가 없으므로 검사는 `main` 작업 폴더에서 `sh .claude/skills/finish-feature/scripts/check.sh origin/main`처럼 돌린다.
- 한 브랜치는 한 작업만 다룬다.

## 흐름

1. 작업마다 이슈를 만든다(`ISSUE_STYLE`이 github · jira면 필수). `/start-feature`가 갈라질 곳을 자동으로 고른다(hotfix · release → `main`, 나머지 → `main`).
2. 작은 단위로 커밋한다.
3. `/finish-feature`가 PR 대상을 같은 규칙으로 고른다. 병합 방식은 저장소의 기존 방식(squash · merge commit)을 따른다.
4. release · hotfix를 `main`에 병합한 뒤에는 **반드시 `main`에도 되돌려 병합**한다(별도 PR). 빠뜨리면 다음 배포에서 수정이 사라진다.
5. 배포 태그(`v1.2.3`)는 사용자 확인 후 만든다.

## 브랜치 · 커밋 컨벤션

| 항목 | 규칙 | 예 |
|---|---|---|
| 브랜치 | `<type>/<이슈번호>-<slug>` — type: feat · fix · docs · chore. hotfix · release는 `main`에서 | `feat/12-login-form` |
| 커밋 | Conventional Commits `<type>[(<scope>)]: <요약>` — type: feat · fix · docs · refactor · test · chore · ci · perf · style · build · revert, 요약은 한국어, 72자 이내, 마침표 없음. 꼬리말 `Refs #N` · AI가 함께 쓴 커밋은 `Co-Authored-By:` | `feat(auth): 로그인 화면 추가` |

근거: 새 저장소 — 기본값(추천). 값은 `.claude/project.sh`, 바꾸려면 `/project-setup`.

## 금지

- `main` · `main`에 직접 커밋 · push, `--force` / `--force-with-lease`.
- `git reset --hard`, `git clean -fd` 등으로 커밋하지 않은 변경을 지우는 것.
- 비밀값 커밋. 실수했다면 지우기보다 먼저 값을 폐기 · 재발급한다.

## 검증과 병합

- `verify.sh` 종료 코드를 확인한 **뒤에만** PR 생성 · 병합한다. `;`로 잇지 않는다.
- CI가 `main` · `main` 둘 다에서 도는지 확인한다(`.github/workflows/ci.yml`).
- 에이전트 worktree는 원격 기본 브랜치에서 만들어질 수 있다. 에이전트는 시작할 때 `origin/main`로 맞춘다(`.claude/agents/*`).
