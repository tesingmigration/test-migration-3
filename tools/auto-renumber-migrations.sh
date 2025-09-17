#!/usr/bin/env bash
set -euo pipefail

MIGRATION_DIR="migrations"
BASE_BRANCH="origin/main"

echo "👉 Fetching base branch: $BASE_BRANCH"
git fetch origin main

# Find the highest migration number in base branch
LAST_NUM=$(git ls-tree -r $BASE_BRANCH --name-only \
  | grep -E "^${MIGRATION_DIR}/[0-9]+_" \
  | sed -E "s@^.*/([0-9]+)_.+@\1@" \
  | sort -n | tail -n1)

LAST_NUM=${LAST_NUM:-0}
NEXT_NUM=$((LAST_NUM+1))

echo "📌 Highest migration number in $BASE_BRANCH: $LAST_NUM"

# Collect all migration files in current branch
FILES=$(ls "$MIGRATION_DIR" | grep -E '^[0-9]+_' | sort -n) || true

if [ -z "$FILES" ]; then
  echo "✅ No migration files found. Nothing to renumber."
  exit 0
fi

echo "⚡ Renumbering migration files..."
TMP_SUFFIX=".tmp$$"

# First, rename everything to a temporary name to avoid collisions
for f in $FILES; do
  mv "$MIGRATION_DIR/$f" "$MIGRATION_DIR/$f$TMP_SUFFIX"
done

# Now assign new sequential numbers
for f in $FILES; do
  ext=$(echo "$f" | sed -E 's/^[0-9]+_//')
  new=$(printf "%04d" $NEXT_NUM)_$ext
  mv "$MIGRATION_DIR/$f$TMP_SUFFIX" "$MIGRATION_DIR/$new"
  echo "🔄 $f → $new"
  NEXT_NUM=$((NEXT_NUM+1))
done

echo "✅ Renumbering completed."
