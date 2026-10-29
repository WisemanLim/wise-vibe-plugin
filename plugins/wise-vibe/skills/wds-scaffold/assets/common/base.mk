## ===== wds 공통 타겟 / common targets (docker compose 전용 · 모드 = local | prod) =====
# local : docker-compose.yml + docker-compose.local.yml + .env.local  (소스 바인드/핫리로드, dev 스테이지)
# prod  : docker-compose.yml + docker-compose.prod.yml  + .env.prod   (runtime 스테이지)
# compose/*.yml (scaffold --extras, --local-db 의 db.yml) 은 두 모드에 자동 포함된다.
# docker-compose.workspace.yml (scaffold --workspace) 은 prod 모드에만 포함 — 통합관리 repo 의 공유 네트워크·이미지 태그.
ENV   ?= local
MODES := local prod
SVC   ?=
EXTRA_FILES := $(foreach f,$(sort $(wildcard compose/*.yml)),-f $(f))
DC_local := docker compose -p $(PROJECT)-local -f docker-compose.yml -f docker-compose.local.yml $(EXTRA_FILES) --env-file .env.local
WS_FILE  := $(if $(wildcard docker-compose.workspace.yml),-f docker-compose.workspace.yml)
DC_prod  := docker compose -p $(PROJECT)-prod  -f docker-compose.yml -f docker-compose.prod.yml  $(EXTRA_FILES) $(WS_FILE) --env-file .env.prod
DC = $(DC_$(ENV))

.PHONY: help preflight test shell deploy prod-net \
        $(foreach m,$(MODES),$(m)-all $(m)-build $(m)-logs $(m)-stop $(m)-restart $(m)-ps)

help:  ## 타겟 목록 / list targets
	@grep -hE '^[a-z][a-zA-Z%_-]*:.*## ' $(MAKEFILE_LIST) | sed -E 's/:[^#]*##/\t/' | awk -F'\t' '{printf "  %-14s %s\n", $$1, $$2}'
	@echo "  <mode>-all     [local|prod] 전체 스택 기동 (이미지 없으면 빌드)"
	@echo "  <mode>-build   [local|prod] 이미지 재빌드 후 기동"
	@echo "  <mode>-logs    [local|prod] 로그 추적 (SVC=<service>)"
	@echo "  <mode>-stop    [local|prod] 컨테이너 정리 (볼륨 유지)"
	@echo "  <mode>-restart [local|prod] 재기동 (SVC=<service>)"
	@echo "  <mode>-ps      [local|prod] 컨테이너 상태"
	@[ -z "$(DB_ENGINE)" ] || echo "  db-* 는 ENV=local|prod (기본 local). 예) make db-migrate ENV=prod"

preflight:  ## Docker·Compose v2·환경 파일 점검 / check docker, compose v2, env files
	@command -v docker >/dev/null 2>&1 || { echo "FAIL: Docker 미설치 / not installed"; exit 1; }
	@docker compose version >/dev/null 2>&1 || { echo "FAIL: docker compose v2 필요 / required"; exit 1; }
	@docker info >/dev/null 2>&1 || { echo "FAIL: Docker 데몬 미기동 / daemon not running"; exit 1; }
	@for f in .env.local .env.prod; do [ -f $$f ] || { echo "FAIL: $$f 없음 — cp .env.example $$f"; exit 1; }; done
	@grep -q 'CHANGE_ME' .env.prod && echo "WARN: .env.prod 에 CHANGE_ME placeholder — 실제 배포 전 Secret Manager 로 주입" || true
	@$(DC_local) config -q && $(DC_prod) config -q && echo "=== Preflight OK $(PREFLIGHT_NOTE) ==="

## --- 모드별 수명주기 / lifecycle per mode ---
$(MODES:%=%-all): %-all:
	$(DC_$*) up -d
$(MODES:%=%-build): %-build:
	$(DC_$*) up -d --build
$(MODES:%=%-logs): %-logs:
	$(DC_$*) logs -f $(SVC)
$(MODES:%=%-stop): %-stop:
	$(DC_$*) down --remove-orphans
$(MODES:%=%-restart): %-restart:
	$(DC_$*) restart $(SVC)
$(MODES:%=%-ps): %-ps:
	$(DC_$*) ps

## --- workspace 공유 네트워크 (scaffold --workspace 시 WORKSPACE_NET 지정, 아니면 no-op) ---
prod-net:  ## prod 공유 네트워크 생성 (통합관리 repo 의 서비스 간 별칭 통신)
	@[ -z "$(WORKSPACE_NET)" ] || docker network inspect $(WORKSPACE_NET) >/dev/null 2>&1 || docker network create $(WORKSPACE_NET) >/dev/null
prod-all prod-build deploy: prod-net

## --- 공통 / common ---
test:   ## local dev 컨테이너에서 테스트 실행 (LOCAL_DB 가 RDBMS 면 db 함께 기동)
	$(DC_local) run --rm $(TEST_DEPS) --entrypoint sh $(APP_SVC) -c '$(TEST)'
shell:  ## 앱 컨테이너 셸 (ENV=local|prod)
	$(DC) exec $(APP_SVC) sh
deploy: ## prod 모드 롤아웃 (대상 호스트에서 실행 — 이미지 재빌드 + 재기동)
	@grep -q 'CHANGE_ME' .env.prod && { echo "FAIL: .env.prod 에 CHANGE_ME — 시크릿 주입 후 배포"; exit 1; } || true
	$(DC_prod) up -d --build --remove-orphans
