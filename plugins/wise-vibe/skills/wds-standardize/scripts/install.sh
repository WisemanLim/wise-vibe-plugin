#!/usr/bin/env bash
# wise-vibe 멀티 툴 설치기 / multi-tool installer
#
# 사용 / usage:
#   install.sh --tool <claude|cursor|antigravity|copilot|codex|all> [--scope project|user]
#              [--target DIR] [--mode copy|link] [--hooks] [--no-agents-md] [--force] [--dry-run] [--uninstall]
#
#   --tool       배포 대상 도구 (쉼표로 여러 개 가능: cursor,codex)
#   --scope      project(기본: --target 의 저장소에 설치) | user(홈 디렉터리 전역 설치)
#   --target     project 설치 위치 (기본: 현재 디렉터리)
#   --mode       copy(기본) | link(정본을 심볼릭 링크 — 플러그인 소스를 지우면 깨짐)
#   --hooks      SessionStart 훅 설치 (claude: .claude/settings.json, cursor: .cursor/hooks.json — 없을 때만 생성)
#   --no-agents-md  AGENTS.md 관리 블록을 쓰지 않음
#   --force      이미 설치된 wds-* 스킬을 교체 (기본: 다르면 건너뛰고 보고)
#   --dry-run    변경 없이 계획만 출력
#   --uninstall  wds-* 스킬·에이전트·AGENTS.md 관리 블록 제거
#
# 도구별 설치 경로 (project / user):
#   claude       .claude/skills  .claude/agents        | ~/.claude/skills  ~/.claude/agents
#   cursor       .cursor/skills  .cursor/agents        | ~/.cursor/skills  ~/.cursor/agents
#   antigravity  .agents/skills  .agents/agents        | ~/.gemini/config/skills  ~/.gemini/config/agents
#   copilot      .github/skills                        | ~/.copilot/skills
#   codex        .agents/skills                        | ~/.agents/skills
#   all (project) .agents/skills 정본 + .claude/skills 상대 링크 + .claude/agents + .agents/agents
# bash 3.2 호환.
set -euo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
SKILLS_SRC="$(cd "${SELF_DIR}/../.." && pwd -P)"          # plugins/wise-vibe/skills
PLUGIN_ROOT="$(cd "${SKILLS_SRC}/.." && pwd -P)"          # plugins/wise-vibe
AGENTS_TPL="${SELF_DIR}/../assets/AGENTS.md"
HOOK_SRC="${PLUGIN_ROOT}/scripts/detect-prd.sh"

die() { echo "ERROR: $*" >&2; exit 2; }
usage() { sed -n '2,27p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

tools=""; scope="project"; target="$PWD"; mode="copy"; hooks=false; agents_md=true; force=false; dry=false; uninstall=false
while [ $# -gt 0 ]; do
  case "$1" in
    --tool) tools="${2:-}"; shift ;;
    --tool=*) tools="${1#*=}" ;;
    --scope) scope="${2:-}"; shift ;;
    --scope=*) scope="${1#*=}" ;;
    --target) target="${2:-}"; shift ;;
    --target=*) target="${1#*=}" ;;
    --mode) mode="${2:-}"; shift ;;
    --mode=*) mode="${1#*=}" ;;
    --hooks) hooks=true ;;
    --no-agents-md) agents_md=false ;;
    --force) force=true ;;
    --dry-run) dry=true ;;
    --uninstall) uninstall=true ;;
    -h|--help) usage 0 ;;
    *) die "알 수 없는 인자 / unknown arg: $1 (--help)" ;;
  esac
  shift
done
[ -n "${tools}" ] || { echo "ERROR: --tool 필요 / required" >&2; usage 1; }
case "${scope}" in project|user) ;; *) die "--scope 는 project|user" ;; esac
case "${mode}" in copy|link) ;; *) die "--mode 는 copy|link" ;; esac
tools="$(printf '%s' "${tools}" | tr ',' ' ')"
for t in ${tools}; do
  case "${t}" in claude|cursor|antigravity|copilot|codex|all) ;; *) die "지원하지 않는 --tool: ${t}" ;; esac
done
if [ "${scope}" = "project" ]; then mkdir -p "${target}"; target="$(cd "${target}" && pwd -P)"; base="${target}"; else base="${HOME}"; fi

SKILLS="$(cd "${SKILLS_SRC}" && ls -d wds-*/ | tr -d '/')"
run() { if [ "${dry}" = true ]; then echo "DRY     $*"; else "$@"; fi; }
note() { echo "$1"; }

