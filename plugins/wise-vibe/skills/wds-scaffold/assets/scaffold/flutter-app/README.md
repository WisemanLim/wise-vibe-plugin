# {{PROJECT_NAME}}

> 생성: `wise-vibe` 플러그인 `wds-scaffold` · 프로파일 `flutter-app` — Flutter (Dart, iOS + Android)
> English: [README.en.md](README.en.md)

## 모드

모바일 앱은 컨테이너로 실행하지 않는다. 모드는 **local / prod** 두 가지이며 빌드 구성(플레이버)으로 매핑된다.
API 서버가 필요하면 서버 프로파일(예: `python-fastapi`)을 별도로 스캐폴딩한다(docker compose local/prod).

| 모드 | 의미 | 서명 |
|------|------|------|
| local | 시뮬레이터/에뮬레이터 + 로컬 API | debug |
| prod | 스토어 배포 빌드 | release (CI 시크릿/match 로 주입 — 커밋 금지) |

설정: `.env.local` / `.env.prod` → `--dart-define-from-file` → `lib/core/env.dart`

## 사전 요구사항

Flutter SDK(stable), Xcode(iOS)/Android SDK, (배포) fastlane

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
| `make help` | 타겟 목록 |
| `make preflight` | 툴체인 점검 (flutter doctor) |
| `make setup` | 의존성 설치 |
| `make local-all` | [local] 시뮬레이터/에뮬레이터 실행 (.env.local) |
| `make local-stop` | [local] 시뮬레이터/에뮬레이터 종료 |
| `make ios` | iOS 시뮬레이터 실행 (.env.local) |
| `make android` | Android 에뮬레이터 실행 (.env.local) |
| `make test` | flutter test + analyze |
| `make local-build` | [local] 디버그 APK (.env.local) |
| `make prod-build` | [prod] AAB + IPA (.env.prod) |
| `make deploy` | 스토어 업로드 (fastlane android beta / ios beta) |

## 시험

`test/dev-env/`(환경 검증 1회) · `test/impl/<Nth>/`(구현 차수별). 자세한 규칙은 `test/README.md`.
