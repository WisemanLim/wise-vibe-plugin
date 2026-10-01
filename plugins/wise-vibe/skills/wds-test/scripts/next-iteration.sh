#!/usr/bin/env bash
# wds-test — 다음 시험 차수 디렉터리 생성 / create the next test/impl/<Nth>/ directory.
# 사용: next-iteration.sh [project-root] [--chunks K]   → 생성 경로를 stdout 마지막 줄에 출력
# 기존 차수는 절대 덮어쓰지 않는다. 서수: 1st 2nd 3rd 4th … 11th 12th 13th … 21st 22nd 23rd …
set -euo pipefail
root="."; chunks=0
while [ $# -gt 0 ]; do
  case "$1" in --chunks) chunks="${2:?}"; shift ;; *) root="$1" ;; esac; shift
done
impl="${root}/test/impl"; mkdir -p "${impl}"
max=0
for d in "${impl}"/*/; do
  [ -d "${d}" ] || continue
  n="$(basename "${d}" | sed -E 's/^([0-9]+)(st|nd|rd|th)$/\1/')"
  case "${n}" in ''|*[!0-9]*) continue ;; esac
  [ "${n}" -gt "${max}" ] && max="${n}"
done
n=$((max+1))
case $((n % 100)) in 11|12|13) suf=th ;; *) case $((n % 10)) in 1) suf=st ;; 2) suf=nd ;; 3) suf=rd ;; *) suf=th ;; esac ;; esac
dir="${impl}/${n}${suf}"
mkdir -p "${dir}/logs"
k=1; while [ "${k}" -le "${chunks}" ]; do mkdir -p "${dir}/chunk-${k}/logs"; k=$((k+1)); done
echo "${dir}"
