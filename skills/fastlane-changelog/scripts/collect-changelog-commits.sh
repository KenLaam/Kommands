#!/usr/bin/env bash
#
# Collect candidate changelog lines from commits since the last build bump.
#
# Boundary detection: the most recent "Bump build to N" commit marks the
# previous deploy. Everything AFTER it (exclusive) is what ships in the next
# build. "Bump version to X" is not a boundary: it ships no build.
#
# Noise filtered out (not tester-facing): merges, build/version bumps,
# docs(...) / docs:, test(...) / test:, chore(deps...). Exact-duplicate
# subjects are de-duped (a PR-branch commit + its squash often repeat).
#
# Usage:
#   collect-changelog-commits.sh            # print candidate lines to stdout
#   collect-changelog-commits.sh --write    # also overwrite fastlane/changelog
#   collect-changelog-commits.sh --range A..B  # override the commit range
#
# Output is reverse-chronological (newest first). The caller is expected to
# curate: reorder features-first, drop anything not tester-relevant, reword
# cryptic subjects. This script does the mechanical filtering only.

# No pipefail: awk early-exit (boundary lookup) and grep "no match" are
# expected, non-error pipeline outcomes here.
set -eu

WRITE=0
RANGE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --write) WRITE=1; shift ;;
    --range) RANGE="${2:-}"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "not a git repo" >&2; exit 1; }
CHANGELOG="$ROOT/fastlane/changelog"

if [ ! -d "$ROOT/fastlane" ]; then
  echo "warning: no fastlane/ dir at repo root ($ROOT) — is this the right project?" >&2
fi

# Determine commit range.
if [ -z "$RANGE" ]; then
  boundary="$(git -C "$ROOT" log --pretty=format:'%H%x09%s' \
    | awk -F'\t' '$2 ~ /[Bb]ump build( number)? to [0-9]+/ {print $1; exit}')"
  if [ -n "$boundary" ]; then
    RANGE="${boundary}..HEAD"
  else
    RANGE="-30"  # no bump found: fall back to last 30 commits
    echo "note: no 'Bump build to' commit found; using last 30 commits" >&2
  fi
fi

# Pull subjects (no merge commits), filter noise, de-dupe preserving order.
if [ "$RANGE" = "-30" ]; then
  raw="$(git -C "$ROOT" log -30 --no-merges --pretty=format:'%s')"
else
  raw="$(git -C "$ROOT" log "$RANGE" --no-merges --pretty=format:'%s')"
fi

candidates="$(printf '%s\n' "$raw" \
  | grep -Eiv '^(bump (build|version)|merge |docs(\(|:)|test(\(|:)|chore\(deps)|bump (build|version)( number)? to [0-9]+' \
  | awk 'NF && !seen[$0]++ { print "- " $0 }')"

if [ -z "$candidates" ]; then
  echo "(no tester-facing commits since last build bump)" >&2
fi

printf '%s\n' "$candidates"

if [ "$WRITE" -eq 1 ] && [ -n "$candidates" ]; then
  printf '%s\n' "$candidates" > "$CHANGELOG"
  echo "wrote $(printf '%s\n' "$candidates" | grep -c '^-') line(s) to $CHANGELOG" >&2
fi
