#!/bin/sh
# Rollback script for harness changes
set -eu

root_dir=$(cd "$(dirname "$0")/.." && pwd)
last_good_ref="${1:-HEAD~1}"

echo "=== Harness Rollback ==="
echo "Rolling back to: $last_good_ref"
echo ""

# Show what will be reverted
echo "Files to revert:"
git diff --name-only "$last_good_ref" -- .github bin scripts Makefile.harness AGENTS.md 2>/dev/null || true
echo ""

read -p "Continue with rollback? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Rollback cancelled."
  exit 0
fi

# Revert harness files
git checkout "$last_good_ref" -- .github bin scripts Makefile.harness AGENTS.md PLANS.md

echo "Rollback complete. Please review changes and re-run 'make ci' to verify."