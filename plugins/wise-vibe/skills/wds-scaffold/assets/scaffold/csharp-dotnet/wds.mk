APP_SVC     := api
TEST        ?= dotnet test test/Api.Tests
MIGRATE     ?= echo "TODO: dotnet ef migrations 를 implement 단계에서 설정"
SEED        ?= echo "TODO: 시드 명령을 implement 단계에서 설정"
SQLITE_PATH := /app/data/app.db
