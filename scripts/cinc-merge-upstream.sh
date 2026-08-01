#!/usr/bin/env bash
#
# Merge an upstream ref into the current Cinc branch while keeping Cinc's own
# in-tree, public omnibus/ directory.
#
# Upstream (chef/inspec/chef-server) relocated omnibus/ into a PRIVATE git
# submodule that we cannot clone. Naively merging the upstream ref drags in the
# submodule gitlink and a .gitmodules pointing at an inaccessible repo. This
# script instead:
#
#   1. Builds a "cleaned" copy of the upstream ref as a single commit: the
#      omnibus submodule and .gitmodules are removed and omnibus/ is repopulated
#      from *this* branch's in-tree omnibus. Because it is one commit (no history
#      replay) it is robust no matter how many omnibus-submodule bump commits
#      upstream layered on after privatization.
#   2. Merges that cleaned ref into the current branch. Cinc's .gitattributes
#      (merge=ignore / merge=union) auto-resolves VERSION, the version.rb files,
#      Gemfile*.lock and CHANGELOG. omnibus/ carries no conflict because both
#      sides now hold Cinc's tree. As a safety net the merge forces omnibus/ and
#      the absence of .gitmodules to Cinc's side before committing.
#
# The 'ignore' merge driver must be registered first (the build's patch.sh does
# this):
#   git config merge.ignore.name 'ignore changes merge driver'
#   git config merge.ignore.driver 'touch %A'
#
# Usage:
#   scripts/cinc-merge-upstream.sh [upstream-ref]
#
# The upstream-ref may be a branch (upstream/main) or a bare tag/sha
# (v19.3.57) for a pinned release build. Default: upstream/main.

set -euo pipefail

UPSTREAM_REF="${1:-upstream/main}"
TEMP_BRANCH="cinc-merge-upstream-tmp-$$"

current_branch="$(git symbolic-ref --short HEAD 2>/dev/null || true)"
if [ -z "$current_branch" ]; then
  echo "error: HEAD is detached; check out the branch you want to merge into first." >&2
  exit 1
fi

if [ -n "$(git status --porcelain)" ]; then
  echo "error: working tree is not clean; commit or stash before merging." >&2
  exit 1
fi

# Determine the remote to fetch. If the ref is "<remote>/<name>" and <remote> is
# a configured remote (e.g. upstream/main) fetch that; otherwise the ref is a
# bare tag or sha (e.g. v19.3.57 for a release) so fetch the default 'upstream'
# remote. Always fetch tags so version tags resolve.
fetch_remote="${UPSTREAM_REF%%/*}"
if [ "$fetch_remote" = "$UPSTREAM_REF" ] || ! git remote get-url "$fetch_remote" >/dev/null 2>&1; then
  fetch_remote="upstream"
fi
echo "==> Fetching $fetch_remote (with tags)"
git fetch --tags "$fetch_remote"

if ! git rev-parse --verify "${UPSTREAM_REF}^{commit}" >/dev/null 2>&1; then
  echo "error: upstream ref '$UPSTREAM_REF' not found." >&2
  exit 1
fi

echo "==> Branch:   $current_branch"
echo "==> Upstream: $UPSTREAM_REF ($(git rev-parse --short "${UPSTREAM_REF}^{commit}"))"

cleanup_temp() {
  if git rev-parse --verify "$TEMP_BRANCH" >/dev/null 2>&1; then
    git branch -D "$TEMP_BRANCH" >/dev/null 2>&1 || true
  fi
}
trap 'code=$?; cleanup_temp; exit $code' EXIT

echo "==> Building de-privatized upstream on $TEMP_BRANCH"
git checkout -q -b "$TEMP_BRANCH" "${UPSTREAM_REF}^{commit}"

if git ls-tree "$TEMP_BRANCH" omnibus | grep -q '^160000'; then
  git rm -q --cached omnibus
  rm -rf omnibus
  [ -f .gitmodules ] && git rm -q -f .gitmodules
  # Repopulate omnibus/ from the branch we are merging into, so the subsequent
  # merge sees an identical omnibus on both sides (no conflict) and the result
  # keeps Cinc's in-tree omnibus.
  git checkout "$current_branch" -- omnibus
  git add -A omnibus
  git commit -q -m "Drop private omnibus submodule; keep Cinc's in-tree omnibus"
else
  echo "    ($UPSTREAM_REF has no omnibus submodule; nothing to de-privatize)"
fi

echo "==> Merging de-privatized upstream into $current_branch"
git checkout -q "$current_branch"
git merge --no-commit --no-ff "$TEMP_BRANCH" >/dev/null 2>&1 || true

# Safety net: force omnibus/ and the absence of .gitmodules to Cinc's side,
# regardless of how git resolved them.
rm -rf omnibus
git checkout "$current_branch" -- omnibus
git add -A omnibus
git rm -q --cached --ignore-unmatch .gitmodules >/dev/null 2>&1 || true
rm -f .gitmodules

remaining="$(git diff --name-only --diff-filter=U)"
if [ -n "$remaining" ]; then
  echo >&2
  echo "error: unresolved conflicts outside omnibus/ remain:" >&2
  echo "$remaining" | sed 's/^/    /' >&2
  echo "Resolve them, 'git add' the files, then 'git commit'. Afterwards delete" >&2
  echo "the temp branch:  git branch -D $TEMP_BRANCH" >&2
  trap - EXIT
  exit 1
fi

if git rev-parse --verify MERGE_HEAD >/dev/null 2>&1; then
  git commit --no-edit -q -m "Merge cleaned $UPSTREAM_REF into $current_branch"
else
  echo "==> Already up to date (no merge commit needed)."
fi

cleanup_temp
trap - EXIT
echo "==> Done. $current_branch now contains $UPSTREAM_REF's source with Cinc's omnibus preserved."
