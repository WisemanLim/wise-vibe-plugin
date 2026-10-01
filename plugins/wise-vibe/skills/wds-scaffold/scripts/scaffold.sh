#!/usr/bin/env bash
# wds-scaffold — 결정적 프로젝트 골격 생성기 / deterministic project scaffolder.
#
# 모드 = local | prod (2종), 실행 = docker compose 전용 (호스트 프로세스 매니저 없음).
#   local : SQLite 고정, dev 스테이지 + 소스 바인드
#   prod  : --db 로 RDBMS 선택 (postgres 기본 | mysql | mariadb | sqlite)
#
# 사용 / usage:
#   scaffold.sh <profile-id> [--db postgres|mysql|mariadb|sqlite] [--name NAME] [--target DIR]
#               [--extras redis,kafka,rabbitmq,mongodb,memcached] [--domain <id>] [--force] [--dry-run]
#   scaffold.sh --list
#
# 규칙: 파일만 생성(설치/네트워크 명령 없음), 실시크릿 없음(.env.prod 는 CHANGE_ME),
#       기존 파일이 다르면 덮어쓰지 않고 <file>.generated 로 기록(--force 시 덮어씀).
# bash 3.2 호환 (macOS 기본 bash) — 연관배열·${v,,} 미사용.
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
ASSETS="${SKILL_DIR}/assets"
REGISTRY="${ASSETS}/profiles.tsv"

die() { echo "ERROR: $*" >&2; exit 2; }
usage() { sed -n '2,16p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

profile=""; db="postgres"; name=""; target="$PWD"; extras=""; domain=""; force=false; dry=false
while [ $# -gt 0 ]; do
  case "$1" in
    --list) awk -F'\t' '!/^#/ {printf "  %-18s %-8s %s\n", $1, $2, $9}' "${REGISTRY}"; exit 0 ;;
    --db) [ $# -ge 2 ] || die "--db 값 필요 / value required"; db="$2"; shift ;;
    --db=*) db="${1#*=}" ;;
    --name) [ $# -ge 2 ] || die "--name 값 필요 / value required"; name="$2"; shift ;;
    --name=*) name="${1#*=}" ;;
    --target) [ $# -ge 2 ] || die "--target 값 필요 / value required"; target="$2"; shift ;;
    --target=*) target="${1#*=}" ;;
    --extras) [ $# -ge 2 ] || die "--extras 값 필요 / value required"; extras="$2"; shift ;;
    --domain) [ $# -ge 2 ] || die "--domain 값 필요 / value required"; domain="$2"; shift ;;
    --domain=*) domain="${1#*=}" ;;
    --extras=*) extras="${1#*=}" ;;
    --force) force=true ;;
    --dry-run) dry=true ;;
    -h|--help) usage 0 ;;
    -*) die "알 수 없는 옵션 / unknown option: $1" ;;
    *) [ -z "${profile}" ] && profile="$1" || die "인자 과다 / unexpected arg: $1" ;;
  esac
  shift
done
[ -n "${profile}" ] || usage 1

row="$(awk -F'\t' -v id="${profile}" '$1==id' "${REGISTRY}")"
[ -n "${row}" ] || die "프로파일 없음 / unknown profile '${profile}' (scaffold.sh --list)"
field() { printf '%s\n' "${row}" | awk -F'\t' -v n="$1" '{print $n}'; }
kind="$(field 2)"; tmpl="$(field 3)"; family="$(field 4)"; gi_langs="$(field 5)"
app_svc="$(field 6)"; app_port="$(field 7)"; forced_image="$(field 8)"; title="$(field 9)"

case "${db}" in postgres|mysql|mariadb|sqlite) ;; postgresql|pg) db=postgres ;;
  *) die "--db 는 postgres|mysql|mariadb|sqlite (입력: ${db})" ;; esac
if [ "${forced_image}" != "-" ] && [ "${db}" != "postgres" ]; then
  die "${profile} 는 PostgreSQL(${forced_image}) 전용 — --db postgres 로 실행"
