#!/usr/bin/env bash
{ # Truncation guard: bash reads the whole brace group before running anything, so a partial `curl | bash` download fails to parse instead of half-running.
set -euo pipefail

# wise-vibe 간편 설치 / easy installer — Agent Skills wds-* (PRD → 추천 → scaffold → 구현·시험·리뷰)
#
#   curl -fsSL https://raw.githubusercontent.com/WisemanLim/wise-vibe-plugin/main/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/WisemanLim/wise-vibe-plugin/main/install.sh | bash -s -- --tool claude,codex
#   curl -fsSL https://raw.githubusercontent.com/WisemanLim/wise-vibe-plugin/main/install.sh | bash -s -- --tool all --target .
#   private repo: gh api -H "Accept: application/vnd.github.raw" repos/WisemanLim/wise-vibe-plugin/contents/install.sh | bash -s -- [options]
#   checkout:     ./install.sh --tool claude|cursor|antigravity|copilot|codex|all [--scope project|user] [--target DIR] ...
#
# 기본 동작: --tool 이 없으면 설치된 도구를 감지(detected)해 사용자 전역(--scope user)에 설치한다.
#            --tool 을 주면 기존과 같이 project 범위(--target, 기본 현재 디렉터리)가 기본이다.
# 이 진입점은 소스를 찾거나 내려받은 뒤 실제 설치기(plugins/wise-vibe/skills/wds-standardize/scripts/install.sh)를 실행한다.

REPO="${WVP_REPO:-WisemanLim/wise-vibe-plugin}"
REF="${WVP_REF:-main}"
TOOL_IDS="claude cursor antigravity copilot codex"
INNER="plugins/wise-vibe/skills/wds-standardize/scripts/install.sh"

say()  { printf '%s\n' "$*"; }
die()  { printf 'wise-vibe install failed: %s\n' "$*" >&2; exit 2; }
has_cmd() { command -v "$1" >/dev/null 2>&1; }

usage() {
  cat <<'EOF'
Usage: install.sh [options]          (all other options are passed to the tool installer)

  --tool <ids>     claude,cursor,antigravity,copilot,codex | all | detected (default when omitted)
  --scope <s>      project (default with --tool) | user (default when --tool is omitted)
  --target <dir>   project install location (default: current directory)
  --mode copy|link --hooks --no-agents-md --force --dry-run --uninstall   (tool installer options)
  --ref <git-ref>  branch/tag to download (default: main, or $WVP_REF)
  --source <path>  use a local checkout instead of downloading
  --list           show version, detected tools and destinations, then exit
  --plugin         print the Claude Code plugin marketplace commands, then exit
  -h, --help       this help
EOF
}

tool_detected() {
  case "$1" in
    claude)      has_cmd claude || [ -d "${CLAUDE_CONFIG_DIR:-$HOME/.claude}" ] ;;
    cursor)      has_cmd cursor || has_cmd cursor-agent || [ -d "$HOME/.cursor" ] ;;
    antigravity) has_cmd antigravity || [ -d "$HOME/.gemini" ] ;;
    copilot)     [ -d "$HOME/.copilot" ] || { has_cmd gh && gh extension list 2>/dev/null | grep -q copilot; } ;;
    codex)       has_cmd codex || [ -d "${CODEX_HOME:-$HOME/.codex}" ] ;;
    *) return 1 ;;
  esac
}
detected_tools() {
  local t out=""
  for t in $TOOL_IDS; do tool_detected "$t" && out="$out,$t"; done
  out="${out#,}"
  [ -n "$out" ] || out="claude,codex"   # nothing detected: Claude Code dir + shared ~/.agents/skills
  echo "$out"
}

