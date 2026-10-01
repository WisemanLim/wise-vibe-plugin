# wise-dev-std 1.2 → wise-vibe 2.0 마이그레이션 · 반영 내역

근거: 백서 *「자체 개발 Skill의 공식 지원 Skill 전환 연구」*(TR-2026-10) 5장(매핑 판정)·7장(로드맵) + 추가 요구
(멀티 툴 배포 파라미터, PRD 다중 PDF 입력, env-init 삭제·local/prod 통일·compose 전용·RDBMS 선택).

## 1. 7장 로드맵 단계별 반영

| 단계 | 백서 작업 | 반영 | 완료 조건 확인 |
|------|-----------|------|----------------|
| Phase 0 정리 | README 버전·homepage, `.antigravity/rules.md` 제거 | 버전 2.0.0 단일화(5개 매니페스트), homepage/repository = `wise-vibe-plugin`, 비공식 경로 제거 | `tests/validate_skills.py` 버전 일치 검사 |
| Phase 1 Skill 통합 | commands 11 → skills, `wds-` 네이밍, 표준 frontmatter | `commands/` 삭제, 스킬 10개(`wds-*`), 표준 필드 + Claude 확장(`disable-model-invocation` 등) | `validate_skills.py`, `claude plugin validate` |
| Phase 2 경로 자립화 | profiles/domains/templates → references·assets, `${CLAUDE_PLUGIN_ROOT}` 제거, scripts 결정화 | `wds-recommend/references/{profiles,domains,trends-cache.yaml}`, `wds-scaffold/assets/`, `scaffold.sh`·`extract-docs.sh`·`next-iteration.sh`·`install.sh` | 스킬 내 `CLAUDE_PLUGIN_ROOT` 0건(검사 항목) |
| Phase 3 공식 위임 | review·test·implement·ui-design 위임 + 폴백 | 각 SKILL.md 의 위임 표 + 폴백 절차 | 문서 검토 |
| Phase 4 멀티 플랫폼 | standardize 재설계, `.cursor-plugin`, Antigravity `plugin.json`, 훅 | `install.sh --tool …`, Cursor/Agent Plugins 매니페스트, Claude·Cursor 훅 | `tests/test_install.sh` (28개 검사) |
| Phase 5 품질 | skill-creator eval, `/skill-doctor` | **미수행** — 트리거 정확도 eval 은 실제 사용 프롬프트가 필요해 후속 과제로 남김 | — |

## 2. 5.2/5.4 판정 → 구성요소

| 구 구성요소 | 판정 | 신 구성요소 | 변경 요지 |
|-------------|------|-------------|-----------|
| prd-advisor + /prd | 유지 | `wds-prd` | **다중 문서 입력**(PDF·MD·DOCX·TXT), 역할 추정, 출처 표기, 빈칸만 설문 |
| stack-advisor + /recommend | 유지 | `wds-recommend` | 모드 local/prod, prod DB 선택 규칙(§4), compose 전용(§5), `--db` 인자 |
| project-scaffolder + /scaffold + /env-init | 유지(+흡수) | `wds-scaffold` | 결정적 `scaffold.sh`, env 파일 생성 흡수, 프로세스 매니저 삭제 |
| living-doc + /req-update | 유지 | `wds-living-doc` | 통합 |
| reverse-prd + /reverse-prd | 유지 | `wds-reverse-prd` | 통합 |
| stack-architect | 유지 | `agents/stack-architect.md` | 흐름·모드 갱신, 설치기로 Cursor/Antigravity 에도 배포 |
| test-runner + /test | 위임 | `wds-test` | E2E·브라우저 → webapp-testing · /verify · 브라우저 에이전트, dev-env 에 prod 리허설 추가 |
| /implement | 위임 | `wds-implement` | 반복 엔진 → ralph-loop · /loop · feature-dev · /goal, 계획표·차수·BLOCKED 유지 |
| code-reviewer + depth-reviewer + /review | 위임 | `wds-review` (+references 2개) | 결함·보안·단순화 → /code-review · /security-review · pr-review-toolkit · Bugbot |
| review `--pdf` (pandoc 체인) | 대체 | 공식 `pdf`/`docx` 스킬 | 자체 변환 체인 삭제 |
| ui-design-advisor + /ui-design | 위임 | `wds-ui-design` | 미학·UI 코드 → frontend-design · theme-factory |
| /standardize + install-portable.sh | 재설계 | `wds-standardize` + `install.sh` | IDE 규칙 7종 복사 → AGENTS.md 관리 블록 1개 + 스킬 설치 |
| plugin/marketplace, SessionStart | 패키지·훅 | Claude·Cursor·Agent Plugins 매니페스트, `cursor/hooks.json` 분리 | Claude `hooks/hooks.json` 과 Cursor 훅 스키마 충돌 회피 |

## 3. 명령 대응표

| wise-dev-std | wise-vibe |
|--------------|-----------|
| `/wise-dev-std:prd "이름" healthcare --full` | `/wise-vibe:wds-prd [a.pdf a-ui-design.pdf …] --name 이름 --domain healthcare --full` |
| `/wise-dev-std:recommend python healthcare --trends` | `/wise-vibe:wds-recommend python healthcare [--db postgres] --trends` |
| `/wise-dev-std:scaffold python-fastapi --domain X` | `/wise-vibe:wds-scaffold python-fastapi --db postgres --domain X [--extras redis]` |
| `/wise-dev-std:env-init python-fastapi --db postgres` | **삭제** — scaffold 가 `.env.local`/`.env.prod`/`.env.example` 생성, `--db` 는 scaffold 인자 |
| `/wise-dev-std:implement` · `test` · `review` · `reverse-prd` · `ui-design` | `/wise-vibe:wds-implement` · `wds-test` · `wds-review` · `wds-reverse-prd` · `wds-ui-design` |
| `/wise-dev-std:req-update` | `/wise-vibe:wds-living-doc` |
| `/wise-dev-std:standardize` · `install-portable.sh` | `/wise-vibe:wds-standardize` · `./install.sh --tool …` |

