#!/usr/bin/env bash
# 스캐폴드 매트릭스 (Docker 불필요): 모든 프로파일 × prod DB 로 생성 → 토큰 잔존·금지 파일·compose config·멱등성 점검.
# 사용: tests/test_scaffold.sh [--compose]   (--compose 면 docker compose config 로 두 모드 파일 검증)
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; SC="${ROOT}/plugins/wise-vibe/skills/wds-scaffold/scripts/scaffold.sh"
OUT="${ROOT}/tests/.out/scaffold"; rm -rf "${OUT}"; mkdir -p "${OUT}"
compose=false; [ "${1:-}" = "--compose" ] && compose=true
fail=0; n=0
ok()  { n=$((n+1)); }
bad() { n=$((n+1)); fail=$((fail+1)); echo "  FAIL $*"; }
profiles="$(awk -F'\t' '!/^#/{print $1":"$2}' "${ROOT}/plugins/wise-vibe/skills/wds-scaffold/assets/profiles.tsv")"
for pk in ${profiles}; do
  p="${pk%%:*}"; kind="${pk##*:}"
  [ "${kind}" = workspace ] && continue   # --services 필요 → 아래 전용 블록
  if [ "${kind}" = service ]; then dbs="postgres mysql mariadb sqlite"; [ "${p}" = bio-rag-research ] && dbs="postgres"; else dbs="-"; fi
  for db in ${dbs}; do
    d="${OUT}/${p}-${db}"; args=""; [ "${db}" != "-" ] && args="--db ${db} --extras redis"
    /bin/bash "${SC}" "${p}" ${args} --target "${d}" >/dev/null 2>"${d}.err" \
      && ok || { bad "${p}/${db} scaffold: $(cat "${d}.err")"; continue; }
    grep -rIl '{{[A-Z_]*}}' "${d}" >/dev/null 2>&1 && bad "${p}/${db} 미치환 토큰: $(grep -rIl '{{[A-Z_]*}}' "${d}" | head -3)" || ok
    for f in Procfile.dev ecosystem.config.cjs .env.dev .env.staging; do [ -e "${d}/${f}" ] && bad "${p}/${db} 금지 파일 ${f}" || ok; done
    [ -f "${d}/test/dev-env/scenario.md" ] && ok || bad "${p}/${db} test/dev-env 없음"
    [ -f "${d}/.gitignore" ] && ok || bad "${p}/${db} .gitignore 없음"
    if [ "${kind}" = service ]; then
      for f in Makefile .env.local .env.prod .env.example docker-compose.local.yml docker-compose.prod.yml compose/redis.yml .github/workflows/ci.yml; do
        [ -f "${d}/${f}" ] && ok || bad "${p}/${db} ${f} 없음"; done
      grep -q "^DB_ENGINE=sqlite" "${d}/.env.local" && ok || bad "${p}/${db} local 이 sqlite 아님"
      grep -q "^DB_ENGINE=${db}" "${d}/.env.prod" && ok || bad "${p}/${db} prod DB_ENGINE 불일치"
      if [ "${db}" = sqlite ]; then grep -q '^  db:' "${d}/docker-compose.prod.yml" && bad "${p}/sqlite db 서비스 존재" || ok
      else grep -q '^  db:' "${d}/docker-compose.prod.yml" && ok || bad "${p}/${db} db 서비스 없음"; fi
      git check-ignore -q --no-index 2>/dev/null; (cd "${d}" && git init -q . && git check-ignore -q .env.prod && ! git check-ignore -q .env.local) && ok || bad "${p}/${db} gitignore(.env.prod 무시/.env.local 커밋) 규칙"
      rm -rf "${d}/.git"
      make -s -C "${d}" help >/dev/null 2>&1 && ok || bad "${p}/${db} make help 실패"
      [ ! -e "${d}/docker-compose.workspace.yml" ] && [ ! -e "${d}/compose/db.yml" ] && ok || bad "${p}/${db} 기본형에 workspace/db.yml 생성됨"
      if [ "${compose}" = true ]; then
        (cd "${d}" && docker compose -f docker-compose.yml -f docker-compose.local.yml -f compose/redis.yml --env-file .env.local config -q) && ok || bad "${p}/${db} compose local config"
        (cd "${d}" && docker compose -f docker-compose.yml -f docker-compose.prod.yml -f compose/redis.yml --env-file .env.prod config -q) && ok || bad "${p}/${db} compose prod config"
      fi
    fi
    if [ "${kind}" = web ]; then
      for f in Makefile .env.local .env.prod .env.example docker-compose.local.yml docker-compose.prod.yml nginx/default.conf.template .github/workflows/ci.yml; do
        [ -f "${d}/${f}" ] && ok || bad "${p} ${f} 없음"; done
      grep -q '^API_UPSTREAM=' "${d}/.env.local" && ok || bad "${p} API_UPSTREAM 없음"
      grep -q 'CHANGE_ME' "${d}/.env.prod" && ok || bad "${p} prod API_UPSTREAM 을 명시하도록 강제하지 않음"
      grep -q '^DB_' "${d}/.env.local" && bad "${p} web 에 DB 설정" || ok
      make -s -C "${d}" help >/dev/null 2>&1 && ok || bad "${p} make help 실패"
      if [ "${compose}" = true ]; then
        (cd "${d}" && docker compose -f docker-compose.yml -f docker-compose.local.yml --env-file .env.local config -q) && ok || bad "${p} compose local config"
        (cd "${d}" && docker compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.prod config -q) && ok || bad "${p} compose prod config"
      fi
    fi
    # 멱등: 재실행 시 쓰기 0
    out="$(/bin/bash "${SC}" "${p}" ${args} --target "${d}" 2>&1 | grep '^written=')"
    case "${out}" in written=0*) ok ;; *) bad "${p}/${db} 비멱등: ${out}" ;; esac
  done
