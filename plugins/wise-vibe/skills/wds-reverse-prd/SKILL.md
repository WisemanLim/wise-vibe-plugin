---
name: wds-reverse-prd
description: >
  PRD 없이 구현된 소스코드를 분석해 PRD.md 를 역도출한다. 라우터·컨트롤러·모델·설정·테스트·README 를 읽어
  기능·비기능 요구·데이터 모델·사용자 흐름을 재구성하고 확인 불가 항목은 "미확인:" 으로 표시한다.
  "PRD 역도출", "소스로 PRD 만들어", "reverse PRD", "PRD from code" 요청 시 사용.
license: Internal
compatibility: Claude Code · Cursor 2.4+ · Antigravity 2.0+ · GitHub Copilot · Codex.
metadata:
  version: "2.0.0"
  source: "github.com/WisemanLim/pub-wise-dev-std (reverse-prd + /reverse-prd 통합)"
argument-hint: "[path] [--full] [--yes]"
allowed-tools: Read Glob Grep Write Edit
---
# wds-reverse-prd — 소스 기반 PRD 역도출

> 인자: `$ARGUMENTS` — `[path]` 분석 대상(기본 현재 디렉터리) · `--full` 풀스펙 · `--yes` 덮어쓰기 확인 생략(기존 PRD 는 `PRD.reverse.md` 로 저장)
> 템플릿: `../wds-prd/references/prd-template.md` · 업종: `../wds-recommend/references/domains/`

이 스킬은 **PRD 없이 구현된 프로젝트의 소스코드를 분석해 PRD.md 를 역도출**한다.
코드는 진실(truth)이고 PRD 는 그 의도의 기록이다. 코드의 "무엇을 했는지"에서 "왜·누가"를 추론한다.

원칙:
- **코드가 근거, 추측은 `미확인:` 태그** — 코드에서 확인할 수 없는 값은 지어내지 않는다.
- **wds-prd 템플릿 목표** — 출력은 `../wds-prd/references/prd-template.md` §A One-Page PRD 형식을 따른다.
- **구현 의도 복원** — "무엇(What)"은 코드에서, "왜(Why)·누가(Who)"는 코드+설정+기존 문서에서 복원. 불가 시 `미확인:`.

## 0. 사전 조건

- `PRD.md` / `prd.md` / `docs/PRD.md` 가 이미 있으면 **덮어쓰지 않는다**. 보강/갱신 여부를 먼저 묻는다.
- 분석 대상이 비어 있거나 최소(빈 scaffold)이면 역도출 대신 `/prd` 사용을 권고하고 중단.

## 1. 소스 분석 단계

분석은 **항상 이 순서**로. 각 단계 결과를 다음 단계의 입력으로 사용한다.

### 1.1 프로젝트 탐색 (Inventory)

| 확인 항목 | 방법 | 결과 |
|---|---|---|
| 언어·프레임워크 | `package.json` / `pyproject.toml` / `go.mod` / `Cargo.toml` / `*.csproj` / `build.gradle.kts` | 프로파일 추정 |
| 패키지매니저 | lockfile 종류 (`pnpm-lock.yaml` / `uv.lock` / `poetry.lock` / `go.sum` / `Cargo.lock`) | 빌드 툴 |
| 진입점 | `main.py` / `main.go` / `src/index.ts` / `cmd/*/main.go` / `Application.java` / `Program.cs` | 앱 유형 |
| 서비스 구성 | `docker-compose.yml` 서비스·포트·volumes | 인프라 토폴로지 |
| 환경 변수 | `.env.local` / `.env.prod` / `.env.example` / `appsettings.json` / `config.py` / `config.go` | NFR 단서 |
| 기존 문서 | `README.md` / `README.en.md` / `COMPLIANCE.md` / `AGENTS.md` | 보조 맥락 |

### 1.2 기능 요구사항 추출 (Functional — What)

**라우터·컨트롤러·핸들러**를 1차 소스로 한다.

| 프레임워크 | 분석 대상 |
|---|---|
| FastAPI / Flask / Starlette | `@app.get/post/put/delete/patch`, `APIRouter`, `include_router` |
| NestJS | `@Controller`, `@Get/Post/Put/Delete/Patch`, `@Module` |
| Next.js | `app/*/route.ts`, `pages/api/**`, `app/**/page.tsx` |
| Gin / Echo / Fiber | `router.GET/POST/…`, `r.Group(…)` |
| Spring Boot | `@RestController`, `@GetMapping/PostMapping/…` |
| Axum / Actix | `Router::new().route(…)`, `web::resource(…)` |
| Express / Hono | `app.get/post/…`, `router.use(…)` |

추출 항목:
- **엔드포인트 목록**: 메서드 + 경로 + 요청/응답 스키마(모델에서)
- **기능 그룹**: 라우터 prefix / 컨트롤러 이름 → 기능 도메인 (예: `/auth/*` → 인증)
- **CRUD 패턴**: Create/Read/Update/Delete 각각 구현 여부

