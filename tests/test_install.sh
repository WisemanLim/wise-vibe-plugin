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
# 간편 설치(bootstrap): --tool 생략 = 감지 + user scope, --list, --source, 잘림 방지 가드
mkdir -p "${OUT}/h2/.claude" "${OUT}/h2/.codex"
# PATH 제한: 호스트에 설치된 도구(cursor·claude 바이너리)가 감지 결과를 바꾸지 않게
HOME="${OUT}/h2" PATH=/usr/bin:/bin /bin/bash "${I}" >/dev/null 2>&1
t "감지 설치: claude user" "[ -d '${OUT}/h2/.claude/skills/wds-scaffold' ]"
t "감지 설치: codex user(.agents)" "[ -d '${OUT}/h2/.agents/skills/wds-scaffold' ]"
t "감지 설치: 미감지 cursor 미설치" "[ ! -d '${OUT}/h2/.cursor/skills' ]"
t "--list 출력" "HOME='${OUT}/h2' PATH=/usr/bin:/bin /bin/bash '${I}' --list | grep '^  \* claude' >/dev/null"
t "--plugin 안내" "/bin/bash '${I}' --plugin | grep 'plugin install wise-vibe@wise-vibe' >/dev/null"
t "--source 체크아웃 사용" "/bin/bash '${I}' --source '${ROOT}' --tool codex --target '${OUT}/src' >/dev/null 2>&1 && [ -d '${OUT}/src/.agents/skills/wds-prd' ]"
t "--source 잘못된 경로 거부" "! /bin/bash '${I}' --source /nonexistent --list >/dev/null 2>&1"
t "잘린 다운로드는 실행 안 됨" "! head -c 1500 '${I}' | HOME='${OUT}/h3' bash >/dev/null 2>&1 && [ ! -e '${OUT}/h3' ]"
echo "install checks=${n} fail=${fail}"
[ "${fail}" -eq 0 ]
