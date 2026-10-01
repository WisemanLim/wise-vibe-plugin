# 개발환경 표준 (wise-vibe)

> Claude Code · Cursor · Antigravity · GitHub Copilot · Codex 가 공통으로 읽는 프로젝트 표준.
> AI 코딩 도구는 코드·CI·인프라를 만들 때 아래 표준을 기본값으로 따른다.

## 작업 흐름 (wds-* 스킬)
- `PRD.md`(또는 `docs/PRD.md`)가 **없으면** 먼저 `wds-prd` 로 초안을 만든다 — 기존 기획서(PDF·MD·DOCX 여러 개)를 인자로 줄 수 있다.
- 순서: `wds-prd` → `wds-recommend` → `wds-scaffold` → `wds-implement` (선택: `wds-test`, `wds-review`, `wds-living-doc`, `wds-reverse-prd`, `wds-ui-design`, `wds-standardize`).
- 호출: Claude Code `/wds-<name>`(플러그인 설치 시 `/wise-vibe:wds-<name>`) · Cursor/Antigravity/Copilot `/wds-<name>` · Codex `$wds-<name>`.

## 실행 — docker compose 전용, 모드 2종
| 모드 | 파일 | DB |
|---|---|---|
| local | `docker-compose.yml` + `docker-compose.local.yml` + `.env.local` | SQLite (고정) |
| prod | `docker-compose.yml` + `docker-compose.prod.yml` + `.env.prod` | `DB_ENGINE`: PostgreSQL(기본) · MySQL · MariaDB · SQLite |

- 진입점은 Makefile: `make <mode>-all|-build|-logs|-stop|-restart|-ps` (mode = local|prod), `make test`, `make db-ping|db-migrate|db-seed [ENV=]`, `make preflight`, `make deploy`.
- 호스트 프로세스 매니저(PM2·honcho·goreman·overmind·forever)를 쓰지 않는다. 프로세스가 늘면 compose 서비스로 추가한다.
- dev/staging 같은 추가 모드를 만들지 않는다. 새 env 키는 `.env.local`·`.env.prod`(CHANGE_ME)·`.env.example` 세 곳에 함께 추가한다.
- 코드·SQL 은 local(SQLite)과 prod(`DB_ENGINE`) 양쪽에서 동작해야 한다.

## 언어·패키지 매니저
우선순위 Node/TS · Python · Rust · Go · C/C++ (+ Java/C# 프로파일). Python=uv, Node=pnpm, Go=modules, Rust=cargo. yarn/bun 은 승인제.

## 시험
- `test/dev-env/`(환경 검증 1회) · `test/impl/<Nth>/`(구현 차수별, 덮어쓰기 금지) — 각 `scenario.md`·`result.md`·`logs/`.
- 사이클: 시나리오 → 실행 → 실패 시 수정·재시험 → 결과. 유닛 테스트도 `test/` 하위(`tests/` 금지).

## 보안·규제
- 시크릿은 코드·커밋에 넣지 않는다. `.env.prod` 는 비커밋, 실제 값은 Secret Manager/Vault/CI 시크릿으로 주입.
- `COMPLIANCE.md` 가 있으면 그 업종 규제·데이터등급을 함께 준수한다. 규제 대상 실데이터를 비운영 환경에 넣지 않는다.

## 공식 스킬 연계 (설치된 경우 우선 사용)
코드 결함·보안 리뷰 `/code-review`·`/security-review` · E2E `webapp-testing` · UI `frontend-design` · 문서 변환 `pdf`/`docx`.
