#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# FlAI Release Script
#
# Usage:  ./scripts/release.sh 0.3.0
#
# This script:
#   1. Validates the version and git state
#   2. Updates version in: pubspec.yaml, package.json, homepage badge, CHANGELOG
#   3. Commits all changes as "chore: release v{VERSION}"
#   4. Creates a git tag v{VERSION}
#   5. Pushes commit + tag → triggers the release workflow
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

# ── Update versions ───────────────────────────────────────────────────────

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

# 5. CHANGELOG — add header if not present
if ! grep -q "## \[${VERSION}\]" CHANGELOG.md; then
  DATE=$(date +%Y-%m-%d)
  # Insert new version header after the first "# Changelog" line
  sed -i '' "/^# Changelog/a\\
\\
## [${VERSION}] - ${DATE}\\
" CHANGELOG.md
  echo "  ✓ CHANGELOG.md (added ${VERSION} header — edit release notes before confirming)"
else
  echo "  ✓ CHANGELOG.md (${VERSION} header already exists)"
fi

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
echo "✓ Released ${TAG}"
echo ""
echo "GitHub Actions will now:"
echo "  1. Run CI checks"
echo "  2. Publish flai_cli to pub.dev"
echo "  3. Publish @getflai/mcp to npm"
echo "  4. Deploy docs to Cloudflare Pages"
echo "  5. Create GitHub Release"
echo ""
echo "Track progress: https://github.com/getflai-dev/flai/actions"
