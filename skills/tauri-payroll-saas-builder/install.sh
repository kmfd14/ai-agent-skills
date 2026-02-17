#!/bin/bash

# Tauri Payroll SaaS Builder - Skill Installation Script
# This script installs the custom Claude skill for VS Code extensions

set -e

echo "=================================================="
echo "Tauri Payroll SaaS Builder - Skill Installer"
echo "=================================================="
echo ""

# Detect OS
OS="$(uname -s)"
case "${OS}" in
    Linux*)     PLATFORM=linux;;
    Darwin*)    PLATFORM=mac;;
    CYGWIN*)    PLATFORM=windows;;
    MINGW*)     PLATFORM=windows;;
    *)          PLATFORM="unknown"
esac

echo "Detected platform: $PLATFORM"
echo ""

# Determine skill installation directory
if [ "$PLATFORM" = "linux" ] || [ "$PLATFORM" = "mac" ]; then
    CONTINUE_DIR="$HOME/.continue/skills"
    CLAUDE_DEV_DIR="$HOME/.vscode/extensions/claude-dev-skills"
elif [ "$PLATFORM" = "windows" ]; then
    CONTINUE_DIR="$USERPROFILE/.continue/skills"
    CLAUDE_DEV_DIR="$USERPROFILE/.vscode/extensions/claude-dev-skills"
else
    echo "Error: Unsupported platform"
    exit 1
fi

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_NAME="tauri-payroll-saas-builder"

echo "Select your VS Code Claude extension:"
echo "1) Continue"
echo "2) Claude Dev / Cline"
echo "3) Manual (just show me the paths)"
echo ""
read -p "Enter choice [1-3]: " choice

case $choice in
    1)
        echo ""
        echo "Installing for Continue extension..."
        
        # Create directory if it doesn't exist
        mkdir -p "$CONTINUE_DIR"
        
        # Copy skill
        if [ -d "$CONTINUE_DIR/$SKILL_NAME" ]; then
            echo "Skill already exists. Backing up..."
            mv "$CONTINUE_DIR/$SKILL_NAME" "$CONTINUE_DIR/${SKILL_NAME}.backup.$(date +%s)"
        fi
        
        cp -r "$SCRIPT_DIR" "$CONTINUE_DIR/$SKILL_NAME"
        
        echo ""
        echo "✅ Skill installed successfully!"
        echo ""
        echo "Next steps:"
        echo "1. Open VS Code"
        echo "2. Press Cmd/Ctrl + Shift + P"
        echo "3. Search for 'Continue: Open Config'"
        echo "4. Add this to your config.json:"
        echo ""
        echo '{
  "skills": [
    {
      "name": "tauri-payroll-saas-builder",
      "path": "'$CONTINUE_DIR/$SKILL_NAME'/SKILL.md"
    }
  ]
}'
        echo ""
        echo "5. Reload VS Code"
        echo "6. Use @tauri-payroll-saas-builder in Continue chat"
        ;;
        
    2)
        echo ""
        echo "Installing for Claude Dev / Cline extension..."
        
        # Create directory if it doesn't exist
        mkdir -p "$CLAUDE_DEV_DIR"
        
        # Copy skill
        if [ -d "$CLAUDE_DEV_DIR/$SKILL_NAME" ]; then
            echo "Skill already exists. Backing up..."
            mv "$CLAUDE_DEV_DIR/$SKILL_NAME" "$CLAUDE_DEV_DIR/${SKILL_NAME}.backup.$(date +%s)"
        fi
        
        cp -r "$SCRIPT_DIR" "$CLAUDE_DEV_DIR/$SKILL_NAME"
        
        echo ""
        echo "✅ Skill installed successfully!"
        echo ""
        echo "Next steps:"
        echo "1. Open VS Code"
        echo "2. In Claude Dev/Cline chat, reference the skill by pasting SKILL.md content"
        echo "3. Or configure Claude Dev to auto-load skills"
        echo ""
        echo "Skill location: $CLAUDE_DEV_DIR/$SKILL_NAME/SKILL.md"
        ;;
        
    3)
        echo ""
        echo "Manual Installation Paths:"
        echo ""
        echo "For Continue:"
        echo "  Copy to: $CONTINUE_DIR/$SKILL_NAME/"
        echo ""
        echo "For Claude Dev/Cline:"
        echo "  Copy to: $CLAUDE_DEV_DIR/$SKILL_NAME/"
        echo ""
        echo "Source directory: $SCRIPT_DIR"
        ;;
        
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

echo ""
echo "Installation complete! See README.md for usage instructions."
echo "=================================================="