fi
if [ -n "${domain}" ] && [ ! -f "${SKILL_DIR}/../wds-recommend/references/domains/${domain}.yaml" ]; then
  die "업종 없음 / unknown domain '${domain}' (wds-recommend/references/domains/*.yaml)"
fi
for x in $(printf '%s' "${extras}" | tr ',' ' '); do
  [ -f "${ASSETS}/extras/${x}.yml" ] || die "--extras 미지원: ${x} (redis|kafka|rabbitmq|mongodb|memcached)"
done

mkdir -p "${target}"
target="$(cd "${target}" && pwd -P)"
[ -n "${name}" ] || name="$(basename "${target}")"
name="$(printf '%s' "${name}" | tr 'A-Z_ .' 'a-z---' | tr -cd 'a-z0-9-' | sed -e 's/--*/-/g' -e 's/^-//' -e 's/-$//')"
[ -n "${name}" ] || name="app"

stage="$(mktemp -d)"; trap 'rm -rf "${stage}"' EXIT

# ---------------------------------------------------------------- DB 매트릭스
db_port=""; db_ping=""; db_shell=""; db_user="app"; db_pass="CHANGE_ME"
case "${db}" in
  postgres) db_port=5432; db_ping='pg_isready -U "$$POSTGRES_USER" -d "$$POSTGRES_DB"'
            db_shell='psql -U "$$POSTGRES_USER" -d "$$POSTGRES_DB"' ;;
  mysql)    db_port=3306; db_ping='mysqladmin ping -h 127.0.0.1 -u"$$MYSQL_USER" -p"$$MYSQL_PASSWORD" --silent'
            db_shell='mysql -u"$$MYSQL_USER" -p"$$MYSQL_PASSWORD" "$$MYSQL_DATABASE"' ;;
  mariadb)  db_port=3306; db_ping='healthcheck.sh --connect --innodb_initialized'
            db_shell='mariadb -u"$$MARIADB_USER" -p"$$MARIADB_PASSWORD" "$$MARIADB_DATABASE"' ;;
  sqlite)   db_ping='true'; db_shell='true' ;;
esac

# 언어군별 연결 문자열 / connection string per language family
url_for() {  # $1=engine
  case "${family}:$1" in
    python:sqlite)   echo "sqlite:////app/data/app.db" ;;
    python:postgres) echo "postgresql+psycopg://${db_user}:${db_pass}@db:5432/app" ;;
    python:mysql|python:mariadb) echo "mysql+pymysql://${db_user}:${db_pass}@db:3306/app" ;;
    java:sqlite)     echo "jdbc:sqlite:/app/data/app.db" ;;
    java:postgres)   echo "jdbc:postgresql://db:5432/app" ;;
    java:mysql)      echo "jdbc:mysql://db:3306/app" ;;
    java:mariadb)    echo "jdbc:mariadb://db:3306/app" ;;
    csharp:sqlite)   echo "Data Source=/app/data/app.db" ;;
    csharp:postgres) echo "Host=db;Port=5432;Database=app;Username=${db_user};Password=${db_pass}" ;;
    csharp:mysql|csharp:mariadb) echo "Server=db;Port=3306;Database=app;User=${db_user};Password=${db_pass}" ;;
    *:sqlite)        echo "file:/app/data/app.db" ;;
    *:postgres)      echo "postgresql://${db_user}:${db_pass}@db:5432/app" ;;
    *:mysql|*:mariadb) echo "mysql://${db_user}:${db_pass}@db:3306/app" ;;
  esac
}