# ---------------------------------------------------------------- args (bootstrap options are consumed, the rest forwarded)
tool=""; scope=""; source_dir=""; action="install"; forward=()
while [ $# -gt 0 ]; do
  case "$1" in
    --tool) [ $# -ge 2 ] || die "--tool needs a value"; tool="$2"; shift 2 ;;
    --tool=*) tool="${1#*=}"; shift ;;
    --scope) [ $# -ge 2 ] || die "--scope needs a value"; scope="$2"; shift 2 ;;
    --scope=*) scope="${1#*=}"; shift ;;
    --ref) [ $# -ge 2 ] || die "--ref needs a value"; REF="$2"; shift 2 ;;
    --ref=*) REF="${1#*=}"; shift ;;
    --source) [ $# -ge 2 ] || die "--source needs a value"; source_dir="$2"; shift 2 ;;
    --source=*) source_dir="${1#*=}"; shift ;;
    --list) action="list"; shift ;;
    --plugin) action="plugin"; shift ;;
    -h|--help) usage; exit 0 ;;
    --target|--mode) [ $# -ge 2 ] || die "$1 needs a value"; forward+=("$1" "$2"); shift 2 ;;
    *) forward+=("$1"); shift ;;
  esac
done
if [ -z "$tool" ] || [ "$tool" = detected ]; then
  tool="$(detected_tools)"; [ -n "$scope" ] || scope="user"
fi
[ -n "$scope" ] || scope="project"

if [ "$action" = plugin ]; then
  say "Claude Code (team distribution, auto-update):"
  say "  /plugin marketplace add $REPO"
  say "  /plugin install wise-vibe@wise-vibe"
  exit 0
fi

# ---------------------------------------------------------------- source
cleanup_tmp=""
trap '[ -n "$cleanup_tmp" ] && rm -rf "$cleanup_tmp"' EXIT
resolve_source() {
  if [ -n "$source_dir" ]; then
    [ -f "$source_dir/$INNER" ] || die "--source $source_dir is not a wise-vibe-plugin checkout"
    source_dir="$(cd "$source_dir" && pwd)"; return
  fi
  local here=""
  if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; fi
  if [ -n "$here" ] && [ -f "$here/$INNER" ]; then source_dir="$here"; return; fi
  case " ${forward[*]:-} " in *" --mode link "*) die "--mode link needs a local checkout (--source)" ;; esac
  cleanup_tmp="$(mktemp -d)"
  say "downloading $REPO@$REF ..."
  if curl -fsSL --proto '=https' --tlsv1.2 --retry 3 "https://codeload.github.com/$REPO/tar.gz/$REF" 2>/dev/null | tar -xz -C "$cleanup_tmp" 2>/dev/null; then :
  elif has_cmd gh && say "public download unavailable — trying gh api (private repo)" && gh api "repos/$REPO/tarball/$REF" > "$cleanup_tmp/src.tgz" 2>/dev/null && tar -xzf "$cleanup_tmp/src.tgz" -C "$cleanup_tmp"; then :
  elif has_cmd git && git clone -q --depth 1 --branch "$REF" "https://github.com/$REPO.git" "$cleanup_tmp/repo" 2>/dev/null; then :
  else die "could not download $REPO@$REF (check network, --ref, or gh auth for a private repo)"; fi
  local d; source_dir=""
  for d in "$cleanup_tmp"/*/; do [ -f "${d}$INNER" ] && { source_dir="${d%/}"; break; }; done
  [ -n "$source_dir" ] || die "downloaded archive has no $INNER"
}
version_of() { sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$source_dir/plugins/wise-vibe/plugin.json" 2>/dev/null | head -1; }

resolve_source
if [ "$action" = list ]; then
  say "wise-vibe $(version_of) · source: $source_dir"
  say "tools (detected = *):"
  for t in $TOOL_IDS; do if tool_detected "$t"; then say "  * $t"; else say "    $t"; fi; done
  say "selected: --tool $tool --scope $scope"
  say "skills: $(cd "$source_dir/plugins/wise-vibe/skills" && ls -d wds-*/ | tr -d '/' | tr '\n' ' ')"
  exit 0
fi
say "wise-vibe $(version_of) · tool=$tool · scope=$scope"
bash "$source_dir/$INNER" --tool "$tool" --scope "$scope" ${forward[@]+"${forward[@]}"}
}
