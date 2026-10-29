#!/usr/bin/env bash
# secret-scan.sh — gitleaks over the root repo and every sub repo checkout .
# Scans exactly what can be committed or shipped: tracked + untracked-not-ignored files
# (git ls-files -co --exclude-standard). Ignored material such as .env.prod, .secrets/, node_modules,
# .wds/ extraction text is out of scope here — those never leave the machine (release.sh excludes them again).
# Uses the gitleaks container so no host install is needed. Findings are redacted.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IMAGE="${GITLEAKS_IMAGE:-zricethezav/gitleaks:v8.28.0}"
rc=0
REPOS="$(awk -F'\t' '!/^#/ && NF {print $1}' "$ROOT/release/services.tsv" 2>/dev/null | tr '\n' ' ')"
for repo in . ${REPOS}; do
  [ -d "$ROOT/$repo/.git" ] || { echo "skip $repo (no git checkout)"; continue; }
  stage="$(mktemp -d)"
  ( cd "$ROOT/$repo" && git ls-files -z -co --exclude-standard \
      | while IFS= read -r -d '' f; do [ -f "$f" ] && printf '%s\0' "$f"; done \
      | COPYFILE_DISABLE=1 tar --null -cf - -T - ) | tar -xf - -C "$stage"
  cfg=""; [ -f "$stage/.gitleaks.toml" ] && cfg="--config /repo/.gitleaks.toml"
  echo "==> gitleaks $repo ($(find "$stage" -type f | wc -l | tr -d ' ') files)"
  # shellcheck disable=SC2086
  docker run --rm -v "$stage:/repo:ro" "$IMAGE" dir /repo $cfg --redact --no-banner || rc=1
  rm -rf "$stage"
done
exit "$rc"