db_deps() {
  case "${family}:${db}" in
    python:postgres) echo '  "psycopg[binary]>=3.2",' ;;
    python:mysql|python:mariadb) echo '  "pymysql>=1.1",' ;;
    java:*)
      echo '    runtimeOnly("org.xerial:sqlite-jdbc:3.46.1.3")                       // local (SQLite)'
      echo '    implementation("org.hibernate.orm:hibernate-community-dialects")    // SQLiteDialect'
      case "${db}" in
        postgres) echo '    runtimeOnly("org.postgresql:postgresql")                            // prod' ;;
        mysql)    echo '    runtimeOnly("com.mysql:mysql-connector-j")                           // prod' ;;
        mariadb)  echo '    runtimeOnly("org.mariadb.jdbc:mariadb-java-client")                  // prod' ;;
      esac ;;
    csharp:*)
      echo '    <PackageReference Include="Microsoft.EntityFrameworkCore.Sqlite" Version="8.*" />'
      case "${db}" in
        postgres) echo '    <PackageReference Include="Npgsql.EntityFrameworkCore.PostgreSQL" Version="8.*" />' ;;
        mysql|mariadb) echo '    <PackageReference Include="Pomelo.EntityFrameworkCore.MySql" Version="8.*" />' ;;
      esac ;;
  esac
}

# ---------------------------------------------------------------- 스테이징 생성
src="${ASSETS}/scaffold/${tmpl}"
[ -d "${src}" ] || die "템플릿 없음 / template missing: ${src}"
cp -R "${src}/." "${stage}/"

write_service_files() {
  local local_url prod_url env_extra_local="" env_extra_prod=""
  local_url="$(url_for sqlite)"; prod_url="$(url_for "${db}")"
  case "${family}" in
    java)
      env_extra_local="SPRING_PROFILES_ACTIVE=local
SPRING_DATASOURCE_URL=${local_url}"
      env_extra_prod="SPRING_PROFILES_ACTIVE=prod
SPRING_DATASOURCE_URL=${prod_url}
SPRING_DATASOURCE_USERNAME=${db_user}
SPRING_DATASOURCE_PASSWORD=${db_pass}"
      [ "${db}" = "sqlite" ] && env_extra_prod="SPRING_PROFILES_ACTIVE=prod,sqlite
SPRING_DATASOURCE_URL=${prod_url}" ;;
    csharp)
      env_extra_local="ASPNETCORE_ENVIRONMENT=Development
ConnectionStrings__Default=${local_url}"
      env_extra_prod="ASPNETCORE_ENVIRONMENT=Production
ConnectionStrings__Default=${prod_url}" ;;
  esac

  { echo "# ${name} — local 모드 (docker compose · SQLite). 시크릿 없음 → 커밋 가능 / no secrets, committable"
    echo "APP_ENV=local"
    echo "BIND_HOST=127.0.0.1"
    echo "API_PORT=${app_port}"
    [ "${profile}" = "node-next-nest" ] && echo "WEB_PORT=3000"
    echo "DB_ENGINE=sqlite"
    echo "DATABASE_URL=${local_url}"
    [ -n "${env_extra_local}" ] && echo "${env_extra_local}"
  } > "${stage}/.env.local"

  { echo "# ${name} — prod 모드 (docker compose · DB_ENGINE=${db})"
    echo "# CHANGE_ME 는 placeholder — 실제 값은 Secret Manager/Vault/CI 시크릿으로 주입. 이 파일은 커밋 금지(.gitignore)."
    echo "APP_ENV=prod"
    echo "BIND_HOST=127.0.0.1"
    echo "API_PORT=${app_port}"
    [ "${profile}" = "node-next-nest" ] && echo "WEB_PORT=3000"
    echo "DB_ENGINE=${db}"
    if [ "${db}" != "sqlite" ]; then
      echo "DB_HOST=db"
      echo "DB_PORT=${db_port}"
      echo "DB_NAME=app"
      echo "DB_USER=${db_user}"
      echo "DB_PASSWORD=${db_pass}"
      case "${db}" in mysql|mariadb) echo "DB_ROOT_PASSWORD=CHANGE_ME_ROOT" ;; esac
      [ "${forced_image}" != "-" ] && echo "DB_IMAGE=${forced_image}"
    fi
    echo "DATABASE_URL=${prod_url}"
    [ -n "${env_extra_prod}" ] && echo "${env_extra_prod}"
  } > "${stage}/.env.prod"
  { echo "# .env.prod 템플릿 (커밋용) — cp .env.example .env.prod 후 CHANGE_ME 교체"; sed 1,2d "${stage}/.env.prod"; } > "${stage}/.env.example"

  # Makefile = 헤더 + 프로파일 변수(wds.mk) + DB 변수 + 공통 타겟
  { echo "# ${name} — ${profile} (wise-vibe wds-scaffold 생성 / generated)"
    echo "# 모드: local(SQLite) | prod(${db}) — 실행은 docker compose 전용. make help"
    echo "PROJECT     := ${name}"
    cat "${stage}/wds.mk"
    echo "DB_ENGINE   := ${db}"
    printf 'DB_PING     := %s\n' "${db_ping}"
    printf 'DB_SHELL    := %s\n' "${db_shell}"
    echo
    cat "${ASSETS}/common/server.mk"
  } > "${stage}/Makefile"
  rm -f "${stage}/wds.mk"

  if [ -n "${extras}" ]; then
    mkdir -p "${stage}/compose"
    for x in $(printf '%s' "${extras}" | tr ',' ' '); do cp "${ASSETS}/extras/${x}.yml" "${stage}/compose/${x}.yml"; done
  fi

  cat > "${stage}/.dockerignore" <<'EOF'