## 4. 생성 프로젝트 변경 (기존 프로젝트 이전 시)

| 항목 | 이전 | 이후 |
|------|------|------|
| env 파일 | `.env.local/.dev/.staging/.prod` | `.env.local`(커밋) · `.env.prod`(비커밋) · `.env.example` |
| compose | `docker-compose.yml`(infra) + `profiles: [app]` | `docker-compose.yml`(공통) + `.local.yml` + `.prod.yml`, 프로젝트명 `<name>-local` / `<name>-prod` 분리 |
| 프로세스 | `Procfile.dev`·`ecosystem.config.cjs`·`.make/*.pid` | 삭제 — 컨테이너 서비스로 |
| Make | `local-*`(호스트) + `dev/staging/prod-*` | `local-*` · `prod-*` 모두 compose, `prod-build` 허용, `shell`·`db-ping`·`db-shell` 추가 |
| DB | local SQLite, dev+ PostgreSQL 고정 | local SQLite, prod `DB_ENGINE` = postgres · mysql · mariadb · sqlite |
| Redis | 기본 포함 | `--extras redis` 선택 |
| 툴체인 | 호스트에 uv/pnpm/go/cargo 필요 | 호스트는 Docker + Make 만 (dev 스테이지가 툴체인 보유) |

이전 절차: `scaffold.sh <profile> --db <engine> --target .` 실행 → 생성된 `*.generated` 를 기존 파일과 비교·병합 →
`Procfile.dev`·`ecosystem.config.cjs`·`.env.dev`·`.env.staging` 삭제 → `make preflight && make local-all && make test`.

## 5. 검증 결과

| 검사 | 범위 | 결과 |
|------|------|------|
| `tests/validate_skills.py` | 스킬 10개 사양, YAML 27개, JSON 5개, 버전 일치, 금지 파일·패턴 | 통과 |
| `claude plugin validate` | marketplace + plugin | 통과 |
| `claude -p --plugin-dir` 로드 | 모델 노출 스킬 7개 + 사용자 전용 3개(`disable-model-invocation`) | 의도대로 |
| `tests/test_scaffold.sh --compose` | 프로파일 12 × prod DB 4 (서비스) · compose config 2모드 · 멱등 · 보존 · 잘못된 입력 | 통과 |
| `tests/test_install.sh` | 5개 도구 + all + user scope + 멱등 + uninstall | 통과 |
| `tests/test_extract.sh` | md + pdf + docx 다중 입력, 역할 추정 | 통과 |
| Docker 실기동 (`tests/e2e_docker.sh`) | 아래 표 | 아래 표 |

Docker 29.8 · Compose 5.5 (macOS arm64), 2026-10-01. 각 행 = scaffold → local(빌드·healthy·`/health`·`make test`·`db-ping`)
→ prod(빌드·app+db healthy·`/health`·`db-ping ENV=prod`·`db-migrate ENV=prod`) → 정리.

| 프로파일 | prod DB (실행한 조합) | local | prod | 비고 |
|----------|----------------------|-------|------|------|
| python-fastapi | postgres · mysql · mariadb · sqlite | 통과 | 통과 | `/health` 가 실제 `SELECT 1` — 4개 엔진 모두 `status: ok`, alembic 마이그레이션 실행 |
| java-spring | mariadb · postgres | 통과 | 통과 | `/health` 실제 DB 질의(SQLite 방언 포함), gradle test |
| go-gin | postgres · mariadb | 통과 | 통과 | go test |
| rust-axum | mysql · sqlite | 통과 | 통과 | cargo test |
| csharp-dotnet | postgres | 통과 | 통과 | xUnit (WebApplicationFactory) |
| cpp-cmake | mariadb | 통과 | 통과 | ctest |
| node-next-nest | postgres · mysql | 통과 | 통과 | vitest(api·web), prod web→api 호출 확인 |
| bio-rag-research | — | — | — | python-fastapi 템플릿 + pgvector 이미지(구성만 검증) |
| 모바일 4종 | — | — | — | SDK 필요 — 구조 검증만 |

go-gin·postgres 와 rust-axum·mysql 조합은 migrate 검사를 넣기 전 하네스로 실행(빌드·헬스·db-ping 까지 확인).

검증 중 발견·수정한 결함: Python `PYTHONPATH` 누락(테스트·alembic 임포트 실패), Java gradle 캐시 락 충돌(실행 중 bootRun ↔ test),
C# 런타임 이미지의 기존 `app` 사용자와 충돌, C++ 빌드/런타임 libstdc++ 버전 불일치, ENTRYPOINT 이미지에서 `run … sh -c` 가
서버를 재기동하던 문제(`--entrypoint sh` 로 수정), Go distroless 런타임에 셸이 없어 `make db-*` 불가(alpine 으로 변경).
재현: `make test-docker PROFILE=<id> DB=<engine> PORT=<port>`.

