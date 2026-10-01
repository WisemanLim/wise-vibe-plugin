# 모바일 스캐폴딩 트러블슈팅 / Mobile scaffold troubleshooting

스캐폴딩 직후 `make local-all` 실패 시 **`make setup` 먼저 실행**. 수동 처리가 필요한 경우 아래 표 참조.

## §troubleshoot-android — Android 개발환경 초기 에러

| 증상 | 원인 | 해결 |
|------|------|------|
| `./gradlew: No such file or directory` | Gradle Wrapper 미생성 | `gradle wrapper --gradle-version 9.5.1` → `chmod +x gradlew` |
| `Could not parse version string '25.0.3'` | Gradle 8.x 임베디드 Kotlin이 JDK 25 버전 문자열 파싱 불가 | `gradle/wrapper/gradle-wrapper.properties` 의 `distributionUrl` 을 Gradle **9.5.1** 이상으로 변경 |
| `kapt` + JDK 25 에러 (`javacOptions` 관련) | kapt 어노테이션 프로세서가 JDK 25 미지원 | `kapt` → **KSP** 마이그레이션: root `build.gradle.kts` 에 `id("com.google.devtools.ksp") version "2.1.0-1.0.29" apply false`, 각 모듈에 `id("com.google.devtools.ksp")` 추가. `kapt(...)` 의존성을 `ksp(...)` 로 변경 |
| `AndroidManifest.xml` 없음 | scaffold 템플릿 누락 | `app/src/main/AndroidManifest.xml` 생성 (템플릿 `§2` 규칙) |
| `sdk.dir` 없음 / `local.properties` 없음 | Android SDK 경로 미등록 | `make setup` 자동 감지, 또는 `local.properties` 에 수동 설정: macOS=`~/Library/Android/sdk`, Linux=`~/Android/Sdk`, Windows=`%USERPROFILE%\AppData\Local\Android\Sdk` |
| `installDevDebug` 실패 (에뮬레이터 미실행) | `make local-all` 는 실행 중인 에뮬레이터 필요 | Android Studio → AVD Manager → 에뮬레이터 실행 후 `make local-all` |

### Gradle 버전 호환성 (JDK 기준)

| JDK | 최소 Gradle | 권장 Gradle |
|-----|------------|------------|
| 17  | 7.3        | 8.x        |
| 21  | 8.5        | 8.10.x     |
| 25+ | 9.5.1+     | **9.5.1**  |

> 템플릿 기본값: Gradle **9.5.1** (`gradle-wrapper.properties`), KSP **2.1.0-1.0.29**.
> `kapt` 사용 금지 — JDK 25 에서 `javacOptions` 파싱 에러 발생.

## §troubleshoot-ios — iOS 개발환경 초기 에러

| 증상 | 원인 | 해결 |
|------|------|------|
| `xcode-select: error: tool 'xcodebuild' requires Xcode` | Xcode Command Line Tools 미설치 | `xcode-select --install` |
| `xcodebuild: error: 'App' is not a workspace` | SwiftPM 프로젝트에 `.xcworkspace` 없이 `xcodebuild -workspace` 호출 | `xcodebuild -scheme App -destination '...'` (workspace 플래그 제거) |
| `simulator … not found` | DEST 이름이 설치된 시뮬레이터와 불일치 | `xcrun simctl list devices available` 로 확인 후 `make local-all DEST='platform=iOS Simulator,name=<name>'` |
| `swift package resolve` 실패 | SPM 캐시 손상 또는 네트워크 | `rm -rf .build && swift package resolve` |
| 서명 에러 (`CODE_SIGNING_REQUIRED`) | 로컬 빌드에 서명 설정 없음 | `make local-all` 에 `CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO` 추가, 또는 Xcode에서 Team 설정 |
| `Package.resolved` 충돌 | 의존성 버전 불일치 | `rm Package.resolved && swift package resolve` |
| `Filename.xcconfig: error: Unable to find included file` | xcconfig `#include` 경로 오류 | `Config/` 경로와 xcconfig `#include` 경로 일치 확인 |

> SPM 프로젝트(Package.swift) vs Xcode 프로젝트(.xcodeproj/.xcworkspace) 혼용 시:
> - SPM만 사용 → `xcodebuild -scheme … -destination …` (workspace 불필요)
> - Xcode 프로젝트 사용 → `xcodebuild -workspace … -scheme … -destination …`
