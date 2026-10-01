# Profile schema (확장 지점 / extension point)

각 `*.yaml` 파일은 하나의 **스택 프로파일**이다. 새 도메인/스택을 추가하려면 이
스키마를 따르는 YAML 한 개를 이 디렉터리에 추가하면 된다. 명령어·스킬이 런타임에
이 디렉터리를 스캔하므로 코드 수정은 필요 없다.

> A profile is pure data. Adding a new `*.yaml` here = adding a new selectable
> stack. No command/skill code changes required — this is the extensibility seam.

## 필드 (fields)

```yaml
id: node-next-nest                # 고유 ID (파일명과 일치). kebab-case.
title: "Node (Next.js + NestJS)"  # 사람이 읽는 이름
kind: service                     # service(기본, 생략 가능) | mobile. 모바일은 아래 §모바일 참조.
status: stable                    # stable | preview | experimental
summary: >                        # 1~2문장 요약
  React 기반 풀스택. 프론트 Next.js, 백엔드 NestJS, 언어 공유.
when_to_use:                      # 선택 가이드 (추천 로직이 매칭에 사용)
  - "프론트-백엔드 언어를 통일하고 싶을 때"
  - "BFF / API Gateway 가 필요할 때"
avoid_when:                       # 비추천 조건
  - "무거운 수치/ML 연산이 핵심일 때 (→ python-fastapi)"

languages:                        # 우선순위 언어 매핑
  primary: node
  also: [typescript]

package_managers:                 # 선택지. default 가 1순위.
  default: pnpm
  allowed: [pnpm, npm]
  notes: "yarn/bun 은 승인제."

layers:                           # FE/BE/DB/Ops/App 표준
  frontend:
    framework: "Next.js (App Router)"
    ui: "React + TypeScript + Tailwind"
    test: "Vitest + Playwright"
  backend:
    framework: "NestJS"
    orm: "Prisma"
    rpc: "gRPC (optional)"
  database:
    default: postgres
    local: sqlite                 # local/test 기본
    cache: redis
  ops:
    ci: "GitHub Actions"
    container: "Docker + Docker Compose"
    deploy: "Kubernetes + Helm + Argo CD"
  app: null                       # 해당 없으면 null

run_methods:                      # docker compose 전용 (호스트 프로세스 매니저 없음)
  container:
    local: "make local-all"
    prod: "make prod-all"

environments:                     # 모드 2종: local / prod
  local: { db: sqlite, compose: "docker-compose.yml + docker-compose.local.yml", notes: "SQLite 고정" }
  prod:  { db: postgres, db_options: [postgres, mysql, mariadb, sqlite], compose: "docker-compose.yml + docker-compose.prod.yml" }

scaffold:                         # 생성할 디렉터리 트리 (상대경로)
  tree:
    - "apps/web/"                 # Next.js
    - "apps/api/"                 # NestJS
    - "packages/shared/"
    - "docker/"
    - ".github/workflows/"
  files:                          # 생성할 핵심 파일 (스캐폴더가 내용 채움)
    - "Makefile"
    - "docker-compose.yml"
    - "apps/web/package.json"
    - "apps/api/package.json"
    - ".env.local"
    - ".github/workflows/ci.yml"

makefile_targets:                 # 공통 Make 진입점
  mode_family: "<mode>-all|-build|-logs|-stop|-restart|-ps (mode = local|prod)"
  test: "pnpm test (Vitest) + e2e (Playwright)"
  build: "Docker 이미지 빌드"
  deploy: "Helm/Argo 로 배포"

references:                       # 표준 근거 (원본 문서 섹션)
  - "Perplexity-개발환경 표준화.md §1 Frontend, §2 Backend"
```

## 규칙 (rules)

- `id` 는 파일명(확장자 제외)과 반드시 일치.
- `environments` 는 항상 `local/prod` 2개 키를 가진다 (wise-vibe 표준).
- `database.local` 은 항상 `sqlite`, prod 는 `--db` 로 `postgres`(기본)·`mysql`·`mariadb`·`sqlite` 중 선택.
- 새 서버 프로파일은 `wds-scaffold/assets/profiles.tsv` 한 줄 + `assets/scaffold/<id>/`(Dockerfile dev/runtime 스테이지, compose 3종, `wds.mk`) 를 함께 추가한다.
- 도메인 특화 프로파일(예: 규제/보안)은 `extends:` 로 베이스 프로파일을 상속할 수 있다.
  예) bio-rag-research 는 python-fastapi + node-next-nest 를 조합.

## 프로파일(스택) vs 도메인(업종) — 두 축 (two axes)

이 디렉터리(`profiles/`)는 **무엇으로 만드나(스택)** 를 정의한다. **어떤 업종이라 무엇을 더
지켜야 하나(규제·데이터등급·인프라·시험)** 는 `../domains/*.yaml` 오버레이가 정의하며,
`../domains/_schema.md` 를 따른다. 둘은 직교하고, 추천은 **프로파일 × 도메인** 으로 해석한다.

- 가벼운 업종 특성 → `domains/*.yaml` 오버레이 한 개 추가(스택 편향 + 규제 델타). 권장.
- 스택 자체가 업종에 강결합(역할분리 RAG 등) → 여기 `profiles/*.yaml` + `extends:` 로 작성(예: bio-rag-research).

## 모바일 프로파일 (`kind: mobile`)

