---
name: wds-scaffold
description: >
  확정된 스택 프로파일로 프로젝트 골격을 결정적으로 생성한다(구 env-init 포함). 실행은 docker compose 전용이고
  모드는 local(SQLite)·prod(--db postgres 기본|mysql|mariadb|sqlite) 두 가지다. Dockerfile(dev/runtime),
  compose 3종, Makefile, .env.local/.env.prod, CI, test/ 골격, README(한/영)을 만들고 업종 지정 시
  COMPLIANCE.md 를 쓴다. "스캐폴딩", "프로젝트 구조 생성", "보일러플레이트", "scaffold" 요청 시 사용.
license: Internal
compatibility: Claude Code · Cursor 2.4+ · Antigravity 2.0+ · GitHub Copilot · Codex. bash 3.2+ 와 perl 필요. 생성물 실행에는 Docker + Compose v2.
metadata:
  version: "2.0.0"
  source: "github.com/WisemanLim/pub-wise-dev-std (project-scaffolder + /scaffold + /env-init 통합)"
argument-hint: "<profile-id>|custom [--db postgres|mysql|mariadb|sqlite] [--extras redis,kafka] [--domain <id>] [--name N] [--target DIR]"
disable-model-invocation: true
allowed-tools: Read Glob Grep Write Edit Bash
---

# wds-scaffold — 프로젝트 골격 생성 / Scaffold

> **경로 규칙**: `SKILL_DIR` = 이 SKILL.md 폴더(Claude Code `${CLAUDE_SKILL_DIR}`).
> 엔진: `SKILL_DIR/scripts/scaffold.sh` · 템플릿: `SKILL_DIR/assets/` · 프로파일/업종: `SKILL_DIR/../wds-recommend/references/`
> 인자: `$ARGUMENTS`

## 1. 표준 (고정 규칙)

| 항목 | 규칙 |
|------|------|
| 실행 | **docker compose 전용**. 호스트 프로세스 매니저(PM2·honcho·goreman·overmind) 없음 |
| 모드 | **local** = SQLite 고정 · dev 스테이지 · 소스 바인드 / **prod** = `--db` RDBMS · runtime 스테이지 |
| prod DB | `postgres`(기본) · `mysql` · `mariadb` · `sqlite` — compose `db` 서비스 + 헬스체크 + `dbdata` 볼륨 |
| env | `.env.local`(시크릿 없음·커밋) · `.env.prod`(CHANGE_ME placeholder·비커밋) · `.env.example`(커밋) |
| Make | `<mode>-all/-build/-logs/-stop/-restart/-ps`, `test`, `shell`, `db-ping/-shell/-migrate/-seed/-reset/-fresh [ENV=]`, `deploy`, `preflight`, `help` |
| 추가 인프라 | `--extras redis,memcached,kafka,rabbitmq,mongodb` → `compose/*.yml` (두 모드 자동 포함) |
| 시험 | `test/README.md`, `test/dev-env/scenario.md`, `test/impl/` (wds-test 표준) |

## 2. 절차

1. **프로파일 확정** — 인자가 없거나 모호하면 `bash SKILL_DIR/scripts/scaffold.sh --list` 로 목록을 보여 주고 묻는다.
   `custom` 이면 `references/custom-flow.md` 대화 절차로 `<profile> --db --extras --domain --name` 을 결정한다.
2. **미리보기** — 대상 디렉터리가 비어 있지 않으면 `--dry-run` 결과(WRITE/KEEP 목록)를 먼저 보여 주고 진행 여부를 확인한다.
3. **생성** — 결정적 엔진을 실행한다(LLM 이 파일을 직접 쓰지 않는다):
   ```bash
   bash "SKILL_DIR/scripts/scaffold.sh" python-fastapi --db postgres --extras redis --name my-svc --target .
   ```
   - 기존 파일이 다르면 덮어쓰지 않고 `<file>.generated` 로 둔다(`--force` 는 사용자가 명시할 때만).
   - `.gitignore` 는 섹션 헤더(`# ===== … =====`) 기준으로 **누락 섹션만** 추가한다.
