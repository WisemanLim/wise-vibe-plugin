#!/usr/bin/env bash
# release.sh — build, start and deploy {{PROJECT_NAME}} (sub projects listed in release/services.tsv).
#
# Platforms: macOS (local rehearsal, Docker Desktop) · Linux servers, Debian/Ubuntu and RHEL family.
# Images: linux/amd64 and linux/arm64. Environments: dev | prod (both run the sub repos' prod compose mode).
#
#   release/release.sh doctor   [--remote]                 check prerequisites (local or remote server)
#   release/release.sh build    [--platforms linux/amd64,linux/arm64] [--version V]
#                                                          multi-arch images → release/dist/*.tar.gz + .sha256
#   release/release.sh up       [--env dev|prod] [--version V] [--rebuild]
#                                                          THIS machine: secrets → image → prod compose → migrate → health
#   release/release.sh deploy   --host user@server [--env dev|prod] [--version V] [ssh options]
#                                                          REMOTE server over ssh: ship source + image, run `up` there
#   release/release.sh status   [--remote]                 containers, health, secret status (fingerprints only)
#   release/release.sh down     [--remote]                 stop containers (volumes and secrets kept)
#   release/release.sh rollback --to VERSION --remote      switch `current` to an earlier release and restart
#
# Options (CLI > release/deploy.env > interactive prompt > default; --yes = no prompts):
#   --services <short|repo>,...  (default: all rows of release/services.tsv)   --env dev|prod   --version V   --rebuild   --yes
# SSH options:
#   --host user@server  --ssh-port 22  --ssh-key ~/.ssh/id_ed25519  --remote-dir /opt/{{PROJECT_NAME}}
#   --build-on local|remote   (local: build for the server's arch here and stream the image; remote: build there)
#   --install-deps            install Docker Engine/Compose/openssl/gnupg/make/git on the server (apt or dnf, sudo)
#
# Exit codes: 0 ok · 2 argument/config · 4 connection · 5 verification failed · 8 unsupported (stable for automation).
# Secrets are never typed by a person: scripts/prod-secrets.sh generates them on the target and prints fingerprints.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SERVICES_TSV="$ROOT/release/services.tsv"   # repo  short  component  image_var  has_db  host_port (scaffold --services)
[ -f "$SERVICES_TSV" ] || { echo "ERROR: $SERVICES_TSV missing" >&2; exit 2; }
ALL_SERVICES="$(awk -F'\t' '!/^#/ && NF {print $1}' "$SERVICES_TSV" | tr '\n' ' ')"
NETWORK="{{PROJECT_NAME}}-net"
IMAGE_NS="{{PROJECT_NAME}}"
MIN_COMPOSE="2.20.0"
DIST="$ROOT/release/dist"

die() { echo "ERROR: $*" >&2; exit "${EXIT_CODE:-2}"; }
fail() { EXIT_CODE="$1"; shift; die "$@"; }   # fail <code> <message>
info() { echo "==> $*" >&2; }
warn() { echo "WARN: $*" >&2; }
q() { printf '%q' "$1"; }  # shell-quote for remote command lines