done
# --local-db: local 도 prod 와 같은 RDBMS (compose/db.yml 이 두 모드 공통, prod.yml 에 db 없음)
for p in go-gin python-fastapi java-spring; do
  d="${OUT}/${p}-localdb"
  /bin/bash "${SC}" "${p}" --db postgres --local-db postgres --target "${d}" >/dev/null 2>&1 && ok || { bad "${p} --local-db postgres 생성 실패"; continue; }
  grep -q '^DB_ENGINE=postgres' "${d}/.env.local" && ok || bad "${p} --local-db: .env.local DB_ENGINE"
  grep -q '^DB_PASSWORD=local-only-not-secret' "${d}/.env.local" && ok || bad "${p} --local-db: local 고정 비밀번호"
  grep -q 'CHANGE_ME' "${d}/.env.local" && bad "${p} --local-db: .env.local 에 CHANGE_ME" || ok
  [ -f "${d}/compose/db.yml" ] && ok || bad "${p} --local-db: compose/db.yml 없음"
  grep -q '^  db:' "${d}/docker-compose.prod.yml" && bad "${p} --local-db: prod.yml 에 db 중복" || ok
  grep -q '^LOCAL_DB    := postgres' "${d}/Makefile" && grep -q '^TEST_DEPS   :=$' "${d}/Makefile" && ok || bad "${p} --local-db: Makefile LOCAL_DB/TEST_DEPS"
  (cd "${d}" && git init -q . && ! git check-ignore -q .env.local) && ok || bad "${p} --local-db: .env.local 커밋 대상 아님"; rm -rf "${d}/.git"
  if [ "${compose}" = true ]; then
    (cd "${d}" && docker compose -f docker-compose.yml -f docker-compose.local.yml -f compose/db.yml --env-file .env.local config --services | grep -qx db) && ok || bad "${p} --local-db: local compose 에 db 없음"
    (cd "${d}" && docker compose -f docker-compose.yml -f docker-compose.prod.yml -f compose/db.yml --env-file .env.prod config --services | grep -qx db) && ok || bad "${p} --local-db: prod compose 에 db 없음"
  fi
done
/bin/bash "${SC}" go-gin --db postgres --local-db mysql --target "${OUT}/x" >/dev/null 2>&1 && bad "--local-db 엔진 불일치 허용됨" || ok
/bin/bash "${SC}" go-gin --db sqlite --local-db postgres --target "${OUT}/x" >/dev/null 2>&1 && bad "prod sqlite + local postgres 허용됨" || ok

# --workspace: prod 전용 공유 네트워크·이미지 태그 오버레이
for pk in go-gin:api node-next-nest:api react-spa:web; do
  p="${pk%%:*}"; d="${OUT}/${p}-ws"
  /bin/bash "${SC}" "${p}" --workspace demo --target "${d}" >/dev/null 2>&1 && ok || { bad "${p} --workspace 생성 실패"; continue; }
  f="${d}/docker-compose.workspace.yml"
  grep -q 'name: demo-net, external: true' "${f}" && ok || bad "${p} --workspace: 네트워크"
  grep -q 'API_IMAGE\|WEB_IMAGE' "${f}" && ok || bad "${p} --workspace: 이미지 변수"
  grep -q '^WORKSPACE_NET := demo-net' "${d}/Makefile" && ok || bad "${p} --workspace: Makefile WORKSPACE_NET"
  grep -q '{{' "${f}" && bad "${p} --workspace: 미치환 토큰" || ok
  if [ "${compose}" = true ]; then
    (cd "${d}" && make -s -n prod-ps 2>/dev/null | grep -q 'docker-compose.workspace.yml') && ok || bad "${p} --workspace: prod 에 오버레이 미포함"
    (cd "${d}" && make -s -n local-ps 2>/dev/null | grep -q 'docker-compose.workspace.yml') && bad "${p} --workspace: local 에 오버레이 포함됨" || ok
  fi