4. **업종(`--domain`) 지정 시** `COMPLIANCE.md` 를 작성한다(§3). 스크립트가 아니라 이 단계에서 YAML 근거로 쓴다.
5. **bio-rag-research** 이면 `SECURITY.md`(출처 병기·ACL·비식별·감사로그·재현성·하이브리드 검색) 를 함께 쓴다.
6. **보고** — 스크립트 요약(written/kept/unchanged)과 다음 명령:
   `make preflight` → `make local-all` → `curl …/health` → `make test` → (선택) `make prod-all` → **wds-test** dev-env 검증.

## 3. COMPLIANCE.md (업종 오버레이)

`../wds-recommend/references/domains/<id>.yaml` 로 작성한다. 섹션:

```
# COMPLIANCE — <title> (KSIC <section>)
> 자동 생성 (wds-scaffold). 근거: domains/<id>.yaml. 규제는 변하므로 references 로 재확인.
## 분류 — KSIC · ISIC/NACE/NAICS
## 한국 규제 (1순위) — korea_regulations 표 (name · since · impact)
## 국제 기준 — global_compliance
## 데이터 등급 — data_classes 표. level=규제대상 은 "local/prod 리허설 포함 비운영 환경에 실데이터 반입 금지"
## 인프라 패턴 — infra_patterns + stack_overrides (필요 시 --extras 제안)
## 개발환경 특수 요구 — dev_env_special
## 추가 시험 — testing_additions (→ test/dev-env, test/impl 케이스)
## 출처 — references
```

`stack_overrides.database` 가 선택한 `--db` 와 다르면 COMPLIANCE.md 에 차이와 근거를 적고 사용자에게 알린다.

## 4. 모바일 (`kind: mobile`)

ios-swiftui · android-compose · flutter-app · react-native-app 은 compose/DB 를 만들지 않는다.
모드 = 빌드 플레이버: iOS `Debug.xcconfig`(local)/`Release.xcconfig`(prod) · Android flavor `local`/`prod` ·
Flutter `.env.local`/`.env.prod`(`--dart-define-from-file`) · RN `.env.*` + `eas.json`(development/prod).
API 가 필요하면 서버 프로파일을 별도 디렉터리(예: `apps/api`)에 한 번 더 스캐폴딩한다. 문제 해결: `references/troubleshoot-mobile.md`.

## 5. 프로파일별 메모

| 프로파일 | local 실행 | 테스트 | DB 헬스 |
|----------|-----------|--------|---------|
| python-fastapi | uvicorn --reload (바인드) | pytest | `/health` 가 실제 `SELECT 1` |
| java-spring | gradle bootRun (바인드) | gradle test | `/health` 가 실제 `SELECT 1` (SQLite 방언 포함) |
| node-next-nest | nest --watch + next dev (서비스 2개) | vitest | 설정만(ORM 은 implement) |
| go-gin / rust-axum / cpp-cmake | go run / cargo run / CMake Debug | go test / cargo test / ctest | 설정만 |
| csharp-dotnet | dotnet watch | xUnit | 설정만(EF Core 프로바이더 패키지 포함) |

"설정만" 프로파일도 `make db-ping ENV=prod` 는 DB 컨테이너 헬스로 연결 가능 여부를 확인한다.
마이그레이션 도구가 없는 프로파일의 `MIGRATE`/`SEED` 는 TODO echo 이며 **wds-implement** 단계에서 채운다.

## 6. 확장

새 서버 프로파일 = `assets/profiles.tsv` 1행 + `assets/scaffold/<id>/`(Dockerfile `dev`/`runtime` 스테이지,
`docker-compose.yml`·`.local.yml`·`.prod.yml`, `wds.mk`) + `../wds-recommend/references/profiles/<id>.yaml`.
토큰: `{{PROJECT_NAME}} {{DB_ENGINE}} {{DB_DEPS}} {{DB_SERVICE}} {{DB_DEPENDS_ON}} {{DB_VOLUMES}} {{PROFILE_ID}} {{PROFILE_TITLE}} {{APP_PORT}}`.

## 7. 안전 규칙

- 파일 생성만. 패키지 설치·이미지 빌드·네트워크 명령을 이 스킬이 실행하지 않는다(사용자가 `make` 로 실행).
- 실제 자격증명 생성 금지 — `.env.prod` 는 `CHANGE_ME`, `make deploy` 는 CHANGE_ME 가 남아 있으면 거부한다.
- 기존 파일 보존(`.generated`), `--force` 는 명시 요청 시에만.
