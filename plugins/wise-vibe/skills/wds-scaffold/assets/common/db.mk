.PHONY: db-ping db-shell db-migrate db-seed db-reset db-fresh

## --- DB (ENV=local|prod, 기본 local) ---
# 모드별 엔진: local = LOCAL_DB (기본 sqlite, --local-db 로 RDBMS 선택), prod = DB_ENGINE
MODE_DB = $(if $(filter prod,$(ENV)),$(DB_ENGINE),$(LOCAL_DB))
db-ping:     ## DB 연결 확인 (sqlite=파일 경로 · RDBMS=db 컨테이너 헬스)
ifeq ($(MODE_DB),sqlite)
	$(DC) run --rm --no-deps --entrypoint sh $(APP_SVC) -c 'mkdir -p $(dir $(SQLITE_PATH)) && echo "sqlite OK: $(SQLITE_PATH)"'
else
	$(DC) exec -T db sh -c '$(DB_PING)' && echo "$(MODE_DB) OK ($(ENV))"
endif
db-shell:    ## DB 클라이언트 접속 (RDBMS 전용, ENV=local|prod)
	@[ "$(MODE_DB)" != "sqlite" ] || { echo "db-shell 은 RDBMS 전용 (SQLite: $(SQLITE_PATH))"; exit 1; }
	$(DC) exec db sh -c '$(DB_SHELL)'
db-migrate:  ## 마이그레이션 적용 (MIGRATE 변수)
	$(DC) run --rm --entrypoint sh $(APP_SVC) -c '$(MIGRATE)'
db-seed:     ## 시드 적재 (SEED 변수)
	$(DC) run --rm --entrypoint sh $(APP_SVC) -c '$(SEED)'
db-reset:    ## [local 전용] SQLite 삭제 또는 RDBMS 스키마 재생성 + 마이그레이션 — prod 거부
ifeq ($(ENV),prod)
	@echo "prod DB reset 금지 / refused"; exit 1
else ifeq ($(LOCAL_DB),sqlite)
	$(DC_local) run --rm --no-deps --entrypoint sh $(APP_SVC) -c 'rm -f $(SQLITE_PATH)'
	$(MAKE) db-migrate ENV=local
else
	$(DC_local) exec -T db sh -c '$(DB_RESET)'
	$(MAKE) db-migrate ENV=local
endif
db-fresh: db-reset  ## [local 전용] db-reset + db-seed
	$(MAKE) db-seed ENV=local
