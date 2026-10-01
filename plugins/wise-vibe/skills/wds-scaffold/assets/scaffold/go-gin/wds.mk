APP_SVC     := api
TEST        ?= go test ./...
MIGRATE     ?= echo "TODO: 마이그레이션 도구(goose/atlas 등)를 implement 단계에서 설정"
SEED        ?= echo "TODO: 시드 명령을 implement 단계에서 설정"
SQLITE_PATH := /app/data/app.db
