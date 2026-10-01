APP_SVC     := api
TEST        ?= pytest -q
MIGRATE     ?= alembic upgrade head
SEED        ?= python -m app.seed
SQLITE_PATH := /app/data/app.db
