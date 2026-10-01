#!/usr/bin/env bash
# Create a Git worktree + branch for one agent job, next to your Unity project.
#
# Usage:  scripts/new-agent-worktree.sh <job-name> [base-ref]
#   COPY_LIBRARY=1  copy Library/ from the main checkout to skip most of the first reimport
#   PROJECT_SUBDIR  path of the Unity project inside the repo, if it is not the repo root
#
# Example: scripts/new-agent-worktree.sh combat-parry main
#   -> ../<repo>-combat-parry on branch agent/combat-parry
set -euo pipefail

job="${1:?usage: new-agent-worktree.sh <job-name> [base-ref]}"
base="${2:-HEAD}"
root="$(git rev-parse --show-toplevel)"
dest="$(dirname "$root")/$(basename "$root")-$job"
branch="agent/$job"
sub="${PROJECT_SUBDIR:-.}"

git -C "$root" worktree add -b "$branch" "$dest" "$base"

if [ "${COPY_LIBRARY:-0}" = "1" ] && [ -d "$root/$sub/Library" ]; then
  echo "Copying Library/ (Unity revalidates it on open; delete it if the editor complains)..."
  cp -r "$root/$sub/Library" "$dest/$sub/Library"
fi

echo
echo "Worktree: $dest"
echo "Branch:   $branch"
echo "Point the agent at: $dest/$sub"
echo "Remove when merged: git worktree remove \"$dest\" && git branch -d \"$branch\""
