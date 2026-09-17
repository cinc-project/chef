#!/usr/bin/env bash
#
# Rebase the current branch onto an upstream branch while dropping commits
# that should not appear in the Cinc fork.
#
# Upstream moved omnibus/ into a PRIVATE submodule we cannot clone, and keeps
# layering submodule-bump commits on top. Replaying those onto a Cinc branch
# that carries omnibus/ in-tree conflicts on the gitlink, so by default this
# script finds them itself: every commit in merge-base..upstream-ref whose diff
# touches .gitmodules or the omnibus gitlink. A commit that moves nothing else
# is dropped; one that also carries real work is replayed with only its
# submodule change reverted, so upstream changes are never silently lost.
# Nothing is hardcoded, so the list stays correct as upstream adds more.
# Branches whose upstream has no submodule (upstream/main) detect nothing and
# rebase unchanged.
#
# Usage:
#   scripts/cinc-rebase-upstream.sh [upstream-ref] [skip-sha ...]
#
# Defaults:
#   upstream-ref = upstream/chef-18
#   skip-sha     = auto-detected (see above)
#
# Shas passed explicitly are dropped whole and turn detection off; set
# CINC_REBASE_NO_AUTO_SKIP=1 to drop nothing at all.
#
# Examples:
#   scripts/cinc-rebase-upstream.sh
#   scripts/cinc-rebase-upstream.sh upstream/chef-18 abcdef12

set -euo pipefail

UPSTREAM_REF="${1:-upstream/chef-18}"
shift || true
SKIP_SHAS=("$@")

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

merge_base="$(git merge-base "$current_branch" "$UPSTREAM_REF")"

# Commits in the replay range that add or bump the private omnibus submodule.
# A gitlink (mode 160000) on either side of the diff is what identifies them.
detect_submodule_commits() {
  git log --format='C %H' --raw --no-abbrev "$merge_base..$UPSTREAM_REF" \
    -- .gitmodules omnibus |
    awk '/^C /{ sha = $2 } /^:/{ if ($1 ~ /160000/ || $2 ~ /160000/) print sha }' |
    sort -u
}

# A commit that only moves the submodule can be dropped outright; one that also
# touches other paths keeps those, so it is replayed and stripped instead.
commit_is_pure_submodule() {
  ! git diff-tree --no-commit-id --name-only -r "$1" |
    grep -qvE '^(omnibus|\.gitmodules)$'
}

DROP_SHAS=()
STRIP_SHAS=()