done
grep -q 'node-next-nest-ws-web' "${OUT}/node-next-nest-ws/docker-compose.workspace.yml" && ok || bad "node-next-nest --workspace: web 서비스 별칭 누락"

# workspace (통합관리 root): 생성물·서브 repo 무시·자체 배포 회귀 시험·멱등
d="${OUT}/ws"
/bin/bash "${SC}" workspace --name demo --services demo-api:api:8380:db,demo-web:web:8390 --target "${d}" >/dev/null 2>"${d}.err" && ok || bad "workspace 생성: $(cat "${d}.err")"
for f in Makefile README.md README.en.md DEPLOY-PROD-GUIDE.md release/release.sh release/services.tsv release/deploy.env.example \
         scripts/prod-secrets.sh scripts/secret-scan.sh test/deploy/test_source_archive.py test/deploy/test_prod_secrets.py \
         test/deploy/scenario.md docs/TEST-OWNERSHIP.md .github/workflows/ci.yml .gitleaks.toml .gitignore; do
  [ -f "${d}/${f}" ] && ok || bad "workspace ${f} 없음"; done
grep -rIl '{{[A-Z_]*}}' "${d}" >/dev/null 2>&1 && bad "workspace 미치환 토큰: $(grep -rIl '{{[A-Z_]*}}' "${d}" | head -3)" || ok
[ -x "${d}/release/release.sh" ] && [ -x "${d}/scripts/prod-secrets.sh" ] && ok || bad "workspace 스크립트 실행 권한"
[ "$(head -2 "${d}/.gitignore" | tail -1)" = "/demo-api/" ] && ok || bad "workspace .gitignore 첫 섹션이 서브 repo 아님"
grep -q '| `demo-web/` | ✔ | web |' "${d}/README.md" && ok || bad "workspace README 서비스 표"
mkdir -p "${d}/demo-api"; echo x > "${d}/demo-api/main.go"
(cd "${d}" && git init -q . && git check-ignore -q demo-api/main.go && git check-ignore -q release/deploy.env && ! git check-ignore -q release/deploy.env.example) && ok || bad "workspace gitignore(서브 repo·deploy.env)"
rm -rf "${d}/.git" "${d}/demo-api"
make -s -C "${d}" test >/dev/null 2>"${d}.test.err" && ok || bad "workspace make test: $(tail -3 "${d}.test.err")"
make -s -C "${d}" help >/dev/null 2>&1 && ok || bad "workspace make help"
bash "${d}/release/release.sh" status --services nope >/dev/null 2>&1; [ $? -eq 2 ] && ok || bad "release.sh 미지 서비스 exit 2 아님"
out="$(/bin/bash "${SC}" workspace --name demo --services demo-api:api:8380:db,demo-web:web:8390 --target "${d}" 2>&1 | grep '^written=')"
case "${out}" in written=0*) ok ;; *) bad "workspace 비멱등: ${out}" ;; esac
/bin/bash "${SC}" workspace --target "${OUT}/x" >/dev/null 2>&1 && bad "workspace --services 없이 허용됨" || ok
/bin/bash "${SC}" workspace --services a:db:1 --target "${OUT}/x" >/dev/null 2>&1 && bad "workspace component 오류 허용됨" || ok
/bin/bash "${SC}" go-gin --services a:api:1 --target "${OUT}/x" >/dev/null 2>&1 && bad "서비스 프로파일에 --services 허용됨" || ok

# 보존 규칙: 사용자 수정 파일은 .generated 로
d="${OUT}/python-fastapi-postgres"; echo "# user" >> "${d}/README.md"
/bin/bash "${SC}" python-fastapi --target "${d}" --extras redis >/dev/null && [ -f "${d}/README.md.generated" ] && grep -q '# user' "${d}/README.md" && ok || bad "보존 규칙(.generated)"
# 잘못된 입력
/bin/bash "${SC}" python-fastapi --db oracle --target "${OUT}/x" >/dev/null 2>&1 && bad "--db oracle 허용됨" || ok
/bin/bash "${SC}" bio-rag-research --db mysql --target "${OUT}/x" >/dev/null 2>&1 && bad "bio-rag mysql 허용됨" || ok
/bin/bash "${SC}" nope --target "${OUT}/x" >/dev/null 2>&1 && bad "미지 프로파일 허용됨" || ok
/bin/bash "${SC}" python-fastapi --target "${OUT}/x" --extras >/dev/null 2>&1 && bad "--extras 값 누락 허용됨" || ok
echo "scaffold checks=${n} fail=${fail}"
[ "${fail}" -eq 0 ]
