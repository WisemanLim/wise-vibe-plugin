# wise-vibe — vibe coding 개발 표준 통합 플러그인

PRD(기획 문서 PDF·Markdown 여러 개도 가능)만 있으면 **스택·DB 추천 → docker compose 골격 생성 → 자동 구현·시험 → 리뷰**까지
이어 주는 Agent Skills 묶음입니다. 같은 스킬 원본을 **Claude Code · Cursor · Google Antigravity · GitHub Copilot · Codex** 에 배포합니다.

- English: [README.en.md](README.en.md)
- 기반: [pub-wise-dev-std](https://github.com/WisemanLim/pub-wise-dev-std) v1.2.0 (commit 4be11b9)
- 설계 근거: 백서 *「자체 개발 Skill의 공식 지원 Skill 전환 연구」* (TR-2026-10) 7장 로드맵·5장 판정 — 반영 내역은 [docs/MIGRATION.md](docs/MIGRATION.md)

## 1. 무엇이 바뀌었나 (wise-dev-std → wise-vibe)

| 영역 | wise-dev-std 1.2 | wise-vibe 2.0 |
|------|------------------|---------------|
| 형식 | Command 11 + Skill 9 (이중 계층) | **Skill 10개(`wds-*`)** — Agent Skills 공개 사양만으로 동작 |
| 배포 | Claude 플러그인 + IDE 규칙 파일 7종 복사 | `install.sh --tool claude\|cursor\|antigravity\|copilot\|codex\|all` → 도구별 공식 스킬 경로 |
| PRD 입력 | 설문 | 설문 + **여러 문서(`a.pdf a-ui-design.pdf …`)** — 역할 추정·출처 표기 |
| 환경 | local/dev/staging/prod, env-init 별도 | **local / prod 2모드**, env-init 은 scaffold 에 흡수 |
| 실행 | 호스트 프로세스 매니저(PM2·honcho·goreman·overmind) + compose | **docker compose 전용** (dev/runtime 이미지 스테이지) |
| DB | local SQLite / 그 외 PostgreSQL 고정 | local SQLite 고정 / prod `--db postgres`(기본)·`mysql`·`mariadb`·`sqlite` |
| 리뷰·시험·UI·구현 루프 | 전부 자체 구현 | 결함·보안·E2E·UI·반복 엔진은 **공식 기능에 위임**, 고유 부분만 유지 |

## 2. 스킬 구성 (백서 5.4 판정 반영)

| 스킬 | 판정 | 역할 | 공식 위임/대체 |
|------|------|------|----------------|
| `wds-prd` | 유지 | 다중 문서(PDF·MD·DOCX)·설문 → `PRD.md` | (선택) doc-coauthoring, docx/pdf |
| `wds-recommend` | 유지 | PRD × 업종(KSIC) → 언어·PM·프레임워크·prod DB | — |
| `wds-scaffold` | 유지 (+env-init 흡수) | 결정적 스크립트로 compose 골격 생성 | — |
| `wds-living-doc` | 유지 (+req-update) | 요구 변경 → 문서 전체 현행화 | — |
| `wds-reverse-prd` | 유지 | 소스 → PRD 역도출 | — |
| `stack-architect`(에이전트) | 유지 | 전체 흐름 독립 수행 | — |
| `wds-test` | 위임 | test/dev-env · test/impl/<Nth> 규약 | webapp-testing · /verify · 브라우저 에이전트 |
| `wds-implement` | 위임 | Epic 계획표·차수·BLOCKED | ralph-loop · /loop · feature-dev · Antigravity /goal |
| `wds-review` | 위임 + 대체 | 레벨별 라인 리뷰 · 라이선스/ISO 5230 | /code-review · /security-review · pr-review-toolkit · Bugbot · **pdf/docx(대체)** |
| `wds-ui-design` | 위임 | 국내 레퍼런스 · KWCAG · 플랫폼 델타 | frontend-design · theme-factory |
| `wds-standardize` | 재설계 | AGENTS.md 관리 블록 + 스킬 설치 | — |
| 패키지·훅 | 추가 | Claude · Cursor · Agent Plugins(Antigravity·Codex·Copilot) 매니페스트, SessionStart | — |

## 3. 설치

### Claude Code (플러그인 — 팀 권장)
```
/plugin marketplace add WisemanLim/wise-vibe-plugin
/plugin install wise-vibe@wise-vibe
```
호출: `/wise-vibe:wds-prd`, `/wise-vibe:wds-scaffold` … (SessionStart 훅 포함)

### 모든 도구 — 설치 스크립트 (도구를 파라미터로 전달)
```bash
git clone https://github.com/WisemanLim/wise-vibe-plugin.git
cd your-project
/path/to/wise-vibe-plugin/install.sh --tool cursor                 # 이 프로젝트의 .cursor/skills
/path/to/wise-vibe-plugin/install.sh --tool antigravity --hooks    # .agents/skills (+ 훅 없음 → AGENTS.md 지침)
/path/to/wise-vibe-plugin/install.sh --tool copilot,codex          # .github/skills + .agents/skills
/path/to/wise-vibe-plugin/install.sh --tool all --hooks            # .agents/skills 원본 + .claude/skills 링크 + 훅
/path/to/wise-vibe-plugin/install.sh --tool all --scope user       # 홈 디렉터리 전역 설치
/path/to/wise-vibe-plugin/install.sh --tool all --uninstall        # 제거 (wds-* 와 AGENTS.md 관리 블록만)
```

| `--tool` | project 경로 | user 경로 | 에이전트 | 훅(`--hooks`) |
|----------|-------------|-----------|----------|---------------|
| claude | `.claude/skills` | `~/.claude/skills` | `.claude/agents` | `.claude/settings.json` SessionStart |
| cursor | `.cursor/skills` | `~/.cursor/skills` | `.cursor/agents` | `.cursor/hooks.json` sessionStart |
| antigravity | `.agents/skills` | `~/.gemini/config/skills` | `.agents/agents` | — (AGENTS.md 지침) |
| copilot | `.github/skills` | `~/.copilot/skills` | — | — |
| codex | `.agents/skills` | `~/.agents/skills` | — | — |
| all | `.agents/skills` + `.claude/skills`(상대 링크) | 위 전부 | `.claude/agents` + `.agents/agents` | Claude + Cursor |

기타 옵션: `--target DIR`, `--mode copy|link`, `--no-agents-md`, `--force`, `--dry-run`. 모든 설치는 `AGENTS.md` 관리 블록
(`<!-- wise-vibe:begin/end -->`)을 쓰고, `CLAUDE.md` 가 있으면 `@AGENTS.md` 한 줄을 더합니다(Claude Code 는 CLAUDE.md 가 있으면 AGENTS.md 를 읽지 않음).

### 플러그인 매니페스트 (도구별 마켓플레이스)
| 파일 | 대상 |
|------|------|
| `.claude-plugin/marketplace.json` · `plugins/wise-vibe/.claude-plugin/plugin.json` | Claude Code (Copilot CLI 도 이 marketplace 를 읽음) |
| `.cursor-plugin/marketplace.json` · `plugins/wise-vibe/.cursor-plugin/plugin.json` | Cursor 2.5+ (훅은 `cursor/hooks.json` 으로 분리 — Claude `hooks/` 와 충돌 방지) |
| `plugins/wise-vibe/plugin.json` (Agent Plugins 1.1 `$schema`) | Codex · GitHub Copilot · Cursor · Antigravity(`agy plugin install plugins/wise-vibe`) |

Copilot CLI: `copilot plugin install WisemanLim/wise-vibe-plugin:plugins/wise-vibe`

## 4. 사용 흐름

```
wds-prd → wds-recommend → wds-scaffold → wds-implement      (선택: wds-test · wds-review · wds-living-doc · wds-standardize)
```

| 도구 | 호출 예 |
|------|---------|
| Claude Code(플러그인) | `/wise-vibe:wds-prd a.pdf a-ui-design.pdf --domain commerce` |
| Claude Code(설치 스크립트) · Cursor · Antigravity · Copilot | `/wds-prd a.pdf a-ui-design.pdf` |
| Codex | `$wds-prd a.pdf a-ui-design.pdf` |

### 4-1. PRD — 다중 문서
```
/wds-prd 기획서.pdf 기획서-ui-design.pdf api-spec.docx --name "주문 서비스" --domain commerce [--full]
```
- `scripts/extract-docs.sh` 가 `.wds/prd-sources/` 에 텍스트를 추출(pdftotext → pypdf, pandoc → zipfile; 도구가 없거나 스캔본이면 에이전트가 원본을 직접 읽음).
- 파일명으로 역할 추정: `*ui*|*design*` → 디자인 요구, `*api*|*spec*` → 외부 연동, `*nfr*|*security*` → 비기능, 그 외 → 본문.
- PRD 각 항목에 `(출처: 파일 p.N)`, 문서 간 상충은 Open Questions. 채워지지 않은 항목만 5문항 설문으로 보완.

### 4-2. 스택·DB 추천
`/wds-recommend python commerce --db postgres --trends` → 표(언어·PM·FW·local/prod DB·extras·시험 러너·프로파일) + 업종 오버레이 요약.

### 4-3. 골격 생성 — docker compose, local/prod
```
/wds-scaffold python-fastapi --db mysql --extras redis --domain commerce
# 스크립트 직접: plugins/wise-vibe/skills/wds-scaffold/scripts/scaffold.sh --list
```

| 모드 | compose | env | DB | 이미지 |
|------|---------|-----|----|--------|
| local | `docker-compose.yml` + `docker-compose.local.yml` | `.env.local` (커밋) | SQLite | `dev` (바인드·핫리로드) |
| prod | `docker-compose.yml` + `docker-compose.prod.yml` | `.env.prod` (비커밋, CHANGE_ME) | `--db` (기본 postgres) | `runtime` |

```
make preflight · make local-all · make test · make db-ping · make prod-all · make db-migrate ENV=prod · make deploy
make <local|prod>-{all,build,logs,stop,restart,ps} · make db-{ping,shell,migrate,seed,reset,fresh} [ENV=]
```
프로파일: `python-fastapi` · `node-next-nest` · `go-gin` · `rust-axum` · `java-spring` · `csharp-dotnet` · `cpp-cmake` · `bio-rag-research`(PostgreSQL+pgvector 고정)
· 모바일 `ios-swiftui` · `android-compose` · `flutter-app` · `react-native-app` (compose 없이 local/prod 빌드 플레이버).

### 4-4. 구현·시험·리뷰
- `/wds-implement` — 계획표 확인 1회 → Epic 루프(공식 반복 엔진 우선) → `test/impl/<Nth>/` → README(한/영) 현행화.
- `/wds-test` — dev-env(로컬+prod 리허설) 또는 impl 시험. 브라우저 검증은 공식 기능 위임.
- `/wds-review` — 공식 `/code-review`·`/security-review` 결과 + 레벨별 라인 리뷰 + 라이선스/상용화 등급 → `.review/`.

## 5. 저장소 구조

```
wise-vibe-plugin/
├── install.sh                         # 설치 진입점 (--tool …)
├── Makefile                           # make validate | test | test-docker
├── .claude-plugin/marketplace.json    # Claude Code (+Copilot)
├── .cursor-plugin/marketplace.json    # Cursor
├── plugins/wise-vibe/
│   ├── .claude-plugin/plugin.json  .cursor-plugin/plugin.json  plugin.json(Agent Plugins)
│   ├── hooks/hooks.json  cursor/hooks.json  scripts/detect-prd.sh
│   ├── agents/stack-architect.md
│   └── skills/wds-{prd,recommend,scaffold,implement,test,review,living-doc,reverse-prd,ui-design,standardize}/
│       ├── SKILL.md  references/  scripts/  assets/
├── tests/                             # validate_skills.py · test_scaffold.sh · test_install.sh · test_extract.sh
└── docs/MIGRATION.md
```

확장: 스택 = `wds-recommend/references/profiles/<id>.yaml` + `wds-scaffold/assets/profiles.tsv` 1행 + `assets/scaffold/<id>/`.
업종 = `wds-recommend/references/domains/<id>.yaml` 1개.

## 6. 검증

```bash
make validate      # 스킬 사양(name/description/줄수/참조 파일)·YAML·JSON·버전 일치 + claude plugin validate
make test          # 스캐폴드 매트릭스(프로파일×DB, compose config) + 설치기 + 문서 추출
```
Docker 실기동 검증(2026-10-01, Docker 29.8 / Compose 5.5) 결과는 [docs/MIGRATION.md §5](docs/MIGRATION.md#5-검증-결과) 참조.

## 7. 한계

- Cursor `.cursor-plugin`·Antigravity `plugin.json` 은 2026-10-01 공식 문서 기준으로 작성했으며 실제 마켓플레이스 등록은 검증하지 않았습니다.
  Codex 마켓플레이스(`.agents/plugins/marketplace.json`)는 넣지 않았습니다 — Codex 는 `install.sh --tool codex` 를 사용하세요.
- node·go·rust·cpp·csharp 템플릿의 `/health` 는 DB 설정만 보고하며 실제 DB 질의는 python·java 만 합니다(`make db-ping ENV=prod` 는 모든 프로파일에서 DB 컨테이너 헬스로 확인).
- 모바일 템플릿은 SDK 가 필요해 이 저장소의 자동 시험 대상이 아닙니다(생성물 구조만 검증).

라이선스: 내부 사용.
