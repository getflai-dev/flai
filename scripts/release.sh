#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# FlAI Release Script
#
# Usage:  ./scripts/release.sh 0.3.0
#
# This script:
#   1. Validates the version and git state
#   2. Auto-generates CHANGELOG from git commits since last tag
#   3. Updates version in: pubspec.yaml, package.json, homepage badge
#   4. Commits all changes as "chore: release v{VERSION}"
#   5. Creates a git tag v{VERSION}
#   6. Pushes commit + tag → triggers the release workflow
# ─────────────────────────────────────────────────────────────────────────────

VERSION="${1:-}"

if [ -z "$VERSION" ]; then
  echo "Usage: ./scripts/release.sh <version>"
  echo "Example: ./scripts/release.sh 0.3.0"
  exit 1
fi

# Strip leading 'v' if provided
VERSION="${VERSION#v}"
TAG="v${VERSION}"
DATE=$(date +%Y-%m-%d)

echo "Releasing FlAI ${TAG}"
echo "────────────────────────────────"

# ── Preflight checks ──────────────────────────────────────────────────────

# Must be on main
BRANCH=$(git branch --show-current)
if [ "$BRANCH" != "main" ]; then
  echo "Error: Must be on main branch (currently on ${BRANCH})"
  exit 1
fi

# Working tree must be clean
if [ -n "$(git status --porcelain)" ]; then
  echo "Error: Working tree is not clean. Commit or stash changes first."
  exit 1
fi

# Tag must not already exist
if git rev-parse "$TAG" >/dev/null 2>&1; then
  echo "Error: Tag ${TAG} already exists"
  exit 1
fi

# Pull latest
echo "Pulling latest from origin..."
git pull origin main --quiet

# ── Auto-generate CHANGELOG ──────────────────────────────────────────────

echo "Generating changelog..."

# Find previous tag
PREV_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
if [ -z "$PREV_TAG" ]; then
  RANGE="HEAD"
  echo "  No previous tag found — including all commits"
else
  RANGE="${PREV_TAG}..HEAD"
  echo "  Changes since ${PREV_TAG}"
fi

# Collect commits by category
ADDED=""
CHANGED=""
FIXED=""
DOCS=""
CI=""
OTHER=""

while IFS= read -r line; do
  # Skip empty lines and merge commits
  [ -z "$line" ] && continue
  echo "$line" | grep -q "^Merge" && continue

  # Categorize by conventional commit prefix
  if echo "$line" | grep -qi "^feat"; then
    msg=$(echo "$line" | sed 's/^feat[:(]*//' | sed 's/^[^:]*: *//' | sed 's/^ *//')
    ADDED="${ADDED}- ${msg}\n"
  elif echo "$line" | grep -qi "^fix"; then
    msg=$(echo "$line" | sed 's/^fix[:(]*//' | sed 's/^[^:]*: *//' | sed 's/^ *//')
    FIXED="${FIXED}- ${msg}\n"
  elif echo "$line" | grep -qi "^docs"; then
    msg=$(echo "$line" | sed 's/^docs[:(]*//' | sed 's/^[^:]*: *//' | sed 's/^ *//')
    DOCS="${DOCS}- ${msg}\n"
  elif echo "$line" | grep -qi "^ci"; then
    msg=$(echo "$line" | sed 's/^ci[:(]*//' | sed 's/^[^:]*: *//' | sed 's/^ *//')
    CI="${CI}- ${msg}\n"
  elif echo "$line" | grep -qi "^chore\|^refactor\|^perf\|^style"; then
    msg=$(echo "$line" | sed 's/^[a-z]*[:(]*//' | sed 's/^[^:]*: *//' | sed 's/^ *//')
    CHANGED="${CHANGED}- ${msg}\n"
  else
    OTHER="${OTHER}- ${line}\n"
  fi
done < <(git log "$RANGE" --pretty=format:"%s" --no-merges)

# Build the changelog entry
ENTRY="## [${VERSION}] - ${DATE}\n"

if [ -n "$ADDED" ]; then
  ENTRY="${ENTRY}\n### Added\n\n${ADDED}"
fi
if [ -n "$CHANGED" ]; then
  ENTRY="${ENTRY}\n### Changed\n\n${CHANGED}"
fi
if [ -n "$FIXED" ]; then
  ENTRY="${ENTRY}\n### Fixed\n\n${FIXED}"
fi
if [ -n "$DOCS" ]; then
  ENTRY="${ENTRY}\n### Documentation\n\n${DOCS}"
fi
if [ -n "$CI" ]; then
  ENTRY="${ENTRY}\n### CI/CD\n\n${CI}"
fi
if [ -n "$OTHER" ]; then
  ENTRY="${ENTRY}\n### Other\n\n${OTHER}"
fi

# Preview the changelog
echo ""
echo "Generated changelog:"
echo "────────────────────────────────"
echo -e "$ENTRY"
echo "────────────────────────────────"

# Insert into CHANGELOG.md after the header
if grep -q "## \[${VERSION}\]" CHANGELOG.md; then
  echo "  ✓ CHANGELOG.md (${VERSION} entry already exists — skipping)"
else
  # Insert after "# Changelog" line (or first line)
  TMPFILE=$(mktemp)
  awk -v entry="$(echo -e "$ENTRY")" '
    /^# Changelog/ { print; print ""; print entry; next }
    { print }
  ' CHANGELOG.md > "$TMPFILE"
  mv "$TMPFILE" CHANGELOG.md
  echo "  ✓ CHANGELOG.md"
fi

# ── Update versions ───────────────────────────────────────────────────────

echo ""
echo "Updating versions to ${VERSION}..."

# 1. CLI pubspec.yaml
sed -i '' "s/^version: .*/version: ${VERSION}/" packages/flai_cli/pubspec.yaml
echo "  ✓ packages/flai_cli/pubspec.yaml"

# 2. MCP package.json
sed -i '' "s/\"version\": \".*\"/\"version\": \"${VERSION}\"/" packages/flai_mcp/package.json
echo "  ✓ packages/flai_mcp/package.json"

# 3. MCP server version in index.ts
sed -i '' "s/version: \".*\"/version: \"${VERSION}\"/" packages/flai_mcp/src/index.ts
echo "  ✓ packages/flai_mcp/src/index.ts"

# 4. Homepage version badge
sed -i '' "s/v[0-9]*\.[0-9]*\.[0-9]*/v${VERSION}/g" docs-site/index.html
echo "  ✓ docs-site/index.html"

# ── Show diff and confirm ─────────────────────────────────────────────────

echo ""
echo "────────────────────────────────"
echo "Files changed:"
git diff --stat
echo ""

read -p "Commit, tag ${TAG}, and push? [y/N] " CONFIRM
if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
  echo "Aborted. Reverting changes..."
  git checkout -- .
  exit 0
fi

# ── Commit, tag, push ─────────────────────────────────────────────────────

git add -A
git commit -m "chore: release ${TAG}"
git tag -a "$TAG" -m "Release ${TAG}"

echo ""
echo "Pushing commit and tag..."
git push origin main
git push origin "$TAG"

echo ""
echo "────────────────────────────────"
echo "Done! Released ${TAG}"
echo ""
echo "GitHub Actions will now:"
echo "  1. Run CI checks"
echo "  2. Publish flai_cli to pub.dev"
echo "  3. Publish @getflai/mcp to npm"
echo "  4. Deploy docs to Cloudflare Pages"
echo "  5. Create GitHub Release with changelog"
echo ""
echo "Track: https://github.com/getflai-dev/flai/actions"
