#!/bin/bash

# Phantom Connect Skill Installer
# Installs the skill to Claude Code's skills directory

set -e

SKILL_NAME="phantom-connect"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$SCRIPT_DIR/skill"

# Default to personal skills directory
INSTALL_PATH="$HOME/.claude/skills/$SKILL_NAME"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --project)
      INSTALL_PATH=".claude/skills/$SKILL_NAME"
      shift
      ;;
    --path)
      INSTALL_PATH="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: ./install.sh [options]"
      echo ""
      echo "Options:"
      echo "  --project     Install to current project (.claude/skills/)"
      echo "  --path PATH   Install to custom path"
      echo "  -h, --help    Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Check if skill directory exists
if [ ! -d "$SKILL_DIR" ]; then
  echo "Error: skill/ directory not found"
  exit 1
fi

# Create parent directory if needed
mkdir -p "$(dirname "$INSTALL_PATH")"

# Copy skill files
echo "Installing Phantom Connect skill to: $INSTALL_PATH"
cp -r "$SKILL_DIR" "$INSTALL_PATH"

echo "✅ Successfully installed!"
echo ""
echo "The skill will be automatically available in Claude Code."
echo "Try asking: 'Help me connect a Phantom wallet in React'"
