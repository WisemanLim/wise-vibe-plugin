APP_SVC     := api
TEST        ?= cargo test
MIGRATE     ?= echo "TODO: sqlx-cli/refinery 등 마이그레이션 도구를 implement 단계에서 설정"
SEED        ?= echo "TODO: 시드 명령을 implement 단계에서 설정"
SQLITE_PATH := /app/data/app.db