# ---------------------------------------------------------------- options
CMD="${1:-}"; [ -n "$CMD" ] && shift || { sed -n '2,27p' "$0" | sed 's/^# \{0,1\}//'; exit 2; }
[ -f "$ROOT/release/deploy.env" ] && . "$ROOT/release/deploy.env"   # KEY=VALUE defaults (gitignored, no secrets)
SERVICES="${SERVICES:-all}"; VERSION="${VERSION:-}"; PLATFORMS="${PLATFORMS:-}"
TARGET_ENV="${TARGET_ENV:-}"; REMOTE_HOST="${REMOTE_HOST:-}"; SSH_PORT="${SSH_PORT:-22}"; SSH_KEY="${SSH_KEY:-}"
REMOTE_DIR="${REMOTE_DIR:-/opt/{{PROJECT_NAME}}}"; BUILD_ON="${BUILD_ON:-local}"; INSTALL_DEPS="${INSTALL_DEPS:-0}"
YES="${YES:-0}"; REMOTE=0; TO=""; IMAGE_READY=0; REBUILD=0
while [ $# -gt 0 ]; do
  case "$1" in
    --services) SERVICES="$2"; shift ;; --version) VERSION="$2"; shift ;; --platforms) PLATFORMS="$2"; shift ;;
    --env) TARGET_ENV="$2"; shift ;;
    --host) REMOTE_HOST="$2"; shift ;; --ssh-port) SSH_PORT="$2"; shift ;; --ssh-key) SSH_KEY="$2"; shift ;;
    --remote-dir) REMOTE_DIR="$2"; shift ;; --build-on) BUILD_ON="$2"; shift ;; --install-deps) INSTALL_DEPS=1 ;;
    --remote) REMOTE=1 ;; --to) TO="$2"; shift ;; --yes|-y) YES=1 ;; --rebuild) REBUILD=1 ;;
    --image-ready) IMAGE_READY=1 ;;   # internal: images already loaded by `deploy`
    *) die "unknown option: $1" ;;
  esac; shift
done
svc_field() { awk -F'\t' -v r="$1" -v c="$2" '!/^#/ && $1==r {print $c; exit}' "$SERVICES_TSV"; }   # svc_field <repo> <column>
svc_list() {  # --services accepts repo names or short names; "all" = every row
  [ "$SERVICES" = all ] && { echo "$ALL_SERVICES"; return; }
  local out="" s r
  for s in $(echo "$SERVICES" | tr ',' ' '); do
    r="$(awk -F'\t' -v s="$s" '!/^#/ && ($1==s || $2==s) {print $1; exit}' "$SERVICES_TSV")"
    [ -n "$r" ] || die "unknown service: $s (release/services.tsv: $ALL_SERVICES)"
    out="$out $r"
  done; echo "$out"; }
component() { svc_field "$1" 3; }
image_var() { svc_field "$1" 4; }
image_name() { echo "$IMAGE_NS/$(svc_field "$1" 2)-$(component "$1")"; }
has_db() { [ "$(svc_field "$1" 5)" = 1 ]; }

# resolved once in the main shell: a die() inside $(svc_list) would only end the subshell
SELECTED="$(svc_list)" || exit $?

ask() {  # ask VAR "question" default [required]
  local var="$1" question="$2" def="${3:-}" req="${4:-}" cur; eval "cur=\${$var:-}"
  [ -n "$cur" ] && return 0
  if [ "$YES" = 1 ] || [ ! -t 0 ]; then
    [ -n "$def" ] && { eval "$var=\$def"; return 0; }
    [ -n "$req" ] && die "$var required (use a CLI option or release/deploy.env)"
    return 0
  fi
  local ans; read -r -p "$question [${def}]: " ans; eval "$var=\${ans:-\$def}"
  [ -n "$req" ] && eval "[ -n \"\${$var}\" ]" || [ -z "$req" ] || die "$var required"
}

default_version() {  # git describe of the root repo, else date-based
  ( cd "$ROOT" && git describe --tags --always --dirty 2>/dev/null ) || date -u +%Y.%m.%d-%H%M
}

# ---------------------------------------------------------------- doctor
detect_os() {  # → macos | debian | rhel | linux-other
  case "$(uname -s)" in
    Darwin) echo macos ;;
    Linux) . /etc/os-release 2>/dev/null || true
      case " ${ID:-} ${ID_LIKE:-} " in
        *" debian "*|*" ubuntu "*) echo debian ;;
        *" rhel "*|*" fedora "*|*" centos "*|*" rocky "*|*" almalinux "*|*" ol "*) echo rhel ;;
        *) echo linux-other ;; esac ;;
    *) echo unsupported ;;
  esac
}
docker_arch() { case "$(uname -m)" in x86_64|amd64) echo amd64 ;; aarch64|arm64) echo arm64 ;; *) uname -m ;; esac; }
ver_ge() { [ "$(printf '%s\n%s\n' "$2" "$1" | sort -t. -k1,1n -k2,2n -k3,3n | head -1)" = "$2" ]; }