### 1.3 데이터 모델 분석 (Data — What + How)

| 분석 대상 | 추출 내용 |
|---|---|
| ORM 모델 (`models.py`, `*.entity.ts`, `@Entity`) | 필드·타입·관계 |
| Prisma / Drizzle / TypeORM 스키마 | ERD |
| DB 마이그레이션 파일 | 이력 기반 스키마 |
| Struct / Pydantic / Zod 정의 | 입력·출력 계약 |

→ 주요 엔티티 + 관계 + 핵심 필드 → PRD `## 7. 기술메모` 데이터 항목

### 1.4 비기능 요구사항 추출 (NFR)

| 단서 | 추출 NFR |
|---|---|
| 환경 변수에 JWT / API_KEY / SECRET | 인증·인가 |
| Dockerfile `limits:` / compose `deploy:` | 성능·자원 제약 |
| `rate_limit`, `throttle`, `@UseGuards`, middleware 체인 | 보안·속도 제한 |
| `CORS`, `AllowOrigin`, `@CrossOrigin` | CORS 정책 |
| `prometheus`, `metrics`, `/health`, `healthcheck` | 관찰가능성 |
| `redis` / `memcached` 서비스 의존 | 캐싱 |
| `https`, `TLS`, `SSL` 설정 | 전송 암호화 |
| `sentry`, `datadog`, `opentelemetry` | 에러 추적·APM |

### 1.5 사용자 흐름 복원 (User Flow)

기존 테스트 파일 있으면 **1차 소스**:
- `test_*.py`, `*.test.ts`, `*_test.go`, `*.spec.ts` → 시나리오 역추적
- E2E / Playwright / Detox 스크립트 → 대표 사용자 여정

테스트 없으면 라우터 호출 순서·세션/토큰 흐름·미들웨어 체인에서 복원.

### 1.6 도메인·업종 힌트 탐지

파일명·함수명·패키지명·주석에서 업종 키워드 감지:

| 키워드 예시 | 매핑 도메인 |
|---|---|
| payment, invoice, settlement, ledger | finance |
| patient, ehr, fhir, clinic, prescription | healthcare |
| cart, order, product, inventory, catalog | commerce |
| shipment, tracking, delivery, warehouse | logistics |
| course, lesson, quiz, grade, enrollment | edtech |
| employee, payroll, hr, attendance | govtech/enterprise |
| sensor, plc, scada, production | manufacturing |
| 감지 불가 | ict-saas (기본) |

도메인 감지 시 `../wds-recommend/references/domains/<id>.yaml` 을 읽어 NFR·규제 후보를 자동 제안
(wds-prd §1-5 동일 방식, 교체 아닌 **제안**).

## 2. 미확인 항목 처리

코드에서 확인 불가한 항목은 `미확인:` 태그 사용. 절대 추측으로 채우지 않는다.

| 항목 | 처리 예시 |
|---|---|
| 비즈니스 목표 (Why) | `미확인: 코드에서 확인 불가. 직접 입력 권장.` |
| 타깃 사용자 (Who) | `미확인: 사용자 유형을 코드에서 추정 불가.` |
| 성공 지표 기준선·목표값 | `미확인: 지표 기준값 없음. 직접 설정 필요.` |
| Out of Scope | `미확인: 코드에 없는 기능은 사용자가 명시 필요.` |

미확인 항목이 3개 이상 + `--yes` 아닌 경우 → **한 번에 묶어 질문**해 채운다.
`--yes` 지정 시 질문 없이 모두 `미확인:` 으로 남기고 즉시 생성.

## 3. PRD 생성 규칙

`../wds-prd/references/prd-template.md` §A One-Page PRD 형식 + 아래 섹션 추가:

```md
## 7. 기술 현황 (Technical Snapshot — 코드 분석 결과)
- 감지 언어/프레임워크:
- 주요 서비스 (docker-compose 기준):
- 감지 엔드포인트 수:
- 주요 엔티티:
- 감지 NFR:
- 기존 테스트 파일 수:
- 분석 기준 날짜:
```

변경 이력 (맨 끝):

```md
## 변경 이력 / Changelog
| 날짜 | 유형 | 내용 | 영향 파일 |
|---|---|---|---|
| YYYY-MM-DD | REVERSE-PRD | 소스코드 역도출 기반 초안 생성 | PRD.md |
```

`--full` 이면 `../wds-prd/references/prd-template.md` §B 풀스펙 섹션(§7 기술메모, §8 Epic)도 추가한다.

## 4. 출력 후 안내

> `PRD.md` 역도출 초안이 생성됐습니다.
> `미확인:` 항목을 검토·보완한 뒤
> `wds-recommend` 로 스택·업종 추천을 이어가거나,
> `wds-test` 로 현재 구현 시험을 바로 진행할 수 있습니다.
