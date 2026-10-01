---
name: wds-review
description: >
  구현 완료 코드에 대해 (1) 심층 분석(스택·라이선스 감사·ISO 5230·상용화 5단계 등급)과 (2) 독자 레벨(0~4)
  라인 단위 리뷰를 .review/ 에 산출한다. 일반 결함·보안 리뷰는 플랫폼 공식 기능(/code-review, /security-review,
  pr-review-toolkit, Bugbot)에 위임해 결과를 병합하고, PDF/DOCX 변환은 공식 pdf·docx 스킬을 쓴다.
  "코드 리뷰", "심층 분석", "라이선스 감사", "상용화 검토", "인수인계 리뷰" 요청 시 사용. implement 후 권장.
license: Internal
compatibility: Claude Code · Cursor 2.4+ · Antigravity 2.0+ · GitHub Copilot · Codex. 위임 대상이 없으면 references 의 자체 절차로 폴백.
metadata:
  version: "2.0.0"
  source: "github.com/WisemanLim/pub-wise-dev-std (depth-reviewer + code-reviewer + /review 통합, 공식 위임)"
argument-hint: "[paths...] [--level 0-4] [--only depth|code|both] [--pdf true|false] [-O]"
allowed-tools: Read Glob Grep Bash Write Edit WebSearch
---

# wds-review — 심층 분석 + 레벨별 코드 리뷰

> `SKILL_DIR` = 이 SKILL.md 폴더(Claude Code `${CLAUDE_SKILL_DIR}`).
> 절차 원문: `SKILL_DIR/references/depth-method.md`(심층) · `SKILL_DIR/references/code-method.md`(라인 리뷰)
> 인자: `$ARGUMENTS`

## 1. 역할 분담 (위임 vs 고유)

| 영역 | 담당 | 비고 |
|------|------|------|
| 일반 결함·정확성 (PR 단위) | **공식 위임** | Claude Code 번들 `/code-review [effort]`(+`--fix`) · `pr-review-toolkit` · Cursor Bugbot |
| 보안 취약점 | **공식 위임** | Claude Code `/security-review` · `security-guidance` 플러그인 · Bugbot 보안 규칙 |
| 단순화·중복 | **공식 위임** | Claude Code `/simplify` |
| 독자 레벨(0=비개발자~4=아키텍트) 라인 리뷰 | **고유** | `code-method.md` → `.review/CODE-REVIEW-Lv<N>/` |
| 라이선스 감사·ISO 5230·상용화 5단계 등급 | **고유** | `depth-method.md` → `.review/REVIEW-InDepth.md` |
| PDF/DOCX 변환 | **공식 대체** | Anthropic `pdf` / `docx` 스킬 (자체 pandoc 체인 없음) |

위임 대상이 현재 도구에 없으면 해당 행은 `references` 의 자체 체크리스트로 수행하고 보고서에 "폴백" 이라 적는다.

## 2. 인자

| 인자 | 기본 | 설명 |
|------|------|------|
| `[paths...]` | 현재 디렉터리 | 대상 |
| `--level 0..4` | 2 | 라인 리뷰 독자 레벨. 없으면 AGENTS.md/PRD 신호로 추천 후 1회 확인(비대화 환경은 2) |
| `--only depth\|code\|both` | both | 산출 범위 |
| `--pdf true\|false` | false | 공식 pdf/docx 스킬로 변환 |
| `-O` | off | 다중 대상 집계 |

## 3. 절차

1. 컨텍스트 수집 — `PRD.md`·`AGENTS.md`·`COMPLIANCE.md`·`Makefile`(프로파일 흔적)·`test/` 최신 결과.
2. **위임 실행**(가능한 것만): 결함 리뷰 → 보안 리뷰. 결과 원문을 `.review/delegated/<tool>.md` 로 저장(요약 아님).
3. **고유 실행** — `both` 면 서로 독립이므로 서브에이전트 2개 병렬 권장(없으면 심층→라인 순차).
   - 심층: `depth-method.md` Step 1~9. Step 4(보안)는 2단계 결과를 인용하고 정책·공급망·시크릿 관리만 보강.
   - 라인: `code-method.md` Step 1~8, 레벨 매트릭스 준수.
4. 저장 — `.review/REVIEW-InDepth.md`, `.review/CODE-REVIEW-Lv<N>/INDEX.md` + 파일별 `.md`, `.review/delegated/`.
5. `--pdf true` → 공식 `pdf`(또는 `docx`) 스킬로 변환.
6. 보고 — 경로 + 1문단씩: 심층 종합 판정(🟢🔵🟡🟠🔴)·top 위험 / 라인 리뷰 레벨·파일 수·top-3 위험 / 위임 결과 요약(심각도별 건수).

## 4. wise-vibe 표준 점검 항목 (심층 Step 6 에 추가)

- 실행이 docker compose 전용인가(호스트 프로세스 매니저·Procfile·ecosystem 파일 잔존 여부).
- 모드가 local/prod 두 개뿐인가(`.env.dev`/`.env.staging`·dev/staging compose 잔존 여부).
- `.env.prod` 가 커밋되지 않았고 `CHANGE_ME` 외 실값이 저장소에 없는가.
- prod DB 엔진이 `.env.prod`·`docker-compose.prod.yml`·`Makefile DB_ENGINE` 에서 일치하는가.
- `test/dev-env/result.md`·`test/impl/<Nth>/result.md` 존재와 최신 판정.

## 5. 규칙

실파일 근거만(경로+라인), 한국어 우선·영어 병기, 마케팅 톤 금지, 읽기·분석·`.review/` 쓰기만(소스 수정은 `/code-review --fix` 등
위임 도구를 사용자가 명시적으로 실행할 때만). 파괴적 명령·실시크릿·네트워크 설치 금지.
