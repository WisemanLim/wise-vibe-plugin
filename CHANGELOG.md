# Changelog

## 2.0.0 — 2026-10-01 (wise-vibe 최초 릴리스, pub-wise-dev-std 1.2.0 기반)

### 변경 (Breaking)
- Command 11개 → Agent Skills 10개(`wds-*`). `commands/` 삭제. 호출: `/wise-vibe:wds-<name>`.
- `env-init` 삭제 → `wds-scaffold` 가 `.env.local`·`.env.prod`·`.env.example` 생성.
- 모드 local/dev/staging/prod → **local / prod**. 실행은 **docker compose 전용**(PM2·honcho·goreman·overmind·Procfile 제거).
- prod DB 선택 `--db postgres|mysql|mariadb|sqlite`(기본 postgres), local 은 SQLite 고정. Redis 는 `--extras` 로 선택.
- `standardize` 재설계: IDE 규칙 7종 복사 → AGENTS.md 관리 블록 + 도구별 스킬 설치.

### 추가
- `install.sh --tool claude|cursor|antigravity|copilot|codex|all` (project/user scope, link/copy, hooks, uninstall).
- `wds-prd` 다중 문서 입력(PDF·MD·DOCX·TXT) + `extract-docs.sh`(pdftotext/pypdf/pandoc/zipfile 폴백, 역할 추정).
- Cursor(`.cursor-plugin/`)·Agent Plugins(`plugin.json`, Codex/Copilot/Antigravity) 매니페스트.
- 서버 템플릿 전면 재작성: Dockerfile `dev`/`runtime` 스테이지, compose 3종, 공통 Makefile(`server.mk`), 헬스체크, 테스트 1개씩.
  python·java 는 `/health` 에서 실제 DB 질의. rust 템플릿의 누락 의존성(serde_json)·cpp 소스 부재·node 소스 부재 해결.
- 공식 Skill 위임: `/code-review`·`/security-review`·pr-review-toolkit·Bugbot·webapp-testing·frontend-design·ralph-loop·pdf/docx.
- 자체 테스트: `make validate`, `make test`, `make test-docker`.

### 수정 (pub-wise-dev-std 부록 B 이슈)
- B-1 README 버전 표기 불일치, B-2 homepage/repository, B-3 `.antigravity/rules.md`, B-4 GEMINI.md 설명, B-5 Windsurf 경로,
  B-6 README 스킬 표 누락, B-7 단계 안내 오류, B-8 Command–Skill 이중 계층, B-9 `${CLAUDE_PLUGIN_ROOT}` 의존.
- 저장소 `.gitignore` 가 `skills/`·`agents/`·`scripts/`·`.env.*` 템플릿을 무시하던 문제.
- `_combine.sh` 가 bash 4 전용(macOS 기본 bash 3.2 실패) → `scaffold.sh` 내장 조립(섹션 단위 멱등)으로 대체.