# ---------------------------------------------------------------- 경로 표
skills_dir() {  # $1=tool
  if [ "${scope}" = "project" ]; then
    case "$1" in claude) echo ".claude/skills" ;; cursor) echo ".cursor/skills" ;; antigravity|codex) echo ".agents/skills" ;; copilot) echo ".github/skills" ;; esac
  else
    case "$1" in claude) echo ".claude/skills" ;; cursor) echo ".cursor/skills" ;; antigravity) echo ".gemini/config/skills" ;; copilot) echo ".copilot/skills" ;; codex) echo ".agents/skills" ;; esac
  fi
}
agents_dir() {
  if [ "${scope}" = "project" ]; then
    case "$1" in claude) echo ".claude/agents" ;; cursor) echo ".cursor/agents" ;; antigravity) echo ".agents/agents" ;; *) echo "" ;; esac
  else
    case "$1" in claude) echo ".claude/agents" ;; cursor) echo ".cursor/agents" ;; antigravity) echo ".gemini/config/agents" ;; *) echo "" ;; esac
  fi
}

# ---------------------------------------------------------------- 설치 단위
install_skill() {  # $1=dest-dir(abs) $2=skill $3=copy|link-to(abs path)
  local dst="$1/$2" how="$3"
  if [ -e "${dst}" ] || [ -L "${dst}" ]; then
    if [ "${how}" != "copy" ] && [ -L "${dst}" ] && [ "$(readlink "${dst}")" = "${how}" ]; then note "SAME    ${dst}"; return; fi
    if [ "${how}" = "copy" ] && [ ! -L "${dst}" ] && diff -rq "${SKILLS_SRC}/$2" "${dst}" >/dev/null 2>&1; then note "SAME    ${dst}"; return; fi
    if [ "${force}" != true ]; then note "SKIP    ${dst} (이미 있음 — --force 로 교체)"; return; fi
    run rm -rf "${dst}"
  fi
  run mkdir -p "$1"
  if [ "${how}" = "copy" ]; then run cp -R "${SKILLS_SRC}/$2" "${dst}"; note "COPY    ${dst}"
  else run ln -s "${how}" "${dst}"; note "LINK    ${dst} -> ${how}"; fi
}
install_skills() {  # $1=tool
  local d; d="${base}/$(skills_dir "$1")"
  for s in ${SKILLS}; do
    if [ "${mode}" = "link" ]; then install_skill "${d}" "${s}" "${SKILLS_SRC}/${s}"; else install_skill "${d}" "${s}" copy; fi
  done
}
install_agent() {  # $1=tool
  local d; d="$(agents_dir "$1")"; [ -n "${d}" ] || return 0
  d="${base}/${d}"; run mkdir -p "${d}"
  if [ -f "${d}/stack-architect.md" ] && ! cmp -s "${PLUGIN_ROOT}/agents/stack-architect.md" "${d}/stack-architect.md" && [ "${force}" != true ]; then
    note "SKIP    ${d}/stack-architect.md (다름 — --force)"; return
  fi
  run cp "${PLUGIN_ROOT}/agents/stack-architect.md" "${d}/stack-architect.md"; note "AGENT   ${d}/stack-architect.md"
}

managed_block() {  # AGENTS.md 관리 블록 / managed block
  echo "<!-- wise-vibe:begin (wds-standardize 가 관리 — 이 블록 안은 수정하지 마세요) -->"
  cat "${AGENTS_TPL}"
  echo "<!-- wise-vibe:end -->"
}
write_agents_md() {
  [ "${scope}" = "project" ] && [ "${agents_md}" = true ] || return 0
  local f="${base}/AGENTS.md" tmp
  tmp="$(mktemp)"; managed_block > "${tmp}"
  if [ ! -f "${f}" ]; then
    run cp "${tmp}" "${f}"; note "WRITE   AGENTS.md"
  elif grep -q '<!-- wise-vibe:begin' "${f}"; then
    if [ "${dry}" != true ]; then
      awk -v blk="${tmp}" '
        /<!-- wise-vibe:begin/ { while ((getline l < blk) > 0) print l; skip=1; next }
        /<!-- wise-vibe:end -->/ { skip=0; next }
        !skip { print }' "${f}" > "${f}.wds" && mv "${f}.wds" "${f}"
    fi
    note "UPDATE  AGENTS.md (관리 블록 교체)"
  else
    if [ "${dry}" != true ]; then { echo; cat "${tmp}"; } >> "${f}"; fi
    note "APPEND  AGENTS.md (관리 블록 추가 — 기존 내용 보존)"
  fi
  rm -f "${tmp}"
}
claude_md_import() {  # Claude Code 는 CLAUDE.md 가 있으면 AGENTS.md 를 읽지 않음 → @AGENTS.md 임포트
  [ "${scope}" = "project" ] && [ "${agents_md}" = true ] || return 0
  local f="${base}/CLAUDE.md"
  [ -f "${f}" ] || { note "INFO    CLAUDE.md 없음 — Claude Code 가 AGENTS.md 를 직접 읽음"; return 0; }
  grep -q '^@AGENTS.md' "${f}" && { note "SAME    CLAUDE.md (@AGENTS.md 있음)"; return 0; }
  if [ "${dry}" != true ]; then printf '\n@AGENTS.md\n' >> "${f}"; fi
  note "APPEND  CLAUDE.md ← @AGENTS.md"
}
install_hooks() {  # $1=tool
  [ "${hooks}" = true ] && [ "${scope}" = "project" ] || return 0
  case "$1" in
    claude)
      run mkdir -p "${base}/.claude/hooks"; run cp "${HOOK_SRC}" "${base}/.claude/hooks/wds-detect-prd.sh"
      if [ -f "${base}/.claude/settings.json" ]; then
        note "MANUAL  .claude/settings.json 존재 — hooks.SessionStart 에 추가: {\"type\":\"command\",\"command\":\"bash .claude/hooks/wds-detect-prd.sh\"}"
      else
        [ "${dry}" = true ] || cat > "${base}/.claude/settings.json" <<'EOF'
{
  "hooks": {
    "SessionStart": [
      { "hooks": [ { "type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/wds-detect-prd.sh\"" } ] }
    ]
  }
}
EOF
        note "WRITE   .claude/settings.json (SessionStart)"
      fi ;;
    cursor)
      run mkdir -p "${base}/.cursor/hooks"; run cp "${HOOK_SRC}" "${base}/.cursor/hooks/wds-detect-prd.sh"
      if [ -f "${base}/.cursor/hooks.json" ]; then
        note "MANUAL  .cursor/hooks.json 존재 — hooks.sessionStart 에 추가: {\"command\":\"bash .cursor/hooks/wds-detect-prd.sh\"}"
      else
        [ "${dry}" = true ] || cat > "${base}/.cursor/hooks.json" <<'EOF'
{
  "version": 1,
  "hooks": {
    "sessionStart": [ { "command": "bash .cursor/hooks/wds-detect-prd.sh" } ]
  }
}
EOF
        note "WRITE   .cursor/hooks.json (sessionStart)"
      fi ;;
    *) note "INFO    $1: SessionStart 훅 없음 — AGENTS.md 의 'PRD 없으면 wds-prd' 지침으로 대체" ;;
  esac
}

