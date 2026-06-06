#!/usr/bin/env bash
# shorthand-skill — installer
# Copy skill folders to the user's agent skill directory.
# Works with Hermes Agent, Claude Code, Codex, OpenCode, and custom skill directories.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/khushalmistry/shorthand-skill/main/install.sh | bash -s -- --agent codex
#   # Or from a local clone:
#   bash install.sh --agent codex
#   bash install.sh --target /path/to/skills --ref <tag-or-sha>

set -euo pipefail

REPO="khushalmistry/shorthand-skill"
REF="${SHORTHAND_SKILL_REF:-main}"
AGENT="auto"
TARGET=""
INSTALL_SET="all"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo "  ✏️  shorthand-skill installer"
echo "  compress skill files ~35-40%. same data. fewer tokens. zero evaluated loss."
echo ""

usage() {
  cat <<EOF
Usage: bash install.sh [options]

Options:
  --agent <name>    auto|hermes|claude|codex|opencode (default: auto)
  --target <dir>    install into an explicit skills directory
  --ref <ref>       Git ref/tag/SHA to download when not running from a clone
  --core-only       install only shorthand, shorthand-dict, shorthand-commit, shorthand-compress
  -h, --help        show this help

Examples:
  bash install.sh --agent codex
  bash install.sh --agent claude --core-only
  SHORTHAND_SKILL_REF="tag-or-sha" bash install.sh --target ~/.codex/skills
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --agent)
      AGENT="${2:-}"
      shift 2
      ;;
    --target)
      TARGET="${2:-}"
      shift 2
      ;;
    --ref)
      REF="${2:-}"
      shift 2
      ;;
    --core-only)
      INSTALL_SET="core"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo -e "  ${RED}✗${NC} Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

skill_dir_for_agent() {
  case "$1" in
    hermes) echo "${HOME}/.hermes/skills" ;;
    claude) echo "${HOME}/.claude/skills" ;;
    codex) echo "${HOME}/.codex/skills" ;;
    opencode) echo "${HOME}/.opencode/skills" ;;
    auto) echo "" ;;
    *)
      echo ""
      return 1
      ;;
  esac
}

# Determine target directory
HERMES_SKILLS="${HOME}/.hermes/skills"
CLAUDE_SKILLS="${HOME}/.claude/skills"
CODEX_SKILLS="${HOME}/.codex/skills"
OPENCODE_SKILLS="${HOME}/.opencode/skills"

if [ -n "$TARGET" ]; then
  mkdir -p "$TARGET"
  echo -e "  ${GREEN}✓${NC} Using explicit skills directory: $TARGET"
elif [ "$AGENT" != "auto" ]; then
  TARGET="$(skill_dir_for_agent "$AGENT")" || {
    echo -e "  ${RED}✗${NC} Unsupported agent: $AGENT"
    usage
    exit 1
  }
  mkdir -p "$TARGET"
  echo -e "  ${GREEN}✓${NC} Using $AGENT skills directory: $TARGET"
else
  if [ -d "$HERMES_SKILLS" ]; then
    TARGET="$HERMES_SKILLS"
    echo -e "  ${GREEN}✓${NC} Found Hermes Agent skills directory: $HERMES_SKILLS"
  elif [ -d "$CLAUDE_SKILLS" ]; then
    TARGET="$CLAUDE_SKILLS"
    echo -e "  ${GREEN}✓${NC} Found Claude Code skills directory: $CLAUDE_SKILLS"
  elif [ -d "$CODEX_SKILLS" ]; then
    TARGET="$CODEX_SKILLS"
    echo -e "  ${GREEN}✓${NC} Found Codex skills directory: $CODEX_SKILLS"
  elif [ -d "$OPENCODE_SKILLS" ]; then
    TARGET="$OPENCODE_SKILLS"
    echo -e "  ${GREEN}✓${NC} Found OpenCode skills directory: $OPENCODE_SKILLS"
  else
    # Preserve the original Hermes-native default when no agent is detectable.
    TARGET="$HERMES_SKILLS"
  fi
  mkdir -p "$TARGET"
  echo -e "  ${YELLOW}→${NC} Created/using skills directory: $TARGET"
fi

CORE_SKILLS="shorthand shorthand-dict shorthand-commit shorthand-compress"
EXAMPLE_SKILLS="tool-setup port-scanner"
if [ "$INSTALL_SET" = "core" ]; then
  SKILL_NAMES="$CORE_SKILLS"
else
  SKILL_NAMES="$CORE_SKILLS $EXAMPLE_SKILLS"
fi

# If running from a local clone, copy from local files
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)" || SCRIPT_DIR=""

if [ -f "$SCRIPT_DIR/skills/shorthand/SKILL.md" ]; then
  echo -e "  ${BLUE}→${NC} Installing from local clone..."
  SOURCE="$SCRIPT_DIR/skills"
else
  echo -e "  ${BLUE}→${NC} Downloading from GitHub ref: $REF"
  # Download to temp directory
  TMPDIR=$(mktemp -d)
  trap 'rm -rf "$TMPDIR"' EXIT

  BASE_URL="https://raw.githubusercontent.com/${REPO}/${REF}/skills"
  FILES="
shorthand/SKILL.md
shorthand/references/DICTIONARY.md
shorthand-dict/SKILL.md
shorthand-commit/SKILL.md
shorthand-compress/SKILL.md
tool-setup/SKILL.md
port-scanner/SKILL.md
"

  for file_path in $FILES; do
    top_dir="${file_path%%/*}"
    case " $SKILL_NAMES " in
      *" $top_dir "*) ;;
      *) continue ;;
    esac
    mkdir -p "$TMPDIR/$(dirname "$file_path")"
    echo -e "  ${BLUE}  ↓${NC} $file_path"
    curl -fsSL "$BASE_URL/$file_path" -o "$TMPDIR/$file_path" 2>/dev/null || {
      echo -e "  ${RED}✗${NC} Failed to download $file_path"
      exit 1
    }
  done
  SOURCE="$TMPDIR"
fi

# Copy skills
echo ""
echo -e "  ${GREEN}→${NC} Installing skills to $TARGET"

for skill_name in $SKILL_NAMES; do
  mkdir -p "$TARGET/$skill_name"
  if [ -f "$SOURCE/$skill_name/SKILL.md" ]; then
    cp -R "$SOURCE/$skill_name/." "$TARGET/$skill_name/"
    echo -e "  ${GREEN}✓${NC} $skill_name"
  else
    echo -e "  ${YELLOW}!${NC} missing $skill_name in source; skipped"
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
if [ "$INSTALL_SET" != "core" ]; then
  echo "    • tool-setup       — Approval-gated dependency resolver"
  echo "    • port-scanner     — Authorization-gated network reconnaissance"
fi
echo ""
echo "  Usage: Use shorthand, or read shorthand/references/DICTIONARY.md for the notation."
echo "  See: https://github.com/${REPO}"
echo ""