doctor_local() {
  local os missing="" c v; os="$(detect_os)"
  info "os=$os arch=$(docker_arch)"
  [ "$os" = unsupported ] && fail 8 "unsupported OS: $(uname -s)"
  for c in docker openssl make curl tar git; do command -v "$c" >/dev/null 2>&1 || missing="$missing $c"; done
  [ -z "$missing" ] || { install_hint "$os"; fail 5 "missing tools:$missing"; }
  if docker --version 2>/dev/null | grep -qi podman; then fail 8 "podman docker shim is not supported (compose features) — install docker-ce"; fi
  docker info >/dev/null 2>&1 || fail 4 "docker daemon not reachable"
  v="$(docker compose version --short 2>/dev/null | sed 's/^v//')" || true
  [ -n "$v" ] && ver_ge "$v" "$MIN_COMPOSE" || fail 5 "docker compose >= $MIN_COMPOSE required (found: ${v:-none})"
  docker buildx version >/dev/null 2>&1 || warn "docker buildx missing — multi-arch build unavailable"
  [ "$os" = rhel ] && command -v getenforce >/dev/null 2>&1 && info "SELinux: $(getenforce) (secret mounts use :z labels)"
  info "doctor OK (compose $v)"
}
install_hint() {
  case "$1" in
    macos)  echo "  macOS: install Docker Desktop, then: brew install gnupg" >&2 ;;
    debian) echo "  Debian/Ubuntu: release/release.sh deploy --install-deps …" >&2 ;;
    rhel)   echo "  RHEL family:   release/release.sh deploy --install-deps …  (docker-ce repo; podman unsupported)" >&2 ;;
  esac
}
install_deps_local() {  # runs ON the server (via deploy --install-deps), needs sudo
  case "$(detect_os)" in
    debian)
      # official Docker apt repository (no piped install script)
      # os-release is read in subshells: sourcing it here would overwrite this script's VERSION
      local os_id codename; os_id="$(. /etc/os-release; echo "$ID")"; codename="$(. /etc/os-release; echo "$VERSION_CODENAME")"
      sudo apt-get update && sudo apt-get install -y ca-certificates curl git make openssl gnupg tar
      sudo install -m 0755 -d /etc/apt/keyrings
      sudo curl -fsSL "https://download.docker.com/linux/$os_id/gpg" -o /etc/apt/keyrings/docker.asc
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/$os_id $codename stable" \
        | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
      sudo apt-get update
      sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin ;;
    rhel)
      sudo dnf -y remove podman-docker 2>/dev/null || true
      sudo dnf -y install dnf-plugins-core curl git make openssl gnupg2 tar
      sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
      sudo dnf -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
      sudo systemctl enable --now docker ;;
    *) fail 8 "--install-deps supports Debian/Ubuntu and RHEL family only" ;;
  esac
  sudo usermod -aG docker "$(id -un)" || true
  info "dependencies installed — re-login may be needed for docker group membership"
}

# ---------------------------------------------------------------- build
ensure_builder() {  # buildx builder able to target non-native platforms
  docker buildx inspect "$IMAGE_NS-builder" >/dev/null 2>&1 || docker buildx create --name "$IMAGE_NS-builder" >/dev/null
}
build_images() {  # build_images <platforms csv> → release/dist/<svc>-<V>-<arch>.tar.gz (+ .sha256) and local load
  local plats="$1" svc arch img tgz
  mkdir -p "$DIST"; ensure_builder
  for svc in $SELECTED; do
    img="$(image_name "$svc")"
    for arch in $(echo "$plats" | tr ',' ' ' | sed 's#linux/##g'); do
      info "build $svc for linux/$arch → $img:$VERSION-$arch"
      docker buildx build --builder "$IMAGE_NS-builder" --platform "linux/$arch" --target runtime \
        -t "$img:$VERSION-$arch" --load "$ROOT/$svc"
      tgz="$DIST/$svc-$VERSION-$arch.tar.gz"
      docker save "$img:$VERSION-$arch" | gzip -1 > "$tgz"
      ( cd "$DIST" && shasum -a 256 "$(basename "$tgz")" > "$(basename "$tgz").sha256" )
      [ "$arch" = "$(docker_arch)" ] && docker tag "$img:$VERSION-$arch" "$img:$VERSION"
    done
  done
  info "artifacts in $DIST"
}

