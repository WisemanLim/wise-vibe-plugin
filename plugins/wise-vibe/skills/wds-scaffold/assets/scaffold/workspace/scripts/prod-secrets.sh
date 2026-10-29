#!/usr/bin/env bash
# prod-secrets.sh — create and inspect a sub project's .env.prod / .secrets/ on the TARGET machine.
#
#   scripts/prod-secrets.sh init   <svc> [--env dev|prod]   create missing values only (re-run keeps existing ones)
#   scripts/prod-secrets.sh status <svc>                    permissions, fingerprints, CHANGE_ME / consistency
#
# <svc> = repo or short name from release/services.tsv
# Values are generated with `openssl rand -hex` and never printed — only SHA-256 fingerprints (first 8 hex).
# Rotation, backup and restore are project-specific follow-ups (see DEPLOY-PROD-GUIDE.md).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
die() { echo "ERROR: $*" >&2; exit 2; }
fp() { printf '%s' "$1" | openssl dgst -sha256 | awk '{print substr($NF,1,8)}'; }
mode_of() { stat -f '%Lp' "$1" 2>/dev/null || stat -c '%a' "$1"; }   # BSD (macOS) or GNU stat
get_key() { awk -F= -v k="$2" '$0 ~ "^"k"=" {sub("^[^=]*=",""); print; exit}' "$1"; }
set_key() {  # set_key <file> <KEY> <value> — value never echoed; comment lines untouched
  local f="$1" k="$2" v="$3" tmp; tmp="$(mktemp)"
  awk -v k="$k" -v v="$v" 'BEGIN{d=0} $0 ~ "^"k"=" {print k"="v; d=1; next} {print} END{if(!d) print k"="v}' "$f" > "$tmp"
  cat "$tmp" > "$f"; rm -f "$tmp"
}

CMD="${1:-}"; SVC="${2:-}"; [ -n "$CMD" ] && [ -n "$SVC" ] || { sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 2; }
shift 2
TSV="$ROOT/release/services.tsv"
[ -f "$TSV" ] || die "$TSV missing"
REPO="$(awk -F'\t' -v s="$SVC" '!/^#/ && ($1==s || $2==s) {print $1; exit}' "$TSV")"
[ -n "$REPO" ] || die "unknown service: $SVC (release/services.tsv)"
SVC="$REPO"
TARGET_ENV=prod
while [ $# -gt 0 ]; do case "$1" in --env) TARGET_ENV="$2"; shift ;; *) die "unknown option: $1" ;; esac; shift; done
case "$TARGET_ENV" in dev|prod) ;; *) die "--env must be dev or prod" ;; esac

DIR="$ROOT/$SVC"; ENVF="$DIR/.env.prod"; SECRETS="$DIR/.secrets"
[ -d "$DIR" ] || die "$SVC checkout missing: $DIR"

rebuild_url() {  # keep scheme (postgresql:// or postgresql+psycopg://), rebuild the rest from DB_* keys
  local scheme url; url="$(get_key "$ENVF" DATABASE_URL)"; scheme="${url%%://*}"
  [ -n "$scheme" ] && [ "$scheme" != "$url" ] || scheme=postgresql
  printf '%s://%s:%s@%s:%s/%s' "$scheme" "$(get_key "$ENVF" DB_USER)" "$(get_key "$ENVF" DB_PASSWORD)" \
    "$(get_key "$ENVF" DB_HOST)" "$(get_key "$ENVF" DB_PORT)" "$(get_key "$ENVF" DB_NAME)"
}

