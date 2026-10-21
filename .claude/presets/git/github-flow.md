# Git 규칙 — GitHub Flow

저장소:  · 기본 브랜치 `main` · 설정: `.claude/project.sh`(`GIT_STRATEGY=github-flow`)

## 흐름

1. 작업마다 GitHub 이슈를 먼저 만든다. 이슈 번호가 브랜치 이름에 들어간다. (`/start-feature`)
2. 최신 `main`에서 브랜치를 만든다.
3. 작은 단위로 커밋한다(아래 Conventional Commits).
4. 브랜치를 push하고 `main`으로 PR을 연다. PR 템플릿을 채운다. (`/finish-feature`)
5. 검토 → 확인 항목 통과 → **Squash and merge** → 브랜치 삭제.
6. `main`은 언제나 배포 가능한 상태로 둔다. 기본은 PR을 거친다. 예외는 아래 「main 직접 push」.

### main 직접 push (1인 개발 기간 예외)

`.claude/project.sh`의 `DIRECT_PUSH=1`일 때만 쓴다(기본 0 — 항상 PR).
속도가 우선인 작은 작업은 브랜치 · PR 없이 `main`에 커밋하고 바로 push해도 된다. 조건:

- push 전에 `check.sh`(커밋 형식 · 비밀값)와 바뀐 영역의 `verify.sh`가 통과해야 한다. 실패하면 push하지 않는다.
- 커밋 꼬리말에 이슈가 있으면 `Refs #N`을 적는다.
- `--force` 금지.
- 디자인 변경 · 결제 · 운영 배포 · 권한 · 데이터 삭제가 들어간 변경, 여러 영역에 걸친 큰 변경은 예외로 하지 않고 PR을 연다.
- 협업자가 생기거나 `main` 보호 설정을 켜면 이 예외는 없앤다.

## 브랜치 · 커밋 컨벤션

| 항목 | 규칙 | 예 |
|---|---|---|
| 브랜치 | `<type>/<이슈번호>-<slug>` — type: feat · fix · docs · chore. hotfix · release는 `main`에서 | `feat/12-login-form` |
| 커밋 | Conventional Commits `<type>[(<scope>)]: <요약>` — type: feat · fix · docs · refactor · test · chore · ci · perf · style · build · revert, 요약은 한국어, 72자 이내, 마침표 없음. 꼬리말 `Refs #N` · AI가 함께 쓴 커밋은 `Co-Authored-By:` | `feat(auth): 로그인 화면 추가` |

근거: 새 저장소 — 기본값(추천). 값은 `.claude/project.sh`, 바꾸려면 `/project-setup`.

## 금지

- 공유 브랜치(`main`)에 `--force` / `--force-with-lease`.
- `git reset --hard`, `git clean -fd` 등으로 아직 커밋하지 않은 변경을 지우는 것.
- 비밀값 커밋. 실수로 커밋했다면 **지우기보다 먼저 그 값을 폐기 · 재발급**한다. public 저장소는 push된 순간 노출된 것으로 본다.

## 검증과 병합

- `verify.sh`의 종료 코드를 확인한 **뒤에만** PR 생성 · 병합한다. `verify …; gh pr merge …`처럼 `;`로 잇지 않는다. 이을 거면 `&&`.
- CI가 돌리지 않는 검사(예: 느린 모바일 빌드)는 로컬 결과를 PR 본문에 붙인다.