# ---------------------------------------------------------------- up (this machine)
set_env_key() {  # set_env_key <file> <KEY> <value> — replace or append, comment lines untouched
  local f="$1" k="$2" v="$3" tmp; tmp="$(mktemp)"
  awk -v k="$k" -v v="$v" 'BEGIN{d=0} $0 ~ "^"k"=" {print k"="v; d=1; next} {print} END{if(!d) print k"="v}' "$f" > "$tmp"
  cat "$tmp" > "$f"; rm -f "$tmp"
}
wait_health() {  # wait_health <svc> — every container of the compose project healthy (container healthcheck)
  # A transient "unhealthy" (slow first start) is not final: Docker flips back to healthy on the next
  # successful probe, so only the deadline (HEALTH_TIMEOUT seconds) decides failure.
  local svc="$1" i states
  for i in $(seq 1 "$(( ${HEALTH_TIMEOUT:-180} / 3 ))"); do
    states="$(docker compose -p "$svc-prod" ps --format '{{.Health}}' 2>/dev/null | sort -u | tr '\n' ' ')"
    [ "$states" = "healthy " ] && { info "$svc healthy"; return 0; }
    sleep 3
  done
  docker compose -p "$svc-prod" ps >&2 || true
  fail 5 "$svc not healthy (states: ${states:-none}) — make -C $svc prod-logs"
}
cmd_up() {
  ask TARGET_ENV "Target environment (dev|prod)" prod
  case "$TARGET_ENV" in dev|prod) ;; *) die "--env must be dev or prod" ;; esac
  [ -n "$VERSION" ] || VERSION="$(default_version)"
  doctor_local
  docker network inspect "$NETWORK" >/dev/null 2>&1 || docker network create "$NETWORK" >/dev/null
  local svc img var
  for svc in $SELECTED; do
    [ -d "$ROOT/$svc" ] || fail 2 "$svc checkout missing under $ROOT (separate git repo — clone it next to release/)"
    info "secrets/config for $svc ($TARGET_ENV)"
    "$ROOT/scripts/prod-secrets.sh" init "$svc" --env "$TARGET_ENV"
    img="$(image_name "$svc"):$VERSION"; var="$(image_var "$svc")"
    if [ "$IMAGE_READY" = 1 ]; then
      docker image inspect "$img" >/dev/null 2>&1 || fail 5 "image $img not loaded"
    elif [ "$REBUILD" = 1 ] || ! docker image inspect "$img" >/dev/null 2>&1; then
      info "build $img (native arch)"
      docker build --target runtime -t "$img" "$ROOT/$svc"
    fi
    set_env_key "$ROOT/$svc/.env.prod" "$var" "$img"
    # published host port comes from release/services.tsv (one table for every environment)
    set_env_key "$ROOT/$svc/.env.prod" "$(echo "$(component "$svc")" | tr 'a-z' 'A-Z')_PORT" "$(svc_field "$svc" 6)"
    ( cd "$ROOT/$svc" && make -s prod-all )
    if has_db "$svc"; then ( cd "$ROOT/$svc" && make -s db-migrate ENV=prod ); fi   # explicit — never automatic in prod
    wait_health "$svc"
  done
  info "up OK: $TARGET_ENV $VERSION"
}
cmd_status() {
  local svc
  for svc in $SELECTED; do
    echo "--- $svc"; docker compose -p "$svc-prod" ps 2>/dev/null || echo "(not running)"
    "$ROOT/scripts/prod-secrets.sh" status "$svc" || true
  done
}
cmd_down() { local svc; for svc in $SELECTED; do ( cd "$ROOT/$svc" && make -s prod-stop ); done; }

