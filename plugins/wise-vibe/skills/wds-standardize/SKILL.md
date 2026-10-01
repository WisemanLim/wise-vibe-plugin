---
name: wds-standardize
description: >
  프로젝트 표준을 도구 중립 형식으로 배포한다: AGENTS.md 관리 블록 1개 + wds-* 스킬 원본을 도구별 공식 경로에 설치
  (Claude Code .claude/skills · Cursor .cursor/skills · Antigravity/Codex .agents/skills · Copilot .github/skills).
  IDE 별 규칙 파일 복사는 하지 않는다. "AGENTS.md 내보내기", "Cursor/Antigravity/Copilot/Codex 에서도 쓰게",
  "팀 표준 배포", "standardize" 요청 시 사용.
license: Internal
compatibility: Claude Code · Cursor 2.4+ · Antigravity 2.0+ · GitHub Copilot · Codex. bash 3.2+.
metadata:
  version: "2.0.0"
  source: "github.com/WisemanLim/pub-wise-dev-std (/standardize 재설계 — 규칙 복사 → Skill 배포)"
argument-hint: "[--tool claude|cursor|antigravity|copilot|codex|all] [--hooks] [--profile <id>] [--domain <id>]"
disable-model-invocation: true
allowed-tools: Read Glob Grep Write Edit Bash
---

# wds-standardize — 표준 배포 (AGENTS.md + Skill)

> `SKILL_DIR` = 이 SKILL.md 폴더(Claude Code `${CLAUDE_SKILL_DIR}`). 설치기: `SKILL_DIR/scripts/install.sh`
> 템플릿: `SKILL_DIR/assets/AGENTS.md` · 인자: `$ARGUMENTS`

## 1. 설계

| 이전 (wise-dev-std) | 현재 (wise-vibe) | 이유 |
|---------------------|------------------|------|
| AGENTS.md + IDE 규칙 7종 복사(.cursor/rules, .windsurf, GEMINI.md, .clinerules …) | **AGENTS.md 관리 블록 1개** | 5개 도구 모두 AGENTS.md 를 네이티브로 읽음 — 복사본은 컨텍스트 중복 |
| `.antigravity/rules.md` | 사용 안 함 | Antigravity 공식 경로는 AGENTS.md / `.agents/rules/` |
| 규칙만 배포(절차 실행 불가) | **wds-* 스킬 원본 배포** | 5개 도구 모두 SKILL.md 지원 → recommend·scaffold·implement 를 직접 실행 |
| — | Claude Code 의 `CLAUDE.md` 에 `@AGENTS.md` | CLAUDE.md 가 있으면 Claude Code 는 AGENTS.md 를 읽지 않음 |

## 2. 절차

1. 대상 도구 결정 — 인자 `--tool`(쉼표 구분) 없으면 저장소 흔적으로 추정해 확인한다
   (`.cursor/` → cursor, `.agents/` → antigravity/codex, `.github/` → copilot, `.claude/`·CLAUDE.md → claude). 여럿이면 `all`.
2. 미리보기 → 설치:
   ```bash
   bash "SKILL_DIR/scripts/install.sh" --tool all --target . --dry-run
   bash "SKILL_DIR/scripts/install.sh" --tool all --target . [--hooks]
   ```
   - `all` = `.agents/skills/wds-*` 원본 + `.claude/skills/wds-*` 상대 링크 + `.claude/agents`·`.agents/agents` + AGENTS.md (+ `--hooks` 시 Claude·Cursor SessionStart).
   - 이미 다른 내용의 `wds-*` 가 있으면 건너뛴다(`--force` 는 사용자가 명시할 때만).
3. **프로젝트 섹션** — AGENTS.md 의 관리 블록 **바깥**에 아래 블록을 쓰거나 갱신한다(있으면 교체):
   ```
   <!-- wise-vibe:project:begin -->
   ## 이 프로젝트
   - 프로파일: <id> (Makefile 1행 / wds-recommend 결과) · prod DB: <DB_ENGINE> · extras: <compose/*.yml>
   - 업종: <domain> — COMPLIANCE.md 의 핵심 규제 3줄 · 규제대상 데이터 등급
   <!-- wise-vibe:project:end -->
   ```
   근거는 `Makefile`(`DB_ENGINE`)·`.env.prod`·`COMPLIANCE.md`·`../wds-recommend/references/profiles/<id>.yaml` 만 사용.
4. 보고 — 설치된 경로, 각 도구 호출법, 재시작 필요 여부, 커밋 권장 파일(`.agents/`, `.claude/skills`, AGENTS.md; `.env.prod` 제외).

## 3. 도구별 경로 (project / user)

| 도구 | 스킬 | 에이전트 | 훅 |
|------|------|----------|----|
| Claude Code | `.claude/skills` / `~/.claude/skills` | `.claude/agents` | `.claude/settings.json` SessionStart (`--hooks`) |
| Cursor | `.cursor/skills` / `~/.cursor/skills` | `.cursor/agents` | `.cursor/hooks.json` sessionStart (`--hooks`) |
| Antigravity | `.agents/skills` / `~/.gemini/config/skills` | `.agents/agents` | 없음 → AGENTS.md 지침 |
| GitHub Copilot | `.github/skills` / `~/.copilot/skills` | — | 없음 |
| Codex | `.agents/skills` / `~/.agents/skills` | — | 없음 |

제거: `install.sh --tool <t> --uninstall` (wds-* 와 AGENTS.md 관리 블록만 지운다).

## 4. 규칙

기존 AGENTS.md·CLAUDE.md 내용은 보존(관리 블록과 `@AGENTS.md` 한 줄만 추가/교체). 기존 settings.json·hooks.json 은 덮어쓰지 않고
추가할 JSON 조각을 안내한다. 네트워크 명령 없음.
