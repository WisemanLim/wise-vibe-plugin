#!/usr/bin/env bash
# 멀티 툴 설치기 검증: 도구별 경로, all(정본+링크), 멱등, AGENTS.md 관리 블록, uninstall, user scope.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; I="${ROOT}/install.sh"
OUT="${ROOT}/tests/.out/install"; rm -rf "${OUT}"; mkdir -p "${OUT}"
fail=0; n=0
t() { n=$((n+1)); if eval "$2"; then :; else fail=$((fail+1)); echo "  FAIL $1"; fi; }
for pair in claude:.claude/skills cursor:.cursor/skills antigravity:.agents/skills copilot:.github/skills codex:.agents/skills; do
  tool="${pair%%:*}"; dir="${pair#*:}"
  /bin/bash "${I}" --tool "${tool}" --target "${OUT}/${tool}" >/dev/null 2>&1
  t "${tool} 스킬 10개" "[ \$(ls -d '${OUT}/${tool}/${dir}'/wds-* | wc -l) -eq 10 ]"
  t "${tool} AGENTS.md" "grep -q 'wise-vibe:begin' '${OUT}/${tool}/AGENTS.md'"
done
t "claude agent" "[ -f '${OUT}/claude/.claude/agents/stack-architect.md' ]"
t "antigravity agent" "[ -f '${OUT}/antigravity/.agents/agents/stack-architect.md' ]"
mkdir -p "${OUT}/all"; printf '# mine\n' > "${OUT}/all/CLAUDE.md"; printf '# keep\n' > "${OUT}/all/AGENTS.md"
/bin/bash "${I}" --tool all --target "${OUT}/all" --hooks >/dev/null 2>&1
t "all: .claude 링크" "[ -L '${OUT}/all/.claude/skills/wds-scaffold' ]"
t "all: 링크 경로로 스크립트 실행" "bash '${OUT}/all/.claude/skills/wds-scaffold/scripts/scaffold.sh' --list >/dev/null"
t "all: 기존 AGENTS.md 보존" "grep -q '# keep' '${OUT}/all/AGENTS.md'"
t "all: CLAUDE.md @AGENTS.md" "grep -q '^@AGENTS.md' '${OUT}/all/CLAUDE.md'"
t "all: claude 훅" "python3 -c 'import json;json.load(open(\"${OUT}/all/.claude/settings.json\"))'"
t "all: cursor 훅" "python3 -c 'import json;json.load(open(\"${OUT}/all/.cursor/hooks.json\"))'"
/bin/bash "${I}" --tool all --target "${OUT}/all" >/dev/null 2>&1
t "멱등: 관리 블록 1개" "[ \$(grep -c 'wise-vibe:begin' '${OUT}/all/AGENTS.md') -eq 1 ]"
t "멱등: @AGENTS.md 1줄" "[ \$(grep -c '^@AGENTS.md' '${OUT}/all/CLAUDE.md') -eq 1 ]"
/bin/bash "${I}" --tool all --target "${OUT}/all" --uninstall >/dev/null 2>&1
t "uninstall: 스킬 제거" "! ls -d '${OUT}/all/.agents/skills'/wds-* >/dev/null 2>&1"
t "uninstall: 관리 블록 제거·사용자 내용 보존" "! grep -q wise-vibe '${OUT}/all/AGENTS.md' && grep -q '# keep' '${OUT}/all/AGENTS.md'"
mkdir -p "${OUT}/home"; HOME="${OUT}/home" /bin/bash "${I}" --tool all --scope user >/dev/null 2>&1
for d in .claude/skills .cursor/skills .gemini/config/skills .copilot/skills .agents/skills; do t "user ${d}" "[ -d '${OUT}/home/${d}/wds-prd' ]"; done
t "잘못된 --tool 거부" "! /bin/bash '${I}' --tool vim >/dev/null 2>&1"
echo "install checks=${n} fail=${fail}"
[ "${fail}" -eq 0 ]