# ---------------------------------------------------------------- remote
SSH_OPTS=""
ssh_setup() {
  ask REMOTE_HOST "Remote host (user@server)" "" required
  local sock; sock="${TMPDIR:-/tmp}/ws-ssh-$(id -u)-%r@%h:%p"
  SSH_OPTS="-p $SSH_PORT -o ControlMaster=auto -o ControlPath=$sock -o ControlPersist=60 -o BatchMode=yes"
  [ -n "$SSH_KEY" ] && SSH_OPTS="$SSH_OPTS -i $SSH_KEY"
  # shellcheck disable=SC2086
  ssh $SSH_OPTS "$REMOTE_HOST" true 2>/dev/null || fail 4 "ssh to $REMOTE_HOST failed (key auth required)"
}
# SSH_OPTS is intentionally word-split (several options in one string)
# shellcheck disable=SC2086
rsh() { ssh $SSH_OPTS "$REMOTE_HOST" "$@"; }
# shellcheck disable=SC2086
rsh_t() { ssh -t $SSH_OPTS "$REMOTE_HOST" "$@"; }  # with tty (sudo password prompts)

source_tarball() {  # tracked + untracked-not-ignored files of the root and sub repos → stdout (tar)
  # NUL-delimited end to end: git would otherwise octal-quote non-ASCII paths (e.g. Hangul file names).
  local list; list="$(mktemp)"
  ( cd "$ROOT" && git ls-files -z -co --exclude-standard ) > "$list"
  for svc in $ALL_SERVICES; do
    [ -d "$ROOT/$svc/.git" ] || continue
    ( cd "$ROOT/$svc" && git ls-files -z -co --exclude-standard | tr '\0' '\n' | sed "s#^#$svc/#" | tr '\n' '\0' ) >> "$list"
  done
  # defence in depth: never ship env/secret material even if an ignore rule regresses
  tr '\0' '\n' < "$list" | grep -vE '(^|/)\.env\.prod|(^|/)\.secrets/|\.pass$|\.tar\.gpg$|(^|/)deploy\.env$|(^|/)\.state/|(^|/)node_modules/' \
    | tr '\n' '\0' | while IFS= read -r -d '' path; do
      # Deleted-but-tracked entries (moves before commit) are skipped: archive current files only.
      if [ -f "$ROOT/$path" ]; then printf '%s\0' "$path"; fi
    done > "$list.f"
  if [ "$(detect_os)" = macos ]; then
    # bsdtar: no xattrs / AppleDouble (._*) files, which GNU tar on the server would warn about or extract
    ( cd "$ROOT" && COPYFILE_DISABLE=1 tar --no-xattrs --no-mac-metadata --null -cf - -T "$list.f" )
  else
    ( cd "$ROOT" && tar --null -cf - -T "$list.f" )
  fi
  rm -f "$list" "$list.f"
}

