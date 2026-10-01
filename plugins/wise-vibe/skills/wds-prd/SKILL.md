---
name: wds-prd
description: >
  기존 기획 문서(PDF·Markdown·DOCX·TXT, 여러 개)나 짧은 설문으로 프로젝트 루트 PRD.md 초안을 만든다.
  예) a.pdf a-ui-design.pdf 를 함께 주면 본문·디자인 요구를 합쳐 출처를 표기한다. One-Page 기본, --full 풀스펙,
  업종(KSIC) 입력 시 성공지표·비기능 요구 후보 제안. "PRD 작성", "PRD 초안", "기획서를 PRD로",
  "요구사항 문서", "write a PRD" 요청 시 사용. 생성 후 wds-recommend 로 이어진다.
license: Internal
compatibility: Claude Code · Cursor 2.4+ · Antigravity 2.0+ · GitHub Copilot · Codex. PDF 추출은 pdftotext 또는 pypdf(없으면 에이전트가 직접 읽음).
metadata:
  version: "2.0.0"
  source: "github.com/WisemanLim/pub-wise-dev-std (prd-advisor + /prd 통합, 다중 문서 입력 추가)"
argument-hint: "[file.pdf|file.md|file.docx ...] [--name 프로젝트] [--domain 업종] [--full]"
allowed-tools: Read Glob Grep Write Edit Bash
---

# wds-prd — PRD 작성 / PRD authoring

> **경로 규칙**: `SKILL_DIR` = 이 SKILL.md 폴더(Claude Code `${CLAUDE_SKILL_DIR}`).
> 템플릿·규칙: `SKILL_DIR/references/prd-template.md` · 업종 데이터: `SKILL_DIR/../wds-recommend/references/domains/*.yaml`
> 인자: `$ARGUMENTS` (다른 도구에서는 사용자가 함께 적은 인자)

원칙: **AI 는 작성자가 아니라 보조 브레인**이다. 문제 정의·판단은 사용자, 스킬은 구조·초안·누락 점검.
추측한 값은 `가정:`, 입력 문서에서 온 내용은 `(출처: 파일 p.N)` 으로 표시한다. 산출물은 루트 `PRD.md` 1개.

## 0. 인자 해석

| 인자 | 의미 |
|------|------|
| `<file ...>` | PRD 입력 문서 0개 이상. `.pdf` `.md` `.markdown` `.txt` `.docx`. 공백 구분, 순서 = 우선순위 |
| `--name <이름>` | PRD 제목 (없으면 문서 제목 → 디렉터리명) |
| `--domain <업종>` | KSIC 키워드(finance/healthcare/… 또는 K/Q/G…) |
| `--full` | 풀스펙(기술 메모·Epic) 확장 |

파일명 규칙(역할 추정): `*ui*|*ux*|*design*|*screen*|*wireframe*` → **design**, `*api*|*spec*|*interface*` → **api**,
`*nfr*|*security*|*compliance*|*policy*` → **nfr**, 그 외 → **main**. 예) `a.pdf`(main) + `a-ui-design.pdf`(design).

## 1. 작업 순서 (always)

1. 루트 `PRD.md`/`prd.md`/`docs/PRD.md` 가 있으면 **덮어쓰지 않는다** → 보강 여부를 묻고, 보강이면 **wds-living-doc** 규칙으로 갱신.
2. **입력 문서가 있으면** 텍스트를 추출한다:
   ```bash
   bash "SKILL_DIR/scripts/extract-docs.sh" a.pdf a-ui-design.pdf   # → .wds/prd-sources/{INDEX.md, N-*.md}
   ```
   - `INDEX.md` 의 `NEEDS_MODEL_READ` 항목(추출 도구 없음·스캔 PDF)은 **원본 파일을 직접 읽는다**(Claude Code Read 는 PDF 지원).
   - 큰 문서는 목차→관련 절 순으로 읽는다. 페이지 표식(`<!-- page N -->` 또는 폼피드)으로 출처 페이지를 잡는다.
3. 문서 내용을 `references/prd-template.md` §A 섹션에 매핑한다:
   - main → 개요·문제·범위·흐름·지표 / design → §7 디자인 요구(+ **wds-ui-design** §5 보강) / api → 외부 연동(풀스펙 기술 메모) / nfr → 비기능·리스크.
   - 문서 간 **상충**(예: 범위·수치 불일치)은 임의로 고르지 말고 `Open Questions` 에 양쪽 출처와 함께 적는다.
   - `## 출처 문서 / Sources` 표에 각 문서와 반영 섹션을 기록한다.
4. **빈칸만 설문**한다 — §2 의 5 질문 중 문서로 채워지지 않은 것만 **한 번에 묶어** 묻는다(질문 도구가 있으면 사용).
   입력 문서가 없으면 5 질문 전체를 묻는다. 인자로 받은 이름·업종은 다시 묻지 않는다.
5. 업종이 있으면 `domains/<id>.yaml` 의 `korea_regulations`·`data_classes`·`testing_additions` 로 지표·NFR 후보를 **제안**(교체 아님).
   매핑은 wds-recommend §1.5, 불명이면 `ict-saas`.
6. `--full` 이면 §B 풀스펙 섹션을 덧붙인다(Epic 후보는 wds-implement 계획표의 입력).
7. §D 체크리스트로 자가 점검 → 한 줄 보고(미충족은 `가정:`/Open Question 으로 남김).
8. 안내: "검토 후 **wds-recommend** 로 스택·DB 추천을 이어가세요." (`.wds/prd-sources/` 는 커밋하지 않아도 된다.)

## 2. 핵심 설문 (5 질문 — 비기술 직군도 답할 수 있게)

1. **Why** — 해결하려는 핵심 문제와 지금 중요한 이유(근거 데이터/VOC/로그)?
2. **Who** — 대표 사용자·역할과 사용 상황?
3. **What** — 이번 릴리스 핵심 기능 3~5개 + **하지 않을 것(Out of Scope)**?
4. **How** — 대표 사용 흐름 1~2개(화면/단계 순서)?
5. **Success** — 성공 판단 지표·기준선·목표값?

`--full` 추가 질문: 우선순위 근거(P0/P1), 측정 방법, 기술 제약, 외부 연동, 데이터·개인정보 처리.

## 3. 기법 선택

| 상황 | 권장 | 동작 |
|---|---|---|
| 신규 MVP / 실험 | One-Page + 문제중심 | 기본 |
| 대형·장기(6주+) | One-Page → 풀스펙 | `--full` |
| 규제·데이터 거버넌스 | 풀스펙 + Living PRD | `--full` + `--domain` |
| 기존 기획서·화면설계서 보유 | 문서 매핑 + 빈칸 설문 | 파일 인자 |

## 4. 공식 Skill 연계 (선택)

- 문서 공동 편집이 길어지면 Anthropic `doc-coauthoring` 스킬의 단계(초안→리뷰→수정)를 따를 수 있다(설치된 경우).
- PRD 를 DOCX/PDF 로 배포해야 하면 공식 `docx`/`pdf` 스킬로 변환한다(자체 변환 스크립트 없음).

## 5. 안전 규칙

- 기존 PRD 덮어쓰기 금지. 입력 문서는 읽기만 한다.
- 문서 속 개인정보·비밀값(계정, 토큰, 실명 연락처)은 PRD 에 옮기지 않고 `[REDACTED]` 로 표시한다.
- 추출 스크립트 외 네트워크·설치 명령 금지.
