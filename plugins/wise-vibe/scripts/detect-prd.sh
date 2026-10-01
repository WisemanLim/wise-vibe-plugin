#!/usr/bin/env bash
# SessionStart 훅 (Claude Code 플러그인 · 설치기 --hooks 로 Cursor 에도 등록 가능)
#   PRD.md 가 없으면 wds-prd, 있으면 다음 단계를 1줄 안내. 스캐폴딩 흔적(Makefile/compose)이 있으면 침묵.
#   출력은 stdout → 에이전트 컨텍스트에 추가된다. 조용하게 동작한다.
set -euo pipefail
dir="${CLAUDE_PROJECT_DIR:-${CURSOR_PROJECT_DIR:-$PWD}}"

if [[ -f "${dir}/Makefile" || -f "${dir}/docker-compose.yml" ]]; then exit 0; fi

prd=""
for c in "PRD.md" "prd.md" "docs/PRD.md" "docs/prd.md"; do
  if [[ -f "${dir}/${c}" ]]; then prd="${c}"; break; fi
done

if [[ -z "${prd}" ]]; then
  echo "[wise-vibe] PRD.md 없음 / not found → wds-prd 로 초안 생성(기획서 PDF·MD 여러 개를 인자로 전달 가능). 이후 wds-recommend → wds-scaffold → wds-implement."
else
  echo "[wise-vibe] '${prd}' 감지 / detected → wds-recommend(스택·DB 추천) → wds-scaffold(docker compose local/prod) → wds-implement."
fi
exit 0