if [ ${#SKIP_SHAS[@]} -gt 0 ]; then
  DROP_SHAS=("${SKIP_SHAS[@]}")
elif [ "${CINC_REBASE_NO_AUTO_SKIP:-0}" != "1" ]; then
  auto_detected=yes
  while read -r sha; do
    [ -n "$sha" ] || continue
    if commit_is_pure_submodule "$sha"; then
      DROP_SHAS+=("$sha")
    else
      STRIP_SHAS+=("$sha")
    fi
  done < <(detect_submodule_commits)
fi

for sha in ${DROP_SHAS[@]+"${DROP_SHAS[@]}"} ${STRIP_SHAS[@]+"${STRIP_SHAS[@]}"}; do
  if ! git rev-parse --verify "$sha^{commit}" >/dev/null 2>&1; then
    echo "error: skip commit '$sha' not found in repository." >&2
    exit 1
  fi
  # Only commits being replayed can be dropped; anything older is already in
  # the history both branches share.
  if ! git merge-base --is-ancestor "$sha" "$UPSTREAM_REF" ||
     git merge-base --is-ancestor "$sha" "$merge_base"; then
    echo "error: skip commit '$sha' is not in $(git rev-parse --short "$merge_base")..$UPSTREAM_REF." >&2
    exit 1
  fi
done

echo "==> Branch:      $current_branch"
echo "==> Upstream:    $UPSTREAM_REF ($(git rev-parse --short "$UPSTREAM_REF"))"
echo "==> Merge-base:  $(git rev-parse --short "$merge_base")"
if [ $(( ${#DROP_SHAS[@]} + ${#STRIP_SHAS[@]} )) -eq 0 ]; then
  echo "==> Submodule:   no commits to neutralize"
else
  echo "==> Submodule:   $(( ${#DROP_SHAS[@]} + ${#STRIP_SHAS[@]} )) commit(s)${auto_detected:+, auto-detected}"
  for sha in ${DROP_SHAS[@]+"${DROP_SHAS[@]}"}; do
    echo "     drop       $(git log -1 --oneline "$sha")"
  done
  for sha in ${STRIP_SHAS[@]+"${STRIP_SHAS[@]}"}; do
    echo "     strip      $(git log -1 --oneline "$sha")"
  done
fi

drop_file=""
strip_file=""
todo_editor=""

cleanup() {
  local code=$?
  rm -f "$drop_file" "$strip_file" "$todo_editor"
  if git rev-parse --verify "$TEMP_BRANCH" >/dev/null 2>&1; then
    git branch -D "$TEMP_BRANCH" >/dev/null 2>&1 || true
  fi
  exit $code
}
trap cleanup EXIT

echo "==> Building cleaned upstream on $TEMP_BRANCH"
git checkout -b "$TEMP_BRANCH" "$UPSTREAM_REF" >/dev/null

if [ $(( ${#DROP_SHAS[@]} + ${#STRIP_SHAS[@]} )) -gt 0 ]; then
  drop_file="$(mktemp)"
  strip_file="$(mktemp)"
  todo_editor="$(mktemp)"
  printf '%s\n' ${DROP_SHAS[@]+"${DROP_SHAS[@]}"} > "$drop_file"
  printf '%s\n' ${STRIP_SHAS[@]+"${STRIP_SHAS[@]}"} > "$strip_file"

  # Replay a strip commit as its own diff minus the submodule paths, rather
  # than picking it: the gitlink hunk expects a value the dropped bumps left
  # behind, so picking it conflicts before any fixup could run. --3way keeps
  # cherry-pick's merge behaviour for the paths we do want.
  strip_cmd="git diff @SHA@^ @SHA@ -- ':(exclude)omnibus' ':(exclude).gitmodules' | git apply --3way - && git commit -q -C @SHA@"

  cat > "$todo_editor" <<'EDITOR'
#!/usr/bin/env bash
set -euo pipefail
out="$(mktemp)"
while IFS= read -r line; do
  case "$line" in
    pick\ *|p\ *)
      sha="${line#* }"
      sha="${sha%% *}"
      if grep -qxF "$sha" "$CINC_DROP_FILE"; then
        continue
      fi
      if grep -qxF "$sha" "$CINC_STRIP_FILE"; then
        printf 'exec %s\n' "${CINC_STRIP_CMD//@SHA@/$sha}" >> "$out"
      else
        printf '%s\n' "$line" >> "$out"
      fi
      ;;
    *)
      printf '%s\n' "$line" >> "$out"
      ;;
  esac
done < "$1"
mv "$out" "$1"
EDITOR
  chmod +x "$todo_editor"

  # One replay, not one rebase per commit: consecutive submodule bumps each
  # expect the gitlink the last one left, so neutralizing them singly conflicts.
  # core.abbrev=40 puts full shas in the todo so the matches are exact.
  if ! CINC_DROP_FILE="$drop_file" CINC_STRIP_FILE="$strip_file" \
       CINC_STRIP_CMD="$strip_cmd" \
       GIT_SEQUENCE_EDITOR="$todo_editor" GIT_EDITOR=true \
       git -c core.abbrev=40 rebase -i --onto "$merge_base" "$merge_base"; then
    echo "error: failed to neutralize the submodule commits cleanly. Resolve conflicts and re-run, or 'git rebase --abort'." >&2
    git rebase --abort >/dev/null 2>&1 || true
    git checkout "$current_branch" >/dev/null 2>&1 || true
    exit 1
  fi
fi

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
