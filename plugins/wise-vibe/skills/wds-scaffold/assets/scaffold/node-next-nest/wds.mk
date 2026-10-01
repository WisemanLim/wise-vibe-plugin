APP_SVC     := api
TEST        ?= pnpm -r test
MIGRATE     ?= echo "TODO: Prisma/Drizzle 등 ORM 마이그레이션을 implement 단계에서 설정"
SEED        ?= echo "TODO: 시드 명령을 implement 단계에서 설정"
SQLITE_PATH := /app/data/app.db
