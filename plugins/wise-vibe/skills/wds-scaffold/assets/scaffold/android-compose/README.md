# {{PROJECT_NAME}}

> 생성: `wise-vibe` 플러그인 `wds-scaffold` · 프로파일 `android-compose` — Android · Kotlin · Jetpack Compose
> English: [README.en.md](README.en.md)

## 모드

모바일 앱은 컨테이너로 실행하지 않는다. 모드는 **local / prod** 두 가지이며 빌드 구성(플레이버)으로 매핑된다.
API 서버가 필요하면 서버 프로파일(예: `python-fastapi`)을 별도로 스캐폴딩한다(docker compose local/prod).

| 모드 | 의미 | 서명 |
|------|------|------|
| local | 시뮬레이터/에뮬레이터 + 로컬 API | debug |
| prod | 스토어 배포 빌드 | release (CI 시크릿/match 로 주입 — 커밋 금지) |

설정: `app/build.gradle.kts` productFlavors `local`(`API_BASE_URL=http://10.0.2.2:8000`, 에뮬레이터→호스트) · `prod`

## 사전 요구사항

JDK 17+, Android SDK(`local.properties` 또는 `ANDROID_HOME`), 에뮬레이터, (배포) fastlane

## 빠른 시작

```bash
make preflight
make setup
make local-all
make test
```

## Make 타겟

| 타겟 | 설명 |
|------|------|
| `make preflight` | 툴체인 점검 (JDK·Android SDK) |
| `make help` | 타겟 목록 |
| `make setup` | 최초 1회 준비 (툴체인·SDK 경로·의존성) |
| `make local-all` | [local] 실행 중인 에뮬레이터/기기에 localDebug 설치 |
| `make local-stop` | [local] 에뮬레이터 종료 |
| `make test` | 단위 테스트 (localDebug) |
| `make local-build` | [local] local flavor 디버그 APK |
| `make prod-build` | [prod] prod flavor 릴리스 AAB |
| `make deploy` | Play 내부 트랙 업로드 (fastlane android beta) |

## 시험

`test/dev-env/`(환경 검증 1회) · `test/impl/<Nth>/`(구현 차수별). 자세한 규칙은 `test/README.md`.
