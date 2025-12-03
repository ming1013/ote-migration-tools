#!/bin/bash

# OTE Migration Tools Installer
# This script copies the Claude Code slash commands to a target repository

set -e

TARGET_REPO="$1"

if [ -z "$TARGET_REPO" ]; then
    echo "Usage: ./install.sh <target-repository-path>"
    echo ""
    echo "Example:"
    echo "  ./install.sh ~/repos/openshift/sdn"
    echo ""
    echo "This will copy the .claude/commands/ directory to the target repository"
    echo "so you can use /analyze-for-ote and /migrate-ote commands there."
    exit 1
fi

# Resolve to absolute path
TARGET_REPO=$(realpath "$TARGET_REPO")

if [ ! -d "$TARGET_REPO" ]; then
    echo "Error: Directory '$TARGET_REPO' does not exist"
    exit 1
fi

echo "Installing OTE migration tools to: $TARGET_REPO"

# Get the script directory (where this script is located)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Copy .claude directory
if [ -d "$TARGET_REPO/.claude" ]; then
    echo "Warning: $TARGET_REPO/.claude already exists"
    read -p "Overwrite? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled"
        exit 0
    fi
    rm -rf "$TARGET_REPO/.claude"
fi

cp -r "$SCRIPT_DIR/.claude" "$TARGET_REPO/"

echo ""
echo "✅ Successfully installed OTE migration tools!"
echo ""
echo "Next steps:"
echo "  1. cd $TARGET_REPO"
echo "  2. Restart Claude Code"
echo "  3. Run /migrate-ote"
echo ""