.git
.env
.env.*
data/
test/**/logs/
node_modules/
**/node_modules/
target/
build/
bin/
obj/
.venv/
__pycache__/
.review/
EOF
  mkdir -p "${stage}/.github/workflows"
  cp "${ASSETS}/common/ci/service.yml" "${stage}/.github/workflows/ci.yml"
  cp "${ASSETS}/common/README.service.md" "${stage}/README.md"
  cp "${ASSETS}/common/README.service.en.md" "${stage}/README.en.md"
  mkdir -p "${stage}/test/dev-env/logs" "${stage}/test/impl"
  cp "${ASSETS}/common/test/README.md" "${stage}/test/README.md"
  cp "${ASSETS}/common/test/dev-env.service.md" "${stage}/test/dev-env/scenario.md"
  touch "${stage}/test/dev-env/logs/.gitkeep" "${stage}/test/impl/.gitkeep"
}

write_mobile_files() {
  mkdir -p "${stage}/test/dev-env/logs" "${stage}/test/impl"
  cp "${ASSETS}/common/test/README.md" "${stage}/test/README.md"
  cp "${ASSETS}/common/test/dev-env.mobile.md" "${stage}/test/dev-env/scenario.md"
  touch "${stage}/test/dev-env/logs/.gitkeep" "${stage}/test/impl/.gitkeep"
}

if [ "${kind}" = "service" ]; then write_service_files; else write_mobile_files; fi

# ---------------------------------------------------------------- 토큰 치환
db_service=""; db_depends=""; db_volumes=""
if [ "${kind}" = "service" ] && [ "${db}" != "sqlite" ]; then
  db_service="$(cat "${ASSETS}/db/${db}.yml")"
  db_depends="    depends_on:
      db: { condition: service_healthy }"
  db_volumes="volumes:
  dbdata:"
fi
export WDS_NAME="${name}" WDS_DB="${db}" WDS_PROFILE="${profile}" WDS_TITLE="${title}" \
       WDS_PORT="${app_port}" WDS_SVC="${app_svc}" WDS_DEPS="$(db_deps)" \
       WDS_DB_SERVICE="${db_service}" WDS_DB_DEPENDS="${db_depends}" WDS_DB_VOLUMES="${db_volumes}"
