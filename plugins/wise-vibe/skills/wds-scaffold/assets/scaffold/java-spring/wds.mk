APP_SVC     := api
TEST        ?= gradle test --no-daemon --project-cache-dir /tmp/gradle-test
MIGRATE     ?= echo "TODO: Flyway/Liquibase 를 implement 단계에서 설정 (현재 ddl-auto)"
SEED        ?= echo "TODO: 시드 명령을 implement 단계에서 설정"
SQLITE_PATH := /app/data/app.db
