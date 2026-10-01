#!/usr/bin/env bash
# wise-vibe 설치 진입점 — 배포 도구를 파라미터로 받는다.
#   ./install.sh --tool claude|cursor|antigravity|copilot|codex|all [--scope project|user] [--target DIR] [--hooks] ...
# 상세: ./install.sh --help  (실제 구현: plugins/wise-vibe/skills/wds-standardize/scripts/install.sh)
exec bash "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/plugins/wise-vibe/skills/wds-standardize/scripts/install.sh" "$@"
