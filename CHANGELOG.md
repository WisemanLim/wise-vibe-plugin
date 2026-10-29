# Changelog

## 2.1.0 — 2026-10-29

### 추가
- **`workspace` 프로파일** (kind `workspace`): 통합관리 root repo 를 결정적으로 생성 — `Makefile` · `README.md`/`README.en.md` · `DEPLOY-PROD-GUIDE.md` ·
  `release/{release.sh,services.tsv,deploy.env.example}` · `scripts/{prod-secrets,secret-scan}.sh` · `test/deploy/`(배포 시험만: 소스 아카이브·비밀 init 회귀) ·
  `docs/TEST-OWNERSHIP.md` · CI(gitleaks + make test) · `.gitleaks.toml` · `.gitignore`(서브 repo 제외 섹션 첫머리).
  `scaffold.sh workspace --services <repo>:<api|web>:<host-port>[:db],... --name <ws>`. 서비스 목록 정본은 `release/services.tsv`.
- `release.sh`: doctor · build(멀티아키 tar.gz+sha256) · up · deploy(ssh, 이미지 스트리밍, releases/<V> + current + shared 비밀) · status · down · rollback, 종료 코드 0/2/4/5/8.
- **`--workspace <ws>`** (서비스·웹): prod 전용 `docker-compose.workspace.yml`(공유 네트워크 `<ws>-net`, 별칭 `<repo>-<svc>`, `<SVC>_IMAGE` 배포 태그) + Makefile `prod-net`.
- **`--local-db <db>`**: local 도 prod 와 같은 RDBMS (`compose/db.yml` 두 모드 공통, local 전용 고정 비밀번호, `db-reset` 은 스키마 재생성). RLS·테넌트 격리 시험용 예외.
- **`react-spa` 프로파일** (kind `web`): Vite + React + TypeScript + Tailwind, dev = Vite / runtime = 비root nginx(읽기 전용 FS, conf.d tmpfs, 보안 헤더, `/api` 프록시).
- **간편 설치**: `curl -fsSL …/install.sh | bash` — 잘림 방지 가드, 소스 다운로드(codeload → gh api → git clone), 도구 감지(`--tool` 생략 시 user scope), `--list`·`--ref`·`--source`·`--plugin`.

### 변경
- `assets/common/server.mk` → `base.mk`(수명주기·시험·배포·prod-net) + `db.mk`(DB 타겟) + `web.mk`. db-ping/db-shell/db-reset 은 모드별 엔진(`LOCAL_DB`/`DB_ENGINE`)을 따른다.
- 모든 서비스 템플릿 healthcheck 에 `start_period: 30s` (느린 첫 기동을 실패로 판정하지 않음).

### 수정 (EvidenceMesh 리허설에서 발견)
- 명령 치환 안의 `die` 가 서브셸만 종료해 잘못된 `--services` 가 exit 0 이 되던 문제 → 목록을 메인 셸에서 1회 해석.
- nginx 읽기 전용 FS 에서 envsubst 설정 렌더 실패 → `conf.d` tmpfs(uid 101).
- 공유 네트워크에서 서비스 이름 `api` 가 repo 간 충돌 → web prod `API_UPSTREAM` 은 `CHANGE_ME` 로 생성해 고유 별칭을 명시하게 함.

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