모바일 앱은 서버 프로파일(`kind: service`)과 구조가 달라 일부 필드를 **재해석**한다.
서버 프로파일은 변경 없음 — 아래는 `kind: mobile` 일 때만 적용된다.
스킬(`wds-recommend`, `wds-scaffold`, `wds-implement`)은
`kind` 로 분기한다.

핵심 차이:

| 개념 | 서버(`service`) | 모바일(`mobile`) |
| --- | --- | --- |
| DB | `database.default`(postgres) + `local`(sqlite) + `cache` | `database.local_store`(온디바이스: CoreData/Room/Drift/SQLite) + `database.remote`(페어링 API) |
| 모드 2종 | local(SQLite) / prod(RDBMS) compose | **빌드 플레이버/스킴**(flavor) → `api_base` + `signing` 매핑 |
| 실행 | `run_methods.container` (docker compose local/prod) | `run_methods.simulator/ios/android/release` (Xcode/Emulator/flutter run) |
| 컨테이너 | docker-compose + 서비스별 Dockerfile | **없음** (앱은 컨테이너화 안 함; 페어링 백엔드만 별도 프로파일에서) |
| 배포 | docker compose prod (`make deploy`) | **Fastlane → TestFlight / Play** (서명·스토어 트랙) |
| CI | linux 러너 | iOS 빌드는 **macOS 러너** 필요 + Fastlane |
| 시험 | pytest/Vitest/go test/cargo test | XCTest/XCUITest · JUnit+Espresso · flutter test+integration_test · Jest+Detox/Maestro |

모바일 전용/재해석 필드:

```yaml
kind: mobile
platforms: [ios, android]          # 지원 타깃. 네이티브 단일이면 [ios] 또는 [android].

languages:
  primary: dart                    # swift | kotlin | dart | node(RN). gitignore 프래그먼트 키로도 사용.
  also: []                         # RN 은 [typescript].

package_managers:
  default: pub                     # SwiftPM | Gradle | pub | pnpm(RN/Expo)
  allowed: [pub]
  notes: "SDK 버전 핀 권장(fvm/asdf 등)."

layers:
  frontend:                        # 모바일 UI 레이어
    framework: "Flutter (Material 3 / Cupertino)"
    state: "Riverpod / Provider"
    navigation: "go_router"
    test: "flutter test + integration_test"
  backend: null                    # 앱 단독. 백엔드 필요 시 extends 로 서버 프로파일 결합(아래 규칙).
  database:
    local_store: "Drift (SQLite) / Hive / Isar"   # 온디바이스 영속화
    remote: "REST/GraphQL via Dio"                 # 페어링 백엔드(별도 프로파일)
  ops:
    ci: "GitHub Actions (iOS 빌드는 macOS 러너) + Fastlane"
    signing: "iOS: match/ASC API key · Android: keystore(Play)"
    deploy: "Fastlane → TestFlight / Play(internal)"
    quality: "flutter analyze + dart format"
  app: "Flutter (iOS + Android)"   # 모바일은 app 레이어가 핵심(서버는 보통 null)

run_methods:                       # 시뮬레이터/에뮬레이터/디바이스. direct/container 대신.
  simulator: "flutter run"
  ios: "flutter run -d ios"
  android: "flutter run -d android"
  release: "flutter build ipa / appbundle"

environments:                      # 2종 키 = 빌드 플레이버 + API base + 서명
  local: { flavor: local, api_base: "http://localhost:8000", signing: debug,   notes: "시뮬레이터, 디버그 서명" }
  prod:  { flavor: prod,  api_base: "https://api.example",   signing: release, notes: "App Store / Play" }

scaffold:
  tree: [ ... ]                    # 플랫폼별 프로젝트 레이아웃(아래 project-scaffolder §모바일)
  files: [ ... ]                   # 매니페스트(pubspec/Package.swift/build.gradle.kts/package.json) + Fastfile + Makefile

testing:
  framework: "flutter test + integration_test (+ Maestro e2e optional)"
  dir: "test/"                     # 시험표준 증빙(scenario/result/logs). Flutter/RN 의 코드테스트(*_test.dart, __tests__)와 공존(러너가 .md 무시).
  dev_env: "test/dev-env/"         # 모바일 dev-env = SDK/툴체인 확인 + 시뮬레이터 부팅 + 디버그 빌드 성공
  impl: "test/impl/<Nth>/"
  cycle: "시나리오→빌드·실행→오류시 수정·재시험→결과작성"
```

### 모바일 규칙 (rules)
- `kind: mobile` 이면 `environments` 의 의미는 **DB/compose 가 아니라 빌드 플레이버 + `api_base` + `signing`**.
  wds-scaffold 는 플레이버 설정(`lib/core/env.dart`+`.env.local/.env.prod`, `xcconfig` Debug/Release, `build.gradle` flavor local/prod, `eas.json`)을 생성.
- `database.local_store` 는 온디바이스, `database.remote` 는 페어링 백엔드(별도 서버 프로파일). 서버 DB(postgres)·compose·Dockerfile 은 **앱에 생성하지 않는다**.
- **백엔드 결합**: 모바일 프로파일은 앱 단독이 기본. API 가 필요하면 별도로 서버 프로파일을 스캐폴딩하거나
  `extends: [react-native-app, python-fastapi]` 처럼 결합한다(결합 시 모노레포: `apps/mobile/` + `apps/api/`).
- gitignore: `languages.primary`(swift/kotlin/dart/node) → `wds-scaffold/assets/gitignore/{swift,android,flutter,react-native}.gitignore`.
  매핑: swift→swift, kotlin→android, dart→flutter, RN(node)→react-native (+ node 공통).
