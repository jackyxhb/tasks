#!/bin/sh
# Branch cognitive memory - creates decision summary on significant branches
set -eu

root_dir=$(cd "$(dirname "$0")/.." && pwd)
branch="${1:-$(git branch --show-current)}"
decision="${2:-}"

if [ -z "$branch" ]; then
  echo "Error: No branch name provided and not on a branch"
  exit 1
fi

if [ -z "$decision" ]; then
  echo "Usage: bin/branch-cognitive.sh <branch-name> '<decision summary>'"
  echo ""
  echo "Creates a commit documenting the branch's purpose and decisions."
  exit 1
fi

timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

commit_msg="cognitive: $decision

Branch: $branch
Timestamp: $timestamp

This commit records the reasoning and context for work on this branch.
"

git commit --allow-empty -m "$commit_msg" 2>/dev/null || echo "Warning: Not in a git repo or commit failed"

echo "Cognitive memory recorded for branch: $branch"
echo "Decision: $decision"