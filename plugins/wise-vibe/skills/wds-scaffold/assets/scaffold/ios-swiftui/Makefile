# {{PROJECT_NAME}} — ios-swiftui (정적 템플릿 / static scaffold template)
# 모드: local(Debug.xcconfig) | prod(Release.xcconfig) — make setup · local-all · test · prod-build · deploy
.PHONY: preflight setup local-all local-stop test local-build prod-build deploy help
SCHEME ?= App
DEST   ?= platform=iOS\ Simulator,name=iPhone\ 16
preflight:   ## 툴체인 점검
	xcode-select -p && xcodebuild -version
help:        ## 타겟 목록
	@grep -hE '^[a-z][a-z-]*:.*## ' $(MAKEFILE_LIST) | sed -E 's/:[^#]*##/\t/' | awk -F'\t' '{printf "  %-16s %s\n", $$1, $$2}'
local-all:   ## [local] 시뮬레이터 Debug 빌드·실행 (Config/Debug.xcconfig)
	xcodebuild -scheme $(SCHEME) -destination $(DEST) -configuration Debug build
local-stop:  ## [local] 시뮬레이터 종료
	xcrun simctl shutdown all
test:        ## 단위/UI 테스트
	xcodebuild test -scheme $(SCHEME) -destination $(DEST)
local-build: ## [local] Debug 빌드 (Config/Debug.xcconfig)
	xcodebuild -scheme $(SCHEME) -configuration Debug -destination generic/platform=iOS build
prod-build:  ## [prod] Release 빌드 → fastlane ios build (Config/Release.xcconfig)
	cd fastlane && fastlane ios build
deploy:      ## TestFlight 업로드 (fastlane ios beta)
	cd fastlane && fastlane ios beta

# 최초 1회 실행 / run once after scaffold
setup:       ## 최초 1회 준비 (툴체인·SDK 경로·의존성)
	@# 1) Xcode Command Line Tools
	@xcode-select -p > /dev/null 2>&1 || \
	  (echo "ERROR: Xcode CLT not installed. Run: xcode-select --install" && exit 1)
	@echo "[setup] Xcode CLT: $$(xcode-select -p)"
	@xcodebuild -version
	@# 2) 사용 가능한 시뮬레이터 확인 / list available simulators
	@echo "[setup] Available simulators (iOS):"
	@xcrun simctl list devices available | grep "iPhone" | head -8
	@# 3) Swift Package 의존성 resolve
	@echo "[setup] Resolving Swift packages..."
	@swift package resolve 2>/dev/null || echo "[setup] WARN: swift package resolve failed (Xcode project이면 xcodebuild -resolvePackageDependencies 사용)"
	@echo "[setup] Done. Run: make local-all"
