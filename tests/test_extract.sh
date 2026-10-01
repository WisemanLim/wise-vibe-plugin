#!/usr/bin/env bash
# wds-prd 다중 문서 추출: md + pdf(생성) + docx(생성) → INDEX 역할·방법 검증.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; X="${ROOT}/plugins/wise-vibe/skills/wds-prd/scripts/extract-docs.sh"
OUT="${ROOT}/tests/.out/extract"; rm -rf "${OUT}"; mkdir -p "${OUT}"; cd "${OUT}"
fail=0; n=0
t() { n=$((n+1)); if eval "$2"; then :; else fail=$((fail+1)); echo "  FAIL $1"; fi; }
printf '# 주문 서비스\n고객은 장바구니에서 결제한다.\n' > a.md
python3 - <<'PY'
import zipfile
# 최소 PDF (텍스트 1줄)
c = b"BT /F1 18 Tf 72 720 Td (Order screen: cart, checkout button) Tj ET"
objs = [b"<< /Type /Catalog /Pages 2 0 R >>", b"<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
        b"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>",
        b"<< /Length %d >>\nstream\n" % len(c) + c + b"\nendstream", b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>"]
out = b"%PDF-1.4\n"; offs = []
for i, o in enumerate(objs, 1):
    offs.append(len(out)); out += b"%d 0 obj\n" % i + o + b"\nendobj\n"
x = len(out); out += b"xref\n0 %d\n0000000000 65535 f \n" % (len(objs) + 1) + b"".join(b"%010d 00000 n \n" % o for o in offs)
out += b"trailer\n<< /Size %d /Root 1 0 R >>\nstartxref\n%d\n%%%%EOF\n" % (len(objs) + 1, x)
open("a-ui-design.pdf", "wb").write(out)
z = zipfile.ZipFile("a-api-spec.docx", "w")
z.writestr("word/document.xml", '<w:document xmlns:w="w"><w:body><w:p><w:r><w:t>POST /orders</w:t></w:r></w:p></w:body></w:document>')
z.close()
PY
bash "${X}" a.md a-ui-design.pdf a-api-spec.docx >log.txt 2>&1; rc=$?
t "exit 0" "[ ${rc} -eq 0 ]"
t "INDEX 생성" "[ -f .wds/prd-sources/INDEX.md ]"
t "md=main/copy" "grep -q 'a.md\` | main | copy' .wds/prd-sources/INDEX.md"
t "pdf=design" "grep -q 'a-ui-design.pdf\` | design |' .wds/prd-sources/INDEX.md"
t "pdf 텍스트" "grep -rq 'checkout' .wds/prd-sources/2-a-ui-design.md || grep -q NEEDS_MODEL_READ .wds/prd-sources/INDEX.md"
t "docx=api 텍스트" "grep -q 'POST /orders' .wds/prd-sources/3-a-api-spec.md"
bash "${X}" missing.pdf >/dev/null 2>&1; rc=$?
t "없는 파일 → exit 1" "[ ${rc} -eq 1 ]"
echo "extract checks=${n} fail=${fail}"
[ "${fail}" -eq 0 ]
