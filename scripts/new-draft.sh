#!/bin/bash

# Script to scaffold a new blog post draft in _drafts/
# Drafts are tracked in git but never built by GitHub Pages, so they are safe
# to commit and push while still being written.
#
# Usage: scripts/new-draft.sh <slug>

# Set the base directory to the repository root
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

SLUG="$1"

if [ -z "$SLUG" ]; then
  echo "Usage: scripts/new-draft.sh <slug>"
  echo "Example: scripts/new-draft.sh jvm-warmup-latency"
  exit 1
fi

# Keep slugs URL-safe: lowercase letters, digits and hyphens only
if ! [[ "$SLUG" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
  echo "Error: slug must be lowercase words separated by single hyphens (got '$SLUG')"
  exit 1
fi

DRAFT_FILE="$BASE_DIR/_drafts/$SLUG.md"

if [ -e "$DRAFT_FILE" ]; then
  echo "Error: draft already exists at $DRAFT_FILE"
  exit 1
fi

# A published post with the same slug would collide on the /blog/:year/:title/ permalink
EXISTING_POST="$(find "$BASE_DIR/_posts" -maxdepth 1 -name "*-$SLUG.md" -print -quit 2>/dev/null)"
if [ -n "$EXISTING_POST" ]; then
  echo "Error: a published post with this slug already exists at $EXISTING_POST"
  exit 1
fi

# Humanize the slug into a starting title: "jvm-warmup" -> "Jvm Warmup"
TITLE="$(echo "$SLUG" | tr '-' ' ' | awk '{for (i = 1; i <= NF; i++) $i = toupper(substr($i, 1, 1)) substr($i, 2); print}')"

mkdir -p "$BASE_DIR/_drafts"

# No date: and no layout: on purpose. publish-draft.sh stamps the date, and the
# layout comes from the type: posts defaults in _config.yml.
cat > "$DRAFT_FILE" <<EOF
---
title: "$TITLE"
categories:
tags:
toc: true # post map in the right sidebar; needs 2+ headings to show
---

<!-- The first paragraph becomes the excerpt on /year-archive/, /categories/
     and /tags/ (excerpt_separator is a blank line). Make it stand alone. -->

## Notes

-
EOF

echo "Created $DRAFT_FILE"
echo "Preview with ./serve_localy.sh, publish with scripts/publish-draft.sh $SLUG"

exit 0
