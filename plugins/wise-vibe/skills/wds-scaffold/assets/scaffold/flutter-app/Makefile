# {{PROJECT_NAME}} — flutter-app (wise-vibe wds-scaffold)
# 모드: local | prod  — .env.<mode> 를 --dart-define-from-file 로 주입 (서버 compose 는 별도 서버 프로파일)
.PHONY: help preflight setup local-all local-stop ios android test local-build prod-build deploy
DEVICE ?=          # -d ios | -d android | -d <id>
help:        ## 타겟 목록
	@grep -hE '^[a-z][a-z-]*:.*## ' $(MAKEFILE_LIST) | sed -E 's/:[^#]*##/\t/' | awk -F'\t' '{printf "  %-12s %s\n", $$1, $$2}'
preflight:   ## 툴체인 점검 (flutter doctor)
	flutter --version && flutter doctor
setup:       ## 의존성 설치
	flutter pub get
local-all:   ## [local] 시뮬레이터/에뮬레이터 실행 (.env.local)
	flutter run $(DEVICE) --dart-define-from-file=.env.local
local-stop:  ## [local] 시뮬레이터/에뮬레이터 종료
	xcrun simctl shutdown all 2>/dev/null || true; adb emu kill 2>/dev/null || true
ios:         ## iOS 시뮬레이터 실행 (.env.local)
	flutter run -d ios --dart-define-from-file=.env.local
android:     ## Android 에뮬레이터 실행 (.env.local)
	flutter run -d android --dart-define-from-file=.env.local
test:        ## flutter test + analyze
	flutter test && flutter analyze
local-build: ## [local] 디버그 APK (.env.local)
	flutter build apk --debug --dart-define-from-file=.env.local
prod-build:  ## [prod] AAB + IPA (.env.prod)
	flutter build appbundle --dart-define-from-file=.env.prod && flutter build ipa --dart-define-from-file=.env.prod
deploy:      ## 스토어 업로드 (fastlane android beta / ios beta)
	cd fastlane && fastlane android beta   # iOS: fastlane ios beta
