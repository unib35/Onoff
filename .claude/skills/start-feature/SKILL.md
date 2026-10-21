---
name: start-feature
description: 이슈 하나로 새 작업을 시작할 때 — GitHub 이슈 확인(없으면 초안 작성 후 승인받아 생성), 저장소 Git 전략(github-flow · git-flow)에 맞는 브랜치에서 작업 브랜치 생성, 이슈에 적힌 연결 ID 문서 위치 안내. 사용자가 "작업 시작", "이슈 N 시작", "새 기능 시작"이라고 하거나 /start-feature를 쓸 때 사용.
---

# 작업 시작

입력: `/start-feature <이슈번호> [slug]` 또는 `/start-feature "<할 일 설명>"`(이슈 없음)
브랜치 접두어 · 갈라질 곳 · 이슈 번호 사용 여부는 `.claude/project.sh`(`GIT_STRATEGY` · `BRANCH_TYPES` · `ISSUE_STYLE` · `BRANCH_REGEX`)를 따른다 — 설치할 때 기존 브랜치 이름에서 감지한 값이다.
출력: 만든 브랜치 이름, 이슈 제목, 연결 ID와 문서 위치, 다음 할 일. 규칙은 `docs/conventions/git.md`, 설정은 `.claude/project.sh`.

1. **이슈 정하기**
   - 번호가 있으면 2로.
   - 설명만 있으면 이슈 초안(제목 · 무엇을 왜 · 연결 ID · 완료 기준)을 보여주고 **승인받은 뒤** `gh issue create -R <GH_REPO> --title … --body-file …`로 만든다. public 저장소면 만들면 바로 공개된다.
2. **type · slug 정하기** — type은 `BRANCH_TYPES` 중 하나(github-flow 기본 `feat` · `fix` · `docs` · `chore`, git-flow 기본 `feature` · `bugfix` · `hotfix` · `release` · `docs` · `chore`). 배포본 긴급 수정이면 `hotfix`. issue 자리: `ISSUE_STYLE=github`이면 이슈 번호, `jira`면 이슈 키(`ABC-123`, GitHub에서 확인하지 않음), `none`이면 `-`. release는 `-` + 버전(`1.2.0`). slug는 영어 소문자 2–5단어. 사용자가 주지 않으면 이슈 제목에서 정하고 보고에 적는다.
3. **실행** — `sh .claude/skills/start-feature/scripts/start.sh <type> <issue|-> <slug>` — 출력의 `from` · `PR 대상`과 `note`(git-flow 되돌림 병합)를 보고에 포함
   | 종료 코드 | 뜻 | 할 일 |
   |---|---|---|
   | 0 | 브랜치 생성 | 4로 |
   | 1 | 입력 형식 오류 | 고쳐서 다시 실행 |
   | 2 | 커밋 안 한 변경 있음 | **멈추고** 변경 목록을 보여주며 사용자에게 물음(커밋 · stash · 나중에). 직접 stash · reset · 삭제하지 않는다 |
   | 3 | 이슈 없음 · 닫힘 · gh 실패 | 보고하고 멈춤 |
   | 4 | git 실패(브랜치 중복 · pull 실패 등) | 메시지 그대로 보고. 강제 옵션 쓰지 않음 |
4. **맥락 안내** — 출력의 `refs` ID만 `ref-docs`에 적힌 문서에서 찾아(`grep -n`) 위치를 알려준다. 문서 전체를 읽어 붙이지 않는다. ID가 없으면 "이슈에 연결 ID 없음"이라고 쓴다.
5. **보고** — 수행 / 검증 / 차단 / 내가 할 일 / 다음 단계 순서로 짧게. 마무리는 `/finish-feature`.
