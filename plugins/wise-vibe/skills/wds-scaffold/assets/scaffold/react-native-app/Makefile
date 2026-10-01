# {{PROJECT_NAME}} — react-native-app (wise-vibe wds-scaffold)
# 모드: local | prod — .env.local(EXPO_PUBLIC_*) / EAS profile development|production
.PHONY: help preflight setup local-all local-stop ios android test local-build prod-build deploy
help:        ## 타겟 목록
	@grep -hE '^[a-z][a-z-]*:.*## ' $(MAKEFILE_LIST) | sed -E 's/:[^#]*##/\t/' | awk -F'\t' '{printf "  %-12s %s\n", $$1, $$2}'
preflight:   ## 툴체인 점검
	node --version && pnpm --version && pnpm exec expo --version
setup:       ## 의존성 설치
	pnpm install
local-all:   ## [local] Expo dev server (.env.local)
	pnpm expo start
local-stop:  ## [local] 시뮬레이터/에뮬레이터 종료
	xcrun simctl shutdown all 2>/dev/null || true; adb emu kill 2>/dev/null || true
ios:         ## iOS 시뮬레이터 네이티브 실행
	pnpm expo run:ios
android:     ## Android 에뮬레이터 네이티브 실행
	pnpm expo run:android
test:        ## jest + 타입체크
	pnpm test && pnpm exec tsc --noEmit
local-build: ## [local] EAS development 빌드
	eas build -p all --profile development
prod-build:  ## [prod] EAS production 빌드
	eas build -p all --profile production
deploy:      ## 스토어 제출 (eas submit) — OTA: eas update
	eas submit -p all --profile production
