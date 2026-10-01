# {{PROJECT_NAME}} — android-compose (정적 템플릿 / static scaffold template)
# 모드: local(flavor local) | prod(flavor prod) — make setup · local-all · test · prod-build · deploy
.PHONY: preflight setup local-all local-stop test local-build prod-build deploy help
preflight:   ## 툴체인 점검 (JDK·Android SDK)
	java -version && ( [ -n "$$ANDROID_HOME" ] || grep -q sdk.dir local.properties )
help:        ## 타겟 목록
	@grep -hE '^[a-z][a-z-]*:.*## ' $(MAKEFILE_LIST) | sed -E 's/:[^#]*##/\t/' | awk -F'\t' '{printf "  %-16s %s\n", $$1, $$2}'
local-all:   ## [local] 실행 중인 에뮬레이터/기기에 localDebug 설치
	./gradlew installLocalDebug
local-stop:  ## [local] 에뮬레이터 종료
	adb emu kill 2>/dev/null || true
test:        ## 단위 테스트 (localDebug)
	./gradlew testLocalDebugUnitTest
local-build: ## [local] local flavor 디버그 APK
	./gradlew assembleLocalDebug
prod-build:  ## [prod] prod flavor 릴리스 AAB
	./gradlew bundleProdRelease
deploy:      ## Play 내부 트랙 업로드 (fastlane android beta)
	cd fastlane && fastlane android beta

# 최초 1회 실행 / run once after scaffold
setup:       ## 최초 1회 준비 (툴체인·SDK 경로·의존성)
	@# 1) Gradle Wrapper — gradlew 없으면 생성 (Gradle 9.5.1, JDK 25 호환)
	@if [ ! -f gradlew ]; then \
	  echo "[setup] gradlew not found. Running: gradle wrapper --gradle-version 9.5.1"; \
	  gradle wrapper --gradle-version 9.5.1 || \
	    (echo "ERROR: 'gradle' CLI not found. Install: sdk install gradle 9.5.1  (or brew install gradle)" && exit 1); \
	  chmod +x gradlew; \
	fi
	@# 2) local.properties — Android SDK 경로 자동 감지
	@if grep -q '<YOUR_ANDROID_SDK_PATH>' local.properties 2>/dev/null || [ ! -f local.properties ]; then \
	  if [ -d "$$HOME/Library/Android/sdk" ]; then \
	    echo "sdk.dir=$$HOME/Library/Android/sdk" > local.properties; \
	    echo "[setup] local.properties → macOS SDK path"; \
	  elif [ -d "$$USERPROFILE/AppData/Local/Android/Sdk" ]; then \
	    echo "sdk.dir=$$USERPROFILE/AppData/Local/Android/Sdk" > local.properties; \
	    echo "[setup] local.properties → Windows SDK path"; \
	  elif [ -d "$$HOME/Android/Sdk" ]; then \
	    echo "sdk.dir=$$HOME/Android/Sdk" > local.properties; \
	    echo "[setup] local.properties → Linux SDK path"; \
	  else \
	    echo "[setup] WARN: Android SDK not found. Set sdk.dir in local.properties manually."; \
	  fi; \
	fi
	@echo "[setup] Done. Run: make local-all"
