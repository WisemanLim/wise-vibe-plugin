#!/usr/bin/env bash
# Docker 실기동 e2e: scaffold → local(헬스·test·db-ping) → prod(헬스·db-ping·migrate) → 정리.
# 사용: tests/e2e_docker.sh <profile> <db> <host-port>   예) tests/e2e_docker.sh python-fastapi postgres 18080
set -u
p=$1; db=$2; port=$3
ROOT=$(cd "$(dirname "$0")/.." && pwd); SC=$ROOT/plugins/wise-vibe/skills/wds-scaffold/scripts/scaffold.sh; S=$ROOT/tests/.out/docker; mkdir -p $S
d=$S/v2-$p-$db; rm -rf $d
/bin/bash $SC $p --db $db --target $d >/dev/null || { echo "$p/$db SCAFFOLD FAIL"; exit 1; }
cd $d
sed -i '' "s/^API_PORT=.*/API_PORT=$port/; s/^WEB_PORT=.*/WEB_PORT=$((port+1))/" .env.local .env.prod
proj=$(awk '/^PROJECT/{print $3}' Makefile)
wait_healthy(){ # $1=mode
  for i in $(seq 1 120); do
    ids=$(docker ps -q --filter "label=com.docker.compose.project=$proj-$1")
    [ -n "$ids" ] || { sleep 5; continue; }
    st=$(docker inspect -f '{{.Name}}={{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' $ids | sort | tr '\n' ' ')
    case "$st" in *starting*|*unhealthy*|*restarting*) sleep 5 ;; *) echo "$st"; return 0 ;; esac
  done; echo "TIMEOUT $st"; return 1; }
fails=0
r(){ echo "== $p/$db $1"; case "$1" in *FAIL*|*TIMEOUT*|*"exit="[1-9]*|*unhealthy*) fails=$((fails+1)) ;; esac; }
make local-build > l-local.txt 2>&1; r "local-build exit=$?"
r "local healthy: $(wait_healthy local)"
r "local health: $(curl -s http://127.0.0.1:$port/health)"
make test > l-test.txt 2>&1; r "test exit=$?"
r "local db-ping: $(make db-ping 2>&1 | tail -1)"
make local-stop >/dev/null 2>&1
make prod-build > l-prod.txt 2>&1; r "prod-build exit=$?"
r "prod healthy: $(wait_healthy prod)"
r "prod health: $(curl -s http://127.0.0.1:$port/health)"
r "prod db-ping: $(make db-ping ENV=prod 2>&1 | tail -1)"
r "prod migrate: $(make db-migrate ENV=prod >/dev/null 2>&1 && echo ok || echo FAIL)"
make prod-stop >/dev/null 2>&1
docker compose -p $proj-local down -v >/dev/null 2>&1; docker compose -p $proj-prod down -v >/dev/null 2>&1
r "DONE fails=${fails}"
[ "${fails}" -eq 0 ]
