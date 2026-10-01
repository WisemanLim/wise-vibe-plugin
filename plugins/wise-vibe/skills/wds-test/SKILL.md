---
name: wds-test
description: >
  PRD 기반 시험 표준을 실행한다: 시나리오 작성 → 실행 → 실패 시 원인 수정·재시험 → result.md. 결과는 test/dev-env
  (환경 검증 1회)와 test/impl/<Nth>/(구현 차수별)에 저장. local 모드 docker compose 기준(make test·make db-ping),
  브라우저/E2E 검증은 플랫폼 공식 기능(webapp-testing·/verify·브라우저 에이전트)에 위임한다.
  "테스트", "시험", "검증", "QA", "test scenario" 요청 시 사용.
license: Internal
compatibility: Claude Code · Cursor 2.4+ · Antigravity 2.0+ · GitHub Copilot · Codex. Docker + Compose v2.
metadata:
  version: "2.0.0"
  source: "github.com/WisemanLim/pub-wise-dev-std (test-runner + /test 통합, E2E 공식 위임)"
argument-hint: "[--area dev-env|impl|all] [--chunk N] [--feature keyword]"
allowed-tools: Read Glob Grep Write Edit Bash
---

# wds-test — 시험 표준 / Testing standard

> `SKILL_DIR` = 이 SKILL.md 폴더(Claude Code `${CLAUDE_SKILL_DIR}`). 참고: `SKILL_DIR/references/chunking.md`
> 인자: `$ARGUMENTS`

## 1. 디렉터리 규칙

```
test/
├── README.md
├── dev-env/{scenario.md,result.md,logs/}     # 표준 환경 검증 1회
└── impl/<Nth>/{scenario.md,result.md,logs/}  # 구현 차수별 (1st, 2nd, …) — 덮어쓰기 금지
```

- 새 차수: `bash SKILL_DIR/scripts/next-iteration.sh [root] [--chunks K]` (마지막 줄 = 생성 경로).
- 언어별 유닛 테스트도 `test/` 하위(`tests/` 금지). 예외: RN `__tests__/`, iOS `AppTests/`, Android `app/src/test`, Go/Rust in-package.
- `test/**/logs/` 는 비커밋(.gitignore).

## 2. 시험 영역

### 2-1. dev-env (서버 프로파일 — docker compose)
`test/dev-env/scenario.md`(스캐폴드가 생성)를 그대로 실행한다.

| 순서 | 명령 | 기대 |
|------|------|------|
| 1 | `make preflight` | Docker·Compose v2·env 파일 OK |
| 2 | `make local-all` | 컨테이너 healthy (`make local-ps`) |
| 3 | `curl -fsS http://127.0.0.1:$API_PORT/health` | 200, `env=local` |
| 4 | `make db-ping` | `sqlite OK` |
| 5 | `make test` | exit 0 |
| 6 | `make prod-all` → `make db-ping ENV=prod` | app+db healthy, `<engine> OK` (리허설 — CHANGE_ME 그대로 허용) |
| 7 | `make local-stop && make prod-stop` | 정리 |

모바일은 `make preflight` → `make setup` → `make local-all`(시뮬레이터) → `make test` → `make prod-build`.

### 2-2. impl (구현 차수)
PRD 수용 기준 → 케이스 표 `| id | 목적 | 입력 | 기대 | 우선 |` → 실행 → 결과.

## 3. 시험 사이클

1. **시나리오** → `scenario.md` (PRD 수용 기준 · COMPLIANCE.md `testing_additions` 포함).
2. **실행** → 원본 출력은 `logs/` (`make test 2>&1 | tee logs/make-test.txt` 등). 기능 검증은 API(curl)·CLI·화면.
3. **실패 시** → 근본 원인 → 수정 → 같은 차수에서 재실행, `round N: 변경 → 결과` 기록.
4. **결과** → `result.md` (`references/chunking.md` §A 템플릿). 케이스 > 15(`--chunk N`) 면 §B 청킹.

## 4. 공식 기능 위임 (E2E·브라우저·앱 구동)

자체 브라우저 자동화는 두지 않는다. 사용 가능한 것을 위에서부터 쓰고, 없으면 폴백한다.

| 플랫폼 | 위임 대상 |
|--------|-----------|
| Claude Code | Anthropic 공식 `webapp-testing` 스킬(Playwright, `example-skills@anthropic-agent-skills`) · 번들 `/verify`·`/run` |
| Cursor | Browser 서브에이전트 |
| Antigravity | `/browser` 서브에이전트 (녹화 아티팩트를 `logs/` 에 링크) |
| Copilot / Codex | 각 에이전트의 브라우저/터미널 도구 |
| 폴백 | `curl` 스모크 + `make test` (UI 케이스는 `MANUAL` 로 표기하고 확인 절차를 적는다) |

## 5. 문서 동기화

시험 완료 후 **wds-living-doc** 으로 README(한/영) `## 시험` 섹션에 최신 차수·판정을 반영한다.
버그 수정이 기능 변경이면 PRD.md 변경 이력에도 1줄.

## 6. 안전

- 기존 차수 덮어쓰기 금지(항상 N+1). prod 리허설은 로컬 Docker 에서만, 실제 운영 DB·배포 대상 금지.
- `make db-reset ENV=prod`·실시크릿·실데이터 금지. 네트워크 설치는 `make` 타겟(이미지 빌드) 범위만.