uninstall_tool() {  # $1=tool
  local d; d="${base}/$(skills_dir "$1")"
  for s in ${SKILLS}; do [ -e "${d}/${s}" ] || [ -L "${d}/${s}" ] && { run rm -rf "${d}/${s}"; note "REMOVE  ${d}/${s}"; }; done
  local a; a="$(agents_dir "$1")"
  [ -n "${a}" ] && [ -f "${base}/${a}/stack-architect.md" ] && { run rm -f "${base}/${a}/stack-architect.md"; note "REMOVE  ${base}/${a}/stack-architect.md"; }
  return 0
}
uninstall_agents_md() {
  local f="${base}/AGENTS.md"
  [ "${scope}" = "project" ] && [ -f "${f}" ] && grep -q '<!-- wise-vibe:begin' "${f}" || return 0
  if [ "${dry}" != true ]; then
    awk '/<!-- wise-vibe:begin/{skip=1;next} /<!-- wise-vibe:end -->/{skip=0;next} !skip{print}' "${f}" > "${f}.wds" && mv "${f}.wds" "${f}"
  fi
  note "REMOVE  AGENTS.md 관리 블록"
}

# ---------------------------------------------------------------- 실행
echo "wise-vibe install — tools=[${tools}] scope=${scope} base=${base} mode=${mode}$( [ "${dry}" = true ] && echo ' (dry-run)')"
if [ "${uninstall}" = true ]; then
  for t in ${tools}; do
    if [ "${t}" = all ]; then for x in claude cursor antigravity copilot codex; do uninstall_tool "${x}"; done; else uninstall_tool "${t}"; fi
  done
  uninstall_agents_md
  exit 0
fi

for t in ${tools}; do
  case "${t}" in
    all)
      if [ "${scope}" = "user" ]; then
        for x in claude cursor antigravity copilot codex; do install_skills "${x}"; install_agent "${x}"; done
      else
        install_skills antigravity                                   # .agents/skills 정본 (Cursor·Antigravity·Codex·Copilot 판독)
        for s in ${SKILLS}; do                                       # Claude Code 는 .agents 를 읽지 않음 → 상대 링크
          if [ "${mode}" = "copy" ]; then install_skill "${base}/.claude/skills" "${s}" "../../.agents/skills/${s}"
          else install_skill "${base}/.claude/skills" "${s}" "${SKILLS_SRC}/${s}"; fi
        done
        install_agent claude; install_agent antigravity             # Cursor 는 .claude/agents 도 판독
        install_hooks claude; install_hooks cursor
      fi ;;
    *) install_skills "${t}"; install_agent "${t}"; install_hooks "${t}" ;;
  esac
done
write_agents_md
case " ${tools} " in *" claude "*|*" all "*) claude_md_import ;; esac

echo "---"
case " ${tools} " in *" claude "*) echo "Claude Code 팀 배포는 플러그인 권장: /plugin marketplace add WisemanLim/wise-vibe-plugin → /plugin install wise-vibe@wise-vibe" ;; esac
echo "호출: Claude Code /wds-<name> (플러그인 설치 시 /wise-vibe:wds-<name>) · Cursor/Antigravity/Copilot /wds-<name> · Codex \$wds-<name>"
echo "도구를 재시작/리로드하면 스킬을 인식합니다."
