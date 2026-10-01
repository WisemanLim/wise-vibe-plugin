---
name: wds-implement
description: >
  PRD.md 의 모든 Epic 을 확인 1회 후 자동 구현한다. Epic 마다 구현 → test/impl/<Nth>/ 시험 → 실패 시 수정·재시험을
  PASS(또는 재시도 한도)까지 반복하고 README(한/영)·PRD 를 현행화한다. 반복 엔진은 플랫폼 공식 기능(ralph-loop·/loop·
  Antigravity /goal)이 있으면 위임하고, Epic 계획표·차수 규약·BLOCKED 처리는 이 스킬이 소유한다.
  wds-scaffold 이후 실행. "PRD 구현", "전체 구현", "implement" 요청 시 사용.
license: Internal
compatibility: Claude Code · Cursor 2.4+ · Antigravity 2.0+ · GitHub Copilot · Codex. Docker + Compose v2.
metadata:
  version: "2.0.0"
  source: "github.com/WisemanLim/pub-wise-dev-std (/implement, 반복 엔진 공식 위임)"
argument-hint: "[--epic N|name] [--from N] [--step] [--max-retry K]"
disable-model-invocation: true
allowed-tools: Read Glob Grep Write Edit Bash
---

# wds-implement — PRD 전체 자동 구현

> 인자: `$ARGUMENTS` · 연계 스킬: **wds-test**(시험) · **wds-living-doc**(문서) · **wds-scaffold**(.gitignore 규칙)

| 인자 | 기본 | 설명 |
|------|------|------|
| `--epic <N\|name>` | 전체 | 특정 Epic 만 |
| `--from <N>` | 1 | N 번 Epic 부터 재개 |
| `--step` | off | Epic 마다 계속 여부 확인 |
| `--max-retry <K>` | 5 | Epic 당 수정·재시험 한도 → 초과 시 BLOCKED |

사전 조건: wds-scaffold 완료(`Makefile`, `docker-compose*.yml`, `.env.local`, `.env.prod`). 없으면 먼저 안내.

## 0. 준비 (1회)

1. **dev-env 검증** — `test/dev-env/result.md` 가 PASS 가 아니면 **wds-test** §2-1 수행
   (`make preflight` → `make local-all` → health → `make db-ping` → `make test` → prod 리허설).
2. **PRD 파싱** → 구현 계획표: `| # | Epic | 기능(FR) | 수용 기준/시험 케이스 | 의존 | 상태 |`.
   Epic 구분이 없으면 기능 묶음으로 만든다. `COMPLIANCE.md` 의 `testing_additions` 를 케이스에 배분.
3. **확인 (유일한 확인 지점)** — 질문 1회로: 계획표 승인(순서·제외) + PRD 의 모호·누락·상충 항목(구현 전에 답이 꼭 필요한 것만).
   비대화 환경이면 기본값 가정으로 진행하고 가정을 보고에 남긴다. 답으로 PRD 가 바뀌면 **PRD.md 먼저 갱신**(변경 이력 1줄).

## 1. Epic 루프

### 1-1. 반복 엔진 — 공식 기능 우선

| 플랫폼 | 위임 | 이 스킬이 넘기는 것 |
|--------|------|--------------------|
| Claude Code | `ralph-loop` 플러그인(완료 조건까지 자기참조 반복) 또는 번들 `/loop` · Epic 설계가 크면 `feature-dev` 플러그인(탐색→아키텍처→구현→리뷰) | 계획표 1행 + 수용 기준 + "1-2 절차 + `result.md` PASS" 를 완료 조건으로 |
| Antigravity | `/goal` (목표 달성까지 반복) · `/plan` | 같음 |
| Cursor · Copilot · Codex | 에이전트 기본 반복 | 같음 |
| 폴백 | 이 스킬이 직접 1-2 를 `--max-retry` 까지 반복 | — |

위임하더라도 **계획표 상태·차수 디렉터리·BLOCKED 기록은 이 스킬이 갱신**한다(엔진 결과를 읽어 반영).

### 1-2. Epic 1개 처리 절차

1. **구현** — 프로파일 스택 그대로. 기존 스타일 유지, 표면적 최소 변경.
   DB 스키마 변경은 마이그레이션 추가 → `make db-migrate`(local) — 프로파일의 `MIGRATE` 가 TODO echo 면 이 Epic 에서 도구를 설정
   (python=alembic, node=Prisma/Drizzle, go=goose/atlas, rust=sqlx-cli, java=Flyway, c#=EF Core migrations).
   local(SQLite)·prod(`DB_ENGINE`) **양쪽에서 동작**하는 SQL/ORM 만 사용(엔진 전용 문법은 분기 또는 회피).
2. **시험** — **wds-test** §3 사이클을 새 차수에(`next-iteration.sh`, Epic 1개 = 차수 1개).
   `scenario.md`(수용 기준) → `make test` + 기능 실행(curl/CLI/화면 — 브라우저는 wds-test §4 위임) → `logs/` → `result.md`.
3. **실패** — 원인 분석 → 수정 → **같은 차수**에서 재시험(회차 누적). 한도 초과면 `BLOCKED` + 필요한 결정을 기록하고 다음 Epic.
4. **PASS** — 계획표 `DONE`. 새 엔드포인트·포트·env 키가 생기면 README 해당 행만 즉시 추가(나머지는 3단계 일괄).
   새 env 키는 `.env.local`·`.env.prod`(`CHANGE_ME`)·`.env.example` 세 곳에 함께 추가.
5. **PRD 밖 요구** — PRD 갱신(변경 이력 1줄) 후 계획표에 Epic 추가. 질문은 구현 불가능한 상충일 때만.
6. `--step` 이면 계속 여부를 묻는다.

## 2. 완료 게이트

- 계획표에 TODO 없음(DONE/BLOCKED), 전체 회귀 `make test` PASS.
- **prod 회귀**: `make prod-all` → `make db-migrate ENV=prod` → `make db-ping ENV=prod` → 핵심 API 스모크 → `make prod-stop`.
- BLOCKED 가 있으면 필요한 결정을 **한 번에** 묻고, 답이 오면 해당 Epic 만 재실행.

## 3. 문서 현행화 (1회)

- `README.md`·`README.en.md` — 구현 코드 근거로: 엔드포인트·포트, compose 서비스, Make 타겟, env 매트릭스(local/prod),
  실행 방법, API 예시(실제 응답), 시험 차수별 판정, 실제 겪은 트러블슈팅, 남은 BLOCKED. 사용자 추가 섹션 보존.
- **wds-living-doc** 으로 PRD.md·COMPLIANCE.md·AGENTS.md 정합성 재검토(소스 수정 없음).

## 4. 보고

계획표 최종 상태(DONE/BLOCKED 수) · Epic 별 차수·판정·재시도 횟수 · 사용한 반복 엔진(위임/폴백) · 가정한 기본값 ·
생성/수정 파일 · BLOCKED 해결에 필요한 결정. 선택 후속: **wds-review**.

## 5. 규칙

- 확인은 0-3 의 1회 + BLOCKED 묶음 질문만. 진행 출력은 Epic 완료마다 1~2줄.
- 기존 `test/impl/<Nth>/` 덮어쓰기 금지. 호스트 프로세스 매니저 도입 금지(새 프로세스 = compose 서비스).
- 파괴적 명령·실시크릿·실제 운영 배포·`make db-reset ENV=prod` 금지. 네트워크 설치는 이미지 빌드 범위만.
