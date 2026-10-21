# Git 규칙 — trunk (기본 브랜치에 바로)

저장소:  · 기본 브랜치 `main` · 설정: `.claude/project.sh`(`GIT_STRATEGY=trunk`, `DIRECT_PUSH=1`)

이 저장소는 작업 브랜치 없이 `main`에 작은 커밋을 바로 올려 왔다(설치할 때 이력에서 감지). 기존 방식을 그대로 따른다. 협업자가 생기거나 리뷰가 필요해지면 github-flow로 바꾸는 것을 DEC로 검토한다.

## 흐름

1. 작은 단위로 `main`에 커밋한다. 크거나 위험한 작업(아래)은 작업 브랜치 → PR.
2. push 전에 `check.sh`(커밋 형식 · 비밀값)와 바뀐 영역의 `verify.sh`가 통과해야 한다. 실패하면 push하지 않는다.
3. 이슈가 있으면 커밋 꼬리말에 `Refs #N`.

PR로 해야 하는 것: 디자인 변경 · 결제 · 운영 배포 · 권한 · 데이터 삭제 · 여러 영역에 걸친 큰 변경 · 아키텍처 변경.

## 브랜치 · 커밋 컨벤션

| 항목 | 규칙 | 예 |
|---|---|---|
| 브랜치 | `<type>/<이슈번호>-<slug>` — type: feat · fix · docs · chore. hotfix · release는 `main`에서 | `feat/12-login-form` |
| 커밋 | Conventional Commits `<type>[(<scope>)]: <요약>` — type: feat · fix · docs · refactor · test · chore · ci · perf · style · build · revert, 요약은 한국어, 72자 이내, 마침표 없음. 꼬리말 `Refs #N` · AI가 함께 쓴 커밋은 `Co-Authored-By:` | `feat(auth): 로그인 화면 추가` |

근거: 새 저장소 — 기본값(추천). 값은 `.claude/project.sh`, 바꾸려면 `/project-setup`.

## 금지

- `main`에 `--force` / `--force-with-lease`, 기록 다시 쓰기.
- `git reset --hard`, `git clean -fd` 등으로 커밋하지 않은 변경을 지우는 것.
- 비밀값 커밋. 실수했다면 지우기보다 먼저 값을 폐기 · 재발급한다.

## 검증

- `verify.sh` 종료 코드를 확인한 **뒤에만** push한다. `verify …; git push`처럼 `;`로 잇지 않는다 — `&&`.
