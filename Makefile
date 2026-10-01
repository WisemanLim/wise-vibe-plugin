# wise-vibe-plugin 저장소 점검 / repository checks
.PHONY: help validate test test-docker clean
PROFILE ?= python-fastapi
DB      ?= postgres
PORT    ?= 18080

help:         ## 타겟 목록
	@grep -hE '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | sed -E 's/:[^#]*##/\t/' | awk -F'\t' '{printf "  %-12s %s\n", $$1, $$2}'
validate:     ## 스킬 사양·YAML·JSON·버전 + 셸 문법 + claude plugin validate(있으면)
	python3 tests/validate_skills.py
	@for f in install.sh plugins/wise-vibe/scripts/*.sh plugins/wise-vibe/skills/*/scripts/*.sh tests/*.sh; do bash -n $$f || exit 1; done; echo "bash -n OK"
	@if command -v shellcheck >/dev/null; then shellcheck -S error install.sh plugins/wise-vibe/scripts/*.sh plugins/wise-vibe/skills/*/scripts/*.sh && echo "shellcheck OK"; fi
	@if command -v claude >/dev/null; then claude plugin validate . && claude plugin validate plugins/wise-vibe; fi
test: validate ## 스캐폴드 매트릭스 + 설치기 + 문서 추출 (Docker 있으면 compose config 포함)
	bash tests/test_scaffold.sh $$(docker compose version >/dev/null 2>&1 && echo --compose)
	bash tests/test_install.sh
	bash tests/test_extract.sh
test-docker:  ## Docker 실기동 e2e (PROFILE= DB= PORT=)
	bash tests/e2e_docker.sh $(PROFILE) $(DB) $(PORT)
clean:        ## 테스트 산출물 삭제
	rm -rf tests/.out .wds