cmd_init() {
  umask 077
  if [ ! -f "$ENVF" ]; then
    [ -f "$DIR/.env.example" ] || die "$DIR/.env.example missing"
    # on a deploy target .env.prod is a symlink into shared/ (release.sh deploy) that may still dangle:
    # write the link target itself, because cp refuses to write through a dangling symlink
    local dest="$ENVF"
    if [ -L "$ENVF" ]; then dest="$(cd "$DIR" && cd "$(dirname "$(readlink .env.prod)")" && pwd)/$(basename "$(readlink "$ENVF")")"; fi
    cp "$DIR/.env.example" "$dest"; echo "created .env.prod from .env.example"
  fi
  if [ -L "$SECRETS" ] && [ ! -d "$SECRETS" ]; then mkdir -p "$(cd "$DIR" && cd "$(dirname "$(readlink .secrets)")" && pwd)/$(basename "$(readlink "$SECRETS")")"; fi
  # keys added to the template since the last init are appended with their template value
  local k
  for k in $(grep -E '^[A-Z_]+=' "$DIR/.env.example" | cut -d= -f1); do
    grep -q "^$k=" "$ENVF" || { set_key "$ENVF" "$k" "$(get_key "$DIR/.env.example" "$k")"; echo "added missing key $k"; }
  done
  set_key "$ENVF" APP_ENV "$TARGET_ENV"
  if grep -q '^DB_PASSWORD=' "$ENVF"; then
    if [ "$(get_key "$ENVF" DB_PASSWORD)" = CHANGE_ME ]; then
      local pw; pw="$(openssl rand -hex 24)"   # hex: no URL encoding / shell quoting issues
      set_key "$ENVF" DB_PASSWORD "$pw"; echo "DB_PASSWORD generated (fp $(fp "$pw"))"
    fi
    set_key "$ENVF" DATABASE_URL "$(rebuild_url)"
  fi
  # secret://file/run/secrets/<name> references → one generated file per name under .secrets/
  local name
  for name in $(grep -oE 'secret://file/run/secrets/[A-Za-z0-9_.-]+' "$ENVF" | sed 's#.*/##' | sort -u); do
    mkdir -p "$SECRETS"; chmod 750 "$SECRETS"
    if [ ! -s "$SECRETS/$name" ]; then
      local tmp; tmp="$(mktemp "$SECRETS/.tmp.XXXXXX")"; openssl rand -hex 32 > "$tmp"; chmod 440 "$tmp"; mv -f "$tmp" "$SECRETS/$name"
      echo "secret $name generated"
    fi
  done
  chmod 600 "$ENVF"
  if grep -vE '^\s*#' "$ENVF" | grep -q CHANGE_ME; then echo "FAIL: CHANGE_ME left in .env.prod" >&2; exit 5; fi
  echo "OK: no CHANGE_ME left ($SVC, APP_ENV=$TARGET_ENV)"
}

cmd_status() {
  [ -f "$ENVF" ] || { echo ".env.prod                  MISSING (!)"; exit 5; }
  local bad=0 v url
  printf '%-26s %s\n' ".env.prod" "$(mode_of "$ENVF")"
  printf '%-26s %s\n' "APP_ENV" "$(get_key "$ENVF" APP_ENV)"
  if grep -q '^DB_PASSWORD=' "$ENVF"; then
    v="$(get_key "$ENVF" DB_PASSWORD)"
    if [ "$v" = CHANGE_ME ] || [ -z "$v" ]; then printf '%-26s %s\n' DB_PASSWORD "CHANGE_ME (!)"; bad=1
    else printf '%-26s set fp %s\n' DB_PASSWORD "$(fp "$v")"; fi
    url="$(get_key "$ENVF" DATABASE_URL)"
    if [ "$url" = "$(rebuild_url)" ]; then printf '%-26s %s\n' DATABASE_URL consistent; else printf '%-26s %s\n' DATABASE_URL "MISMATCH (!)"; bad=1; fi
  fi
  if [ -d "$SECRETS" ]; then
    printf '%-26s %s\n' ".secrets/" "$(mode_of "$SECRETS")"
    local f; for f in "$SECRETS"/*; do [ -f "$f" ] || continue
      printf '%-26s mode %s fp %s\n' "$(basename "$f")" "$(mode_of "$f")" "$(fp "$(cat "$f")")"; done
  fi
  [ "$bad" = 0 ] || exit 5
}

case "$CMD" in init) cmd_init ;; status) cmd_status ;; *) die "unknown command: $CMD (init|status)" ;; esac
