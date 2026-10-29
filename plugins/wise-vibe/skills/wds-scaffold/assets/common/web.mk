## --- web (정적 SPA) ---
.PHONY: build-web
build-web: ## 운영 정적 빌드(dist) — dev 컨테이너
	$(DC_local) run --rm --no-deps --entrypoint sh $(APP_SVC) -c '$(BUILD)'
