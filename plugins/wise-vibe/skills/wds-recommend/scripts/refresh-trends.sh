#!/usr/bin/env bash
# 트렌드 캐시 신선도 점검 / Trends-cache staleness gate.
# references/trends-cache.yaml 의 last_updated + ttl_days 로 stale 여부를 판정하고,
# stale 이면 --trends 재확인이 필요한 항목(WebSearch 쿼리)을 출력한다.
# 데몬이 아니다 — 사용자/CI 가 실행하며, 실제 버전·시행일 확인은 Claude(--trends)나 사람이 한다.
#   This is NOT a daemon. It gates freshness; actual lookups are done by Claude (--trends) or a human.
#
# 사용 / usage:
#   refresh-trends.sh                      신선도 점검(FRESH/STALE) + 재확인 항목 출력
#   refresh-trends.sh --set-updated TODAY  수동 갱신 후 last_updated 를 오늘로 스탬프(+ source: manual)
#   refresh-trends.sh --set-updated YYYY-MM-DD
# 종료코드 / exit: 0=FRESH, 1=STALE (CI 게이트용 / for CI gating)
set -euo pipefail

skill_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cache="${skill_root}/references/trends-cache.yaml"
[[ -f "${cache}" ]] || { echo "ERROR: 캐시 없음 / cache missing: ${cache}" >&2; exit 2; }

# --set-updated 처리 / stamp last_updated
if [[ "${1:-}" == "--set-updated" ]]; then
  newdate="${2:-}"
  if [[ -z "${newdate}" || "${newdate}" == "TODAY" ]]; then
    newdate="$(date +%F)"
  fi
  # last_updated 한 줄만 치환(들여쓰기 보존) / replace the single line
  tmp="$(mktemp)"
  sed -E "s/^([[:space:]]*last_updated:).*/\1 \"${newdate}\"/" "${cache}" > "${tmp}" && mv "${tmp}" "${cache}"
  sed -E "s/^([[:space:]]*source:).*/\1 \"manual (${newdate})\"/" "${cache}" > "${tmp}" 2>/dev/null && mv "${tmp}" "${cache}" || true
  echo "STAMPED: last_updated=${newdate}"
  exit 0
fi

# last_updated / ttl_days 추출 (python3 우선, 없으면 grep) / extract fields
last_updated=""; ttl_days=""
if command -v python3 >/dev/null 2>&1; then
  read -r last_updated ttl_days < <(python3 - "${cache}" <<'PY'
import sys,re
t=open(sys.argv[1]).read()
def g(k,d):
    m=re.search(r'^\s*'+k+r':\s*"?([^"\n]+)"?',t,re.M); return (m.group(1).strip() if m else d)
print(g('last_updated','1970-01-01'), g('ttl_days','90'))
PY
)
else
  last_updated="$(grep -E '^\s*last_updated:' "${cache}" | head -1 | sed -E 's/.*last_updated:\s*"?([^"]+)"?.*/\1/')"
  ttl_days="$(grep -E '^\s*ttl_days:' "${cache}" | head -1 | sed -E 's/[^0-9]//g')"
fi
# 인라인 주석/공백 제거: ttl 은 숫자만, 날짜는 첫 토큰만 / strip inline comments
ttl_days="$(printf '%s' "${ttl_days}" | tr -dc '0-9')"
ttl_days="${ttl_days:-90}"
last_updated="$(printf '%s' "${last_updated}" | awk '{print $1}')"

# 경과일 계산 / days elapsed (GNU date 와 BSD/macOS date 모두 지원)
today_epoch="$(date +%s)"
if up_epoch="$(date -j -f "%Y-%m-%d" "${last_updated}" +%s 2>/dev/null)"; then :       # BSD/macOS
elif up_epoch="$(date -d "${last_updated}" +%s 2>/dev/null)"; then :                     # GNU
else echo "WARN: last_updated 파싱 실패 / unparseable: ${last_updated}"; up_epoch=0; fi

elapsed_days=$(( (today_epoch - up_epoch) / 86400 ))
echo "trends-cache: last_updated=${last_updated}, ttl_days=${ttl_days}, elapsed=${elapsed_days}d"

if (( elapsed_days <= ttl_days )); then
  echo "FRESH — 캐시 유효. --trends 시 'verify: true' 항목만 선택 재확인 / cache valid."
  exit 0
fi

echo "STALE — TTL 초과. 아래 항목을 --trends(WebSearch)로 재확인 후 'refresh-trends.sh --set-updated TODAY' / re-verify then stamp:"
echo "  · 런타임/프레임워크 'verify: true' 메이저 버전 (Node LTS, Python, Next, FastAPI, Flutter, Expo SDK 등)"
echo "  · regulations.*.since 가 오늘에 임박/경과한 업종 규제 시행일 (전자금융감독규정·마이데이터·PCI-DSS·DR 등)"
echo "  · 변경분은 references/trends-cache.yaml + 해당 profiles/*.yaml·domains/*.yaml 에 반영(출처 references)."
exit 1
