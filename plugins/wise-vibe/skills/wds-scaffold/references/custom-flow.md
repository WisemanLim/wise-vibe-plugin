# custom 플로우 — 대화형 스택 선택 (`wds-scaffold custom`)

`custom` 은 템플릿이 아니라 **선택 → 실제 프로파일 + `--db` + `--extras` 로 변환**하는 대화 절차다.
질문 도구(Claude Code `AskUserQuestion` 등)가 있으면 단계별로, 없으면 한 번에 묻는다. ★ = 기본/권장.

| 단계 | 질문 | 선택지 → 인자 |
|------|------|---------------|
| 1 | 유형 | 웹 서비스(서버 API)★ · 모바일 앱 |
| 2a | 백엔드 언어 (웹) | TypeScript/Node★ → `node-next-nest` · Python★ → `python-fastapi` · Go → `go-gin` · Rust → `rust-axum` · Java/Kotlin → `java-spring` · C# → `csharp-dotnet` · C/C++ → `cpp-cmake` |
| 2b | 모바일 | Flutter★ → `flutter-app` · React Native → `react-native-app` · SwiftUI → `ios-swiftui` · Compose → `android-compose` |
| 3 | prod DB (웹) | PostgreSQL★ → `--db postgres` · MySQL → `--db mysql` · MariaDB → `--db mariadb` · SQLite(단일 노드) → `--db sqlite` |
| 4 | 추가 인프라 (웹, 다중) | 없음★ · Redis · Memcached · Kafka · RabbitMQ · MongoDB → `--extras redis,kafka,…` |
| 5 | 업종(KSIC) | 없음 · finance · healthcare · commerce · logistics · manufacturing · govtech · edtech · media-gaming · ict-saas · agriculture · energy-utilities · construction · hospitality → `--domain` (COMPLIANCE.md) |
| 6 | 프로젝트 이름 | 기본: 대상 디렉터리명 → `--name` |

모드는 고정이다: **local = SQLite**, **prod = 3단계 DB**. 실행은 docker compose 전용(호스트 프로세스 매니저 없음).
MongoDB 는 RDBMS 대체가 아니라 `--extras mongodb` 로 추가된다(앱 연결 코드는 implement 단계).

## 결정 요약 (실행 전 출력)

```
프로파일   python-fastapi            prod DB   postgres (기본)
extras     redis                     업종      finance
이름       my-service                대상      ./my-service
명령       scaffold.sh python-fastapi --db postgres --extras redis --name my-service --target ./my-service
```

그다음 일반 절차(SKILL.md §2)로 진행하고, 업종이 있으면 COMPLIANCE.md 를 생성한다.
