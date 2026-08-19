#!/bin/bash

# Script to promote a draft from _drafts/ into _posts/ so GitHub Pages builds it.
# Moves the file to _posts/YYYY-MM-DD-<slug>.md and stamps the date: field.
# Does not commit or push -- review the result first.
#
# Usage: scripts/publish-draft.sh <slug>

# Set the base directory to the repository root
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

SLUG="$1"

if [ -z "$SLUG" ]; then
  echo "Usage: scripts/publish-draft.sh <slug>"
  echo "Example: scripts/publish-draft.sh jvm-warmup-latency"
  exit 1
fi

DRAFT_FILE="$BASE_DIR/_drafts/$SLUG.md"

if [ ! -f "$DRAFT_FILE" ]; then
  echo "Error: no draft found at $DRAFT_FILE"
  echo "Available drafts:"
  find "$BASE_DIR/_drafts" -maxdepth 1 -name '*.md' -exec basename {} .md \; 2>/dev/null | sed 's/^/  /'
  exit 1
fi

DATE="$(date +%F)"
YEAR="$(date +%Y)"
POST_FILE="$BASE_DIR/_posts/$DATE-$SLUG.md"

if [ -e "$POST_FILE" ]; then
  echo "Error: target already exists at $POST_FILE"
  exit 1
fi

mkdir -p "$BASE_DIR/_posts"

# Stamp the date into the front matter unless the author already set one.
# The front matter is the block between the first two --- lines.
if awk '/^---[[:space:]]*$/ {n++; next} n == 1 && /^date:/ {found = 1} END {exit !found}' "$DRAFT_FILE"; then
  echo "Front matter already has a date: field, leaving it as is"
else
  TMP_FILE="$(mktemp)"
  awk -v date="$DATE" '
    /^---[[:space:]]*$/ { n++ }
    { print }
    n == 1 && !done && /^title:/ { print "date: " date; done = 1 }
  ' "$DRAFT_FILE" > "$TMP_FILE"

  if ! grep -q "^date: $DATE\$" "$TMP_FILE"; then
    rm -f "$TMP_FILE"
    echo "Error: could not insert date: into the front matter of $DRAFT_FILE"
    echo "Add a 'date: $DATE' line under title: manually, then rerun."
    exit 1
  fi

  cat "$TMP_FILE" > "$DRAFT_FILE"
  rm -f "$TMP_FILE"
fi

# Use git mv so the move is recorded as a rename, but only when the draft is
# actually tracked -- git mv refuses on a draft that was never committed.
if git -C "$BASE_DIR" ls-files --error-unmatch "$DRAFT_FILE" > /dev/null 2>&1; then
  git -C "$BASE_DIR" mv "$DRAFT_FILE" "$POST_FILE"
else
  mv "$DRAFT_FILE" "$POST_FILE"
fi

if [ $? -ne 0 ]; then
  echo "Error: failed to move $DRAFT_FILE to $POST_FILE"
  exit 1
fi

echo "Published:"
echo "  _drafts/$SLUG.md"
echo "    -> _posts/$DATE-$SLUG.md"
echo "  URL: /blog/$YEAR/$SLUG/"
echo
echo "Review categories: and tags: in the front matter, then commit and push."

exit 0
