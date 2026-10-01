# {{PROJECT_NAME}}

> 생성: `wise-vibe` 플러그인 `wds-scaffold` · 프로파일 `react-native-app` — React Native (Expo, TypeScript)
> English: [README.en.md](README.en.md)

## 모드

모바일 앱은 컨테이너로 실행하지 않는다. 모드는 **local / prod** 두 가지이며 빌드 구성(플레이버)으로 매핑된다.
API 서버가 필요하면 서버 프로파일(예: `python-fastapi`)을 별도로 스캐폴딩한다(docker compose local/prod).

| 모드 | 의미 | 서명 |
|------|------|------|
| local | 시뮬레이터/에뮬레이터 + 로컬 API | debug |
| prod | 스토어 배포 빌드 | release (CI 시크릿/match 로 주입 — 커밋 금지) |

설정: `.env.local` / `.env.prod`(`EXPO_PUBLIC_*`) + `eas.json` profile `development`(local) / `production`(prod) → `src/core/env.ts`

## 사전 요구사항

Node 22, pnpm, Expo CLI, (빌드) EAS CLI, Xcode/Android SDK

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
| `make preflight` | 툴체인 점검 |
| `make setup` | 의존성 설치 |
| `make local-all` | [local] Expo dev server (.env.local) |
| `make local-stop` | [local] 시뮬레이터/에뮬레이터 종료 |
| `make ios` | iOS 시뮬레이터 네이티브 실행 |
| `make android` | Android 에뮬레이터 네이티브 실행 |
| `make test` | jest + 타입체크 |
| `make local-build` | [local] EAS development 빌드 |
| `make prod-build` | [prod] EAS production 빌드 |
| `make deploy` | 스토어 제출 (eas submit) — OTA: eas update |

## 시험

`test/dev-env/`(환경 검증 1회) · `test/impl/<Nth>/`(구현 차수별). 자세한 규칙은 `test/README.md`.
