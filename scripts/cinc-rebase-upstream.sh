#!/usr/bin/env bash
#
# Rebase the current branch onto an upstream branch while dropping commits
# that should not appear in the Cinc fork (e.g. the omnibus privatization
# submodule that replaces the omnibus directory with a private submodule
# we cannot pull from).
#
# Usage:
#   scripts/cinc-rebase-upstream.sh [upstream-ref] [skip-sha ...]
#
# Defaults:
#   upstream-ref = upstream/chef-18
#   skip-sha     = 623d32af0a024a4fdd144159d6efd4496b841460
#
# Examples:
#   scripts/cinc-rebase-upstream.sh
#   scripts/cinc-rebase-upstream.sh upstream/main 623d32af0a abcdef12

set -euo pipefail

UPSTREAM_REF="${1:-upstream/chef-18}"
shift || true
SKIP_SHAS=("$@")
if [ ${#SKIP_SHAS[@]} -eq 0 ]; then
  SKIP_SHAS=("623d32af0a024a4fdd144159d6efd4496b841460")
fi

TEMP_BRANCH="cinc-rebase-upstream-tmp-$$"

current_branch="$(git symbolic-ref --short HEAD 2>/dev/null || true)"
if [ -z "$current_branch" ]; then
  echo "error: HEAD is detached; check out the branch you want to rebase first." >&2
  exit 1
fi

if [ -n "$(git status --porcelain)" ]; then
  echo "error: working tree is not clean; commit or stash before rebasing." >&2
  exit 1
fi

echo "==> Fetching $(echo "$UPSTREAM_REF" | cut -d/ -f1)"
git fetch "$(echo "$UPSTREAM_REF" | cut -d/ -f1)"

if ! git rev-parse --verify "$UPSTREAM_REF" >/dev/null 2>&1; then
  echo "error: upstream ref '$UPSTREAM_REF' not found." >&2
  exit 1
fi

for sha in "${SKIP_SHAS[@]}"; do
  if ! git rev-parse --verify "$sha^{commit}" >/dev/null 2>&1; then
    echo "error: skip commit '$sha' not found in repository." >&2
    exit 1
  fi
  if ! git merge-base --is-ancestor "$sha" "$UPSTREAM_REF"; then
    echo "error: skip commit '$sha' is not an ancestor of $UPSTREAM_REF." >&2
    exit 1
  fi
done

merge_base="$(git merge-base "$current_branch" "$UPSTREAM_REF")"
echo "==> Branch:      $current_branch"
echo "==> Upstream:    $UPSTREAM_REF ($(git rev-parse --short "$UPSTREAM_REF"))"
echo "==> Merge-base:  $(git rev-parse --short "$merge_base")"
echo "==> Skipping:    ${SKIP_SHAS[*]}"

cleanup() {
  local code=$?
  if git rev-parse --verify "$TEMP_BRANCH" >/dev/null 2>&1; then
    git branch -D "$TEMP_BRANCH" >/dev/null 2>&1 || true
  fi
  exit $code
}
trap cleanup EXIT

echo "==> Building cleaned upstream on $TEMP_BRANCH"
git checkout -b "$TEMP_BRANCH" "$UPSTREAM_REF" >/dev/null

# Drop each skip commit from the temp branch, oldest first.
mapfile -t ordered_skips < <(
  for sha in "${SKIP_SHAS[@]}"; do
    printf '%s %s\n' "$(git rev-list --count "$sha")" "$sha"
  done | sort -n | awk '{print $2}'
)

for sha in "${ordered_skips[@]}"; do
  echo "    dropping $(git log -1 --oneline "$sha")"
  if ! git rebase --onto "${sha}^" "$sha"; then
    echo "error: failed to drop $sha cleanly. Resolve conflicts and re-run, or 'git rebase --abort'." >&2
    git checkout "$current_branch" >/dev/null 2>&1 || true
    exit 1
  fi
done

echo "==> Rebasing $current_branch onto cleaned upstream"
git checkout "$current_branch" >/dev/null
if ! git rebase --onto "$TEMP_BRANCH" "$merge_base"; then
  echo
  echo "Rebase paused with conflicts. Resolve them, then 'git rebase --continue'."
  echo "When finished, delete the temp branch:  git branch -D $TEMP_BRANCH"
  trap - EXIT
  exit 1
fi

echo "==> Done. $current_branch is now rebased onto $UPSTREAM_REF (with skipped commits omitted)."
