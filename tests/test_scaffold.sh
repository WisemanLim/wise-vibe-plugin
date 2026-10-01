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
      if [ "${compose}" = true ]; then
        (cd "${d}" && docker compose -f docker-compose.yml -f docker-compose.local.yml -f compose/redis.yml --env-file .env.local config -q) && ok || bad "${p}/${db} compose local config"
        (cd "${d}" && docker compose -f docker-compose.yml -f docker-compose.prod.yml -f compose/redis.yml --env-file .env.prod config -q) && ok || bad "${p}/${db} compose prod config"
      fi
    fi
    # 멱등: 재실행 시 쓰기 0
    out="$(/bin/bash "${SC}" "${p}" ${args} --target "${d}" 2>&1 | grep '^written=')"
    case "${out}" in written=0*) ok ;; *) bad "${p}/${db} 비멱등: ${out}" ;; esac
  done
done
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
