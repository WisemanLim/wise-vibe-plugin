#!/usr/bin/env bash
# wds-prd — PRD 입력 문서 텍스트 추출 / extract text from PRD source documents.
#
# 사용 / usage:
#   extract-docs.sh <file> [file ...] [--out DIR]      (기본 DIR = .wds/prd-sources)
#   예) extract-docs.sh a.pdf a-ui-design.pdf notes.md
#
# 지원: .md .markdown .txt (복사) · .pdf (pdftotext → pypdf) · .docx (pandoc → python zipfile)
# 추출 도구가 없으면 해당 파일을 NEEDS_MODEL_READ 로 표시 — 에이전트가 원본을 직접 읽는다.
# 결과: <DIR>/<n>-<basename>.md + <DIR>/INDEX.md (역할·방법·분량)
# 역할 추정(파일명): ui|ux|design|screen|wireframe → design · api|interface|spec → api ·
#                   nfr|security|compliance|policy → nfr · 그 외 → main
# bash 3.2 호환.
set -euo pipefail

out=".wds/prd-sources"; files=()
while [ $# -gt 0 ]; do
  case "$1" in
    --out) out="${2:?--out DIR}"; shift ;;
    --out=*) out="${1#*=}" ;;
    -h|--help) sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) files+=("$1") ;;
  esac
  shift
done
[ "${#files[@]}" -gt 0 ] || { echo "ERROR: 입력 파일 없음 / no input files" >&2; exit 2; }

mkdir -p "${out}"
index="${out}/INDEX.md"
{
  echo "# PRD 입력 문서 / PRD sources"
  echo
  echo "| # | 원본 / source | 역할 / role | 방법 / method | 추출본 / extracted | 글자수 / chars |"
  echo "|---|---------------|-------------|---------------|--------------------|----------------|"
} > "${index}"

role_of() {
  local b; b="$(basename "$1" | tr 'A-Z' 'a-z')"
  case "${b}" in
    *ui*|*ux*|*design*|*screen*|*wireframe*|*figma*) echo design ;;
    *api*|*interface*|*spec*) echo api ;;
    *nfr*|*security*|*compliance*|*policy*|*regulation*) echo nfr ;;
    *) echo main ;;
  esac
}

py_pdf() {  # pypdf 가 있으면 사용
  python3 - "$1" <<'PY' 2>/dev/null
import sys
from pypdf import PdfReader
r = PdfReader(sys.argv[1])
for i, p in enumerate(r.pages, 1):
    print(f"\n<!-- page {i} -->\n")
    print(p.extract_text() or "")
PY
}

py_docx() {  # 표준 라이브러리만으로 docx 본문 추출
  python3 - "$1" <<'PY' 2>/dev/null
import sys, zipfile, re, html
xml = zipfile.ZipFile(sys.argv[1]).read("word/document.xml").decode("utf8")
for para in re.findall(r"<w:p[ >].*?</w:p>", xml, re.S):
    text = "".join(re.findall(r"<w:t[^>]*>(.*?)</w:t>", para, re.S))
    print(html.unescape(text))
PY
}

n=0; need_model=0; fail=0
for f in "${files[@]}"; do
  n=$((n+1))
  if [ ! -f "${f}" ]; then
    echo "| ${n} | \`${f}\` | - | MISSING | - | 0 |" >> "${index}"; fail=$((fail+1)); continue
  fi
  base="$(basename "${f}")"; dst="${out}/${n}-${base%.*}.md"; role="$(role_of "${f}")"
  ext="$(printf '%s' "${base##*.}" | tr 'A-Z' 'a-z')"; method=""
  case "${ext}" in
    md|markdown|txt) cp "${f}" "${dst}"; method="copy" ;;
    pdf)
      if command -v pdftotext >/dev/null 2>&1 && pdftotext -layout "${f}" "${dst}" 2>/dev/null; then method="pdftotext"
      elif py_pdf "${f}" > "${dst}" && [ -s "${dst}" ]; then method="pypdf"
      else rm -f "${dst}"; method="NEEDS_MODEL_READ"; fi ;;
    docx)
      if command -v pandoc >/dev/null 2>&1 && pandoc -t gfm "${f}" -o "${dst}" 2>/dev/null; then method="pandoc"
      elif py_docx "${f}" > "${dst}" && [ -s "${dst}" ]; then method="python-zipfile"
      else rm -f "${dst}"; method="NEEDS_MODEL_READ"; fi ;;
    *) method="UNSUPPORTED"; fail=$((fail+1)) ;;
  esac
  if [ -f "${dst}" ] && [ "$(wc -c < "${dst}" | tr -d ' ')" -lt 20 ] && [ "${ext}" = "pdf" ]; then
    rm -f "${dst}"; method="NEEDS_MODEL_READ (스캔 PDF 추정 / likely scanned)"
  fi
  case "${method}" in NEEDS_MODEL_READ*) need_model=$((need_model+1)) ;; esac
  if [ -f "${dst}" ]; then
    chars="$(wc -m < "${dst}" | tr -d ' ')"
    echo "| ${n} | \`${f}\` | ${role} | ${method} | \`${dst}\` | ${chars} |" >> "${index}"
  else
    echo "| ${n} | \`${f}\` | ${role} | ${method} | - | 0 |" >> "${index}"
  fi
done

{
  echo
  echo "- NEEDS_MODEL_READ: 추출 도구 없음/스캔본 → 에이전트가 원본 파일을 직접 읽는다."
  echo "- 역할(role)은 파일명 추정값이다. design → PRD 디자인 요구, api → 외부 연동, nfr → 비기능/규제 섹션에 우선 반영."
} >> "${index}"

cat "${index}"
echo "---"
echo "sources=${n} need_model_read=${need_model} failed=${fail} out=${out}"
[ "${fail}" -eq 0 ] || exit 1
