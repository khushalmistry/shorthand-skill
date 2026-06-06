#!/usr/bin/env bash
# shorthand-skill — installer
# Copy skill files to the user's agent skill directory.
# Works with Hermes Agent, Claude Code, OpenCode, and any agent that reads SKILL.md files.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/khushalmistry/shorthand-skill/main/install.sh | bash
#   # Or from a local clone:
#   bash install.sh

set -euo pipefail

REPO="khushalmistry/shorthand-skill"
BRANCH="main"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo "  ✏️  shorthand-skill installer"
echo "  compress skill files 35-40%. same data. fewer tokens. zero loss."
echo ""

# Determine target directory
HERMES_SKILLS="${HOME}/.hermes/skills"
CLAUDE_SKILLS="${HOME}/.claude/skills"

TARGET=""
if [ -d "$HERMES_SKILLS" ]; then
  TARGET="$HERMES_SKILLS"
  echo -e "  ${GREEN}✓${NC} Found Hermes Agent skills directory: $HERMES_SKILLS"
elif [ -d "$CLAUDE_SKILLS" ]; then
  TARGET="$CLAUDE_SKILLS"
  echo -e "  ${GREEN}✓${NC} Found Claude Code skills directory: $CLAUDE_SKILLS"
else
  # Default to Hermes
  TARGET="$HERMES_SKILLS"
  mkdir -p "$TARGET"
  echo -e "  ${YELLOW}→${NC} Created skills directory: $TARGET"
fi

# If running from a local clone, copy from local files
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)" || SCRIPT_DIR=""

if [ -f "$SCRIPT_DIR/skills/shorthand/SKILL.md" ]; then
  echo -e "  ${BLUE}→${NC} Installing from local clone..."
  SOURCE="$SCRIPT_DIR/skills"
else
  echo -e "  ${BLUE}→${NC} Downloading from GitHub..."
  # Download to temp directory
  TMPDIR=$(mktemp -d)
  trap 'rm -rf "$TMPDIR"' EXIT

  # Download each skill file
  SKILLS="shorthand/SKILL.md shorthand-dict/SKILL.md shorthand-commit/SKILL.md shorthand-compress/SKILL.md"
  BASE_URL="https://raw.githubusercontent.com/${REPO}/${BRANCH}/skills"

  for skill_path in $SKILLS; do
    skill_name=$(dirname "$skill_path")
    mkdir -p "$TMPDIR/$skill_name"
    echo -e "  ${BLUE}  ↓${NC} $skill_name"
    curl -fsSL "$BASE_URL/$skill_path" -o "$TMPDIR/$skill_path" 2>/dev/null || {
      echo -e "  ${RED}✗${NC} Failed to download $skill_path"
      exit 1
    }
  done

  # Download sample skills
  SAMPLES="port-scanner.md tool-setup.md"
  mkdir -p "$TMPDIR/samples"
  for sample in $SAMPLES; do
    echo -e "  ${BLUE}  ↓${NC} samples/$sample"
    curl -fsSL "$BASE_URL/samples/$sample" -o "$TMPDIR/samples/$sample" 2>/dev/null || {
      echo -e "  ${RED}✗${NC} Failed to download samples/$sample"
      exit 1
    }
  done

  # Download dictionary
  echo -e "  ${BLUE}  ↓${NC} shorthand-dict dictionary"
  SOURCE="$TMPDIR"
fi

# Copy skills
echo ""
echo -e "  ${GREEN}→${NC} Installing skills to $TARGET"

SKILL_NAMES="shorthand shorthand-dict shorthand-commit shorthand-compress"
for skill_name in $SKILL_NAMES; do
  mkdir -p "$TARGET/$skill_name"
  if [ -f "$SOURCE/$skill_name/SKILL.md" ]; then
    cp "$SOURCE/$skill_name/SKILL.md" "$TARGET/$skill_name/SKILL.md"
    echo -e "  ${GREEN}✓${NC} $skill_name"
  fi
done

# Copy samples
echo ""
echo -e "  ${GREEN}→${NC} Installing sample skills"
mkdir -p "$TARGET/samples"
for sample in "$SOURCE"/samples/*.md; do
  if [ -f "$sample" ]; then
    cp "$sample" "$TARGET/samples/"
    echo -e "  ${GREEN}✓${NC} samples/$(basename "$sample")"
  fi
done

echo ""
echo -e "  ${GREEN}✓${NC} Installation complete!"
echo ""
echo "  Skills installed:"
echo "    • shorthand        — Core compression notation"
echo "    • shorthand-dict   — Dictionary of all symbols & patterns"
echo "    • shorthand-commit — Compressed commit messages"
echo "    • shorthand-compress — Convert verbose skills to shorthand"
echo ""
echo "  Sample skills:"
echo "    • port-scanner     — Network reconnaissance (shorthand format)"
echo "    • tool-setup       — Universal dependency resolver (shorthand format)"
echo ""
echo "  Usage: Load shorthand-dict first, then write skills using the notation."
echo "  See: https://github.com/${REPO}"
echo ""