cmd_deploy() {
  ssh_setup
  ask TARGET_ENV "Target environment (dev|prod)" prod
  local ros rarch rel base svc img
  ros="$(rsh 'uname -s; uname -m' | tr '\n' ' ')"
  case "$ros" in Linux*) ;; *) fail 8 "remote must be Linux (got: $ros)" ;; esac
  rarch="$(echo "$ros" | awk '{print $NF}')"; case "$rarch" in x86_64|amd64) rarch=amd64 ;; aarch64|arm64) rarch=arm64 ;; *) fail 8 "unsupported arch $rarch" ;; esac
  info "remote: $ros→ linux/$rarch, env=$TARGET_ENV"
  [ -n "$VERSION" ] || VERSION="$(default_version)"
  base="$REMOTE_DIR"; rel="$base/releases/$VERSION"

  if [ "$INSTALL_DEPS" = 1 ]; then
    info "installing prerequisites on the server (sudo)"
    rsh "mkdir -p /tmp/ws-release"; rsh "cat > /tmp/ws-release/release.sh" < "$0"
    rsh_t "bash /tmp/ws-release/release.sh install-deps"
  fi

  info "prepare $rel"
  rsh "mkdir -p $(q "$rel") $(q "$base/shared") 2>/dev/null || { sudo mkdir -p $(q "$rel") $(q "$base/shared") && sudo chown -R \$(id -un):\$(id -gn) $(q "$base"); }"
  info "ship source (git-tracked files only; secrets excluded)"
  source_tarball | gzip -1 | rsh "tar -xzf - -C $(q "$rel")"
  # .env.prod / .secrets live in shared/<svc>/ and are symlinked into each release → survive upgrades/rollbacks.
  rsh "set -e; for s in $ALL_SERVICES; do [ -d $(q "$rel")/\$s ] || continue; mkdir -p $(q "$base")/shared/\$s; ln -sfn ../../../shared/\$s/.env.prod $(q "$rel")/\$s/.env.prod; ln -sfn ../../../shared/\$s/.secrets $(q "$rel")/\$s/.secrets; done; chmod 700 $(q "$base")/shared"

  info "remote doctor"
  rsh "cd $(q "$rel") && bash release/release.sh doctor" || fail 5 "server prerequisites missing — rerun with --install-deps"

  local extra=""
  if [ "$BUILD_ON" = local ]; then
    ensure_builder
    for svc in $SELECTED; do
      img="$(image_name "$svc"):$VERSION"
      info "build $svc for linux/$rarch locally and stream to server"
      docker buildx build --builder "$IMAGE_NS-builder" --platform "linux/$rarch" --target runtime -t "$img" --load "$ROOT/$svc"
      docker save "$img" | gzip -1 | rsh "gunzip | docker load >/dev/null && echo loaded $img"
    done
    extra="--image-ready"
  fi
  info "start on server"
  rsh "cd $(q "$rel") && bash release/release.sh up --yes --env $(q "$TARGET_ENV") --version $(q "$VERSION") --services $(q "$SERVICES") $extra"
  rsh "ln -sfn releases/$(q "$VERSION") $(q "$base")/current"
  info "deploy OK: $REMOTE_HOST $TARGET_ENV $VERSION (current → releases/$VERSION)"
}
remote_current() { rsh "cd $(q "$REMOTE_DIR")/current && bash release/release.sh $1 --yes --services $(q "$SERVICES") $2"; }
cmd_rollback() {
  [ -n "$TO" ] || die "--to VERSION required"
  [ "$REMOTE" = 1 ] || die "rollback is remote only (--remote --host …)"
  ssh_setup
  rsh "[ -d $(q "$REMOTE_DIR")/releases/$(q "$TO") ]" || fail 5 "release $TO not found on server"
  info "switch current → releases/$TO (DB migrations are NOT reverted — irreversible changes need a restore)"
  rsh "ln -sfn releases/$(q "$TO") $(q "$REMOTE_DIR")/current"
  remote_current up "--image-ready --version $(q "$TO") --env $(q "${TARGET_ENV:-prod}")"
}

# ---------------------------------------------------------------- dispatch
case "$CMD" in
  doctor)   if [ "$REMOTE" = 1 ]; then ssh_setup; rsh "cd $(q "$REMOTE_DIR")/current && bash release/release.sh doctor"; else doctor_local; fi ;;
  install-deps) install_deps_local ;;
  build)    [ -n "$VERSION" ] || VERSION="$(default_version)"; build_images "${PLATFORMS:-linux/amd64,linux/arm64}" ;;
  up)       cmd_up ;;
  deploy)   cmd_deploy ;;
  status)   if [ "$REMOTE" = 1 ]; then ssh_setup; remote_current status ""; else cmd_status; fi ;;
  down)     if [ "$REMOTE" = 1 ]; then ssh_setup; remote_current down ""; else cmd_down; fi ;;
  rollback) cmd_rollback ;;
  *) die "unknown command: $CMD (doctor|build|up|deploy|status|down|rollback)" ;;
esac