find "${stage}" -type f ! -name '*.png' ! -name '*.jar' | while IFS= read -r f; do
  grep -q '{{' "$f" 2>/dev/null || continue
  perl -0pi -e '
    for my $k (qw(DB_DEPS DB_SERVICE DB_DEPENDS_ON DB_VOLUMES)) {
      my %m = (DB_DEPS=>"WDS_DEPS", DB_SERVICE=>"WDS_DB_SERVICE", DB_DEPENDS_ON=>"WDS_DB_DEPENDS", DB_VOLUMES=>"WDS_DB_VOLUMES");
      my $v = $ENV{$m{$k}};
      if ($v eq "") { s/^[ \t]*\{\{$k\}\}[ \t]*\n//mg } else { s/^[ \t]*\{\{$k\}\}[ \t]*$/$v/mg }
    }
    s/\{\{PROJECT_NAME\}\}/$ENV{WDS_NAME}/g;   s/\{\{DB_ENGINE\}\}/$ENV{WDS_DB}/g;
    s/\{\{PROFILE_ID\}\}/$ENV{WDS_PROFILE}/g;  s/\{\{PROFILE_TITLE\}\}/$ENV{WDS_TITLE}/g;
    s/\{\{APP_PORT\}\}/$ENV{WDS_PORT}/g;       s/\{\{APP_SVC\}\}/$ENV{WDS_SVC}/g;
  ' "$f"
done

# ---------------------------------------------------------------- .gitignore (섹션 단위 멱등)
gi_new="${stage}/.gitignore.wds"; : > "${gi_new}"
for frag in _common _platform ${gi_langs}; do cat "${ASSETS}/gitignore/${frag}.gitignore" >> "${gi_new}"; echo >> "${gi_new}"; done

# ---------------------------------------------------------------- 대상에 반영
created=0; kept=0; same=0
report() { echo "$1"; }
place() {  # $1 = 스테이지 상대경로
  local rel="$1" from="${stage}/$1" to="${target}/$1"
  if [ -e "${to}" ]; then
    if cmp -s "${from}" "${to}"; then same=$((same+1)); return; fi
    if [ "${force}" != true ]; then
      kept=$((kept+1)); report "KEEP    ${rel}  (기존 파일 보존 → ${rel}.generated)"
      [ "${dry}" = true ] || cp "${from}" "${to}.generated"
      return
    fi
  fi
  created=$((created+1)); report "WRITE   ${rel}"
  if [ "${dry}" != true ]; then mkdir -p "$(dirname "${to}")"; cp "${from}" "${to}"; fi
}
( cd "${stage}" && find . -type f ! -name '.gitignore.wds' | sed 's#^\./##' | sort ) > "${stage}.list"
while IFS= read -r rel; do place "${rel}"; done < "${stage}.list"
rm -f "${stage}.list"

# .gitignore: 없으면 생성, 있으면 누락 섹션(=== 헤더 기준)만 추가
gi="${target}/.gitignore"
if [ ! -f "${gi}" ]; then
  report "WRITE   .gitignore"; [ "${dry}" = true ] || cp "${gi_new}" "${gi}"
else
  awk -v existing="${gi}" '
    BEGIN { while ((getline l < existing) > 0) if (l ~ /^# =====/) have[l]=1 }
    /^# =====/ { emit = !($0 in have); if (emit) print "" }
    emit { print }
  ' "${gi_new}" > "${gi_new}.add"
  if [ -s "${gi_new}.add" ]; then
    report "APPEND  .gitignore (누락 섹션 / missing sections)"
    [ "${dry}" = true ] || cat "${gi_new}.add" >> "${gi}"
  fi
fi

echo "---"
echo "profile=${profile} kind=${kind} name=${name} target=${target}"
[ "${kind}" = "service" ] && echo "modes: local=sqlite · prod=${db}${extras:+ · extras=${extras}}"
[ -n "${domain}" ] && echo "domain=${domain} → COMPLIANCE.md 는 wds-scaffold 스킬 §3 이 domains/${domain}.yaml 로 작성"
echo "written=${created} kept(.generated)=${kept} unchanged=${same}$( [ "${dry}" = true ] && echo ' (dry-run)')"
if [ "${kind}" = "service" ]; then
  echo "next: make preflight → make local-all → curl http://127.0.0.1:${app_port}/health → make test"
  echo "      make prod-all (CHANGE_ME 교체 후) → make db-ping ENV=prod"
else
  echo "next: make setup → make local-all (시뮬레이터/에뮬레이터) → make test"
fi
