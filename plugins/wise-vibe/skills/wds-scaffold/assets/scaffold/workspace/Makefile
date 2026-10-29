# {{PROJECT_NAME}} — 통합관리 repo (wise-vibe wds-scaffold workspace 생성 / generated)
# 배포·릴리스 오케스트레이션만. 서브 프로젝트 빌드·시험은 각 repo 가 소유한다 (release/services.tsv).
.DEFAULT_GOAL := help
SUBREPOS := $(shell awk -F'\t' '!/^\#/ && NF {print $$1}' release/services.tsv)
.PHONY: help test verify-services secret-scan doctor
help: ## 타겟 목록 / list targets
	@grep -hE '^[a-z][a-zA-Z_-]*:.*## ' $(MAKEFILE_LIST) | sed -E 's/:[^#]*##/\t/'
test: ## 배포 시험만: 스크립트 문법 + 소스 아카이브·비밀 init 회귀 (서비스 런타임 불필요)
	@bash -n release/release.sh scripts/prod-secrets.sh scripts/secret-scan.sh
	@python3 -I test/deploy/test_source_archive.py
	@python3 -I test/deploy/test_prod_secrets.py
verify-services: ## (선택) 각 서브 repo 의 preflight·test 위임 — 소스 동기화 없음
	@for s in $(SUBREPOS); do $(MAKE) -C $$s preflight test || exit 1; done
secret-scan: ## gitleaks — root + 서브 repo (git 가시 파일)
	@scripts/secret-scan.sh
doctor: ## 이 머신 릴리스 사전 점검
	@release/release.sh doctor
