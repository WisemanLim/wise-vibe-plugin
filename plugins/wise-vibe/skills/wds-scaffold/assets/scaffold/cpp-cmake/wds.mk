APP_SVC     := api
TEST        ?= cmake --preset debug >/dev/null && cmake --build build/debug && ctest --test-dir build/debug --output-on-failure
MIGRATE     ?= echo "TODO: 마이그레이션 도구를 implement 단계에서 설정"
SEED        ?= echo "TODO: 시드 명령을 implement 단계에서 설정"
SQLITE_PATH := /app/data/app.db
