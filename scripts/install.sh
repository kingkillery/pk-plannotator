#!/bin/bash
set -e

INSTALL_BASE_URL="https://plan.artificialgarden.org"
VERSION="0.19.22-pk.1"
SKILLS_REPO="kingkillery/pk-plannotator"
INSTALL_DIR="$HOME/.local/bin"

if ! command -v bun >/dev/null 2>&1; then
    echo "bun is required for the pk-plannotator installer. Install bun first, then rerun this installer." >&2
    exit 1
fi

bundle_name="pk-plannotator-bun.js"

# Clean up old Windows install locations (for users running bash on Windows)
if [ -n "$USERPROFILE" ]; then
    # Running on Windows (Git Bash, MSYS, etc.) - clean up old locations
    rm -f "$USERPROFILE/.local/bin/plannotator" "$USERPROFILE/.local/bin/plannotator.exe" 2>/dev/null || true
    rm -f "$LOCALAPPDATA/plannotator/plannotator.exe" 2>/dev/null || true
    echo "Cleaned up old Windows install locations"
fi

latest_tag="${VERSION}"
echo "Installing pk-plannotator ${latest_tag}..."

bundle_url="${INSTALL_BASE_URL}/download/${bundle_name}"
checksum_url="${bundle_url}.sha256"

mkdir -p "$INSTALL_DIR"

tmp_file=$(mktemp)
curl -fsSL -o "$tmp_file" "$bundle_url"

expected_checksum=$(curl -fsSL "$checksum_url" | cut -d' ' -f1)

if [ "$(uname -s)" = "Darwin" ]; then
    actual_checksum=$(shasum -a 256 "$tmp_file" | cut -d' ' -f1)
else
    actual_checksum=$(sha256sum "$tmp_file" | cut -d' ' -f1)
fi

if [ "$actual_checksum" != "$expected_checksum" ]; then
    echo "Checksum verification failed!" >&2
    rm -f "$tmp_file"
    exit 1
fi

# Remove old binary first (handles Windows .exe and locked file issues)
rm -f "$INSTALL_DIR/plannotator" "$INSTALL_DIR/plannotator.exe" "$INSTALL_DIR/pk-plannotator" "$INSTALL_DIR/pk-plannotator.exe" 2>/dev/null || true

mv "$tmp_file" "$INSTALL_DIR/pk-plannotator.js"
cat > "$INSTALL_DIR/pk-plannotator" << 'SHIM_EOF'
#!/bin/sh
DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
exec bun "$DIR/pk-plannotator.js" "$@"
SHIM_EOF
chmod +x "$INSTALL_DIR/pk-plannotator"
ln "$INSTALL_DIR/pk-plannotator" "$INSTALL_DIR/plannotator" 2>/dev/null || cp "$INSTALL_DIR/pk-plannotator" "$INSTALL_DIR/plannotator"

echo ""
echo "pk-plannotator ${latest_tag} installed to ${INSTALL_DIR}/pk-plannotator.js"
echo "plannotator resolves to ${INSTALL_DIR}/plannotator"

if ! echo "$PATH" | tr ':' '\n' | grep -qx "$INSTALL_DIR"; then
    echo ""
    echo "${INSTALL_DIR} is not in your PATH. Add it with:"
    echo ""

    case "$SHELL" in
        */zsh)  shell_config="~/.zshrc" ;;
        */bash) shell_config="~/.bashrc" ;;
        *)      shell_config="your shell config" ;;
    esac

    echo "  echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ${shell_config}"
    echo "  source ${shell_config}"
fi

# Validate plugin hooks.json if plugin is already installed
PLUGIN_HOOKS="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/plugins/marketplaces/plannotator/apps/hook/hooks/hooks.json"
if [ -f "$PLUGIN_HOOKS" ]; then
    cat > "$PLUGIN_HOOKS" << 'HOOKS_EOF'
{
  "hooks": {
    "PermissionRequest": [
      {
        "matcher": "ExitPlanMode",
        "hooks": [
          {
            "type": "command",
            "command": "plannotator",
            "timeout": 345600
          }
        ]
      }
    ]
  }
}
HOOKS_EOF
    echo "Updated plugin hooks at ${PLUGIN_HOOKS}"
fi

# Clear any cached OpenCode plugin to force fresh download on next run
rm -rf "$HOME/.cache/opencode/node_modules/@plannotator" "$HOME/.bun/install/cache/@plannotator" 2>/dev/null || true

# Clear Pi jiti cache to force fresh download on next run
rm -rf /tmp/jiti 2>/dev/null || true

# Update Pi extension if pi is installed
if command -v pi &>/dev/null; then
    echo "Updating Pi extension..."
    pi install npm:@plannotator/pi-extension
    echo "Pi extension updated."
fi

# Install /review slash command
CLAUDE_COMMANDS_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/commands"
mkdir -p "$CLAUDE_COMMANDS_DIR"

cat > "$CLAUDE_COMMANDS_DIR/plannotator-review.md" << 'COMMAND_EOF'
---
description: Open interactive code review for current changes or a PR URL
allowed-tools: Bash(plannotator:*)
---

## Code Review Feedback

!`plannotator review $ARGUMENTS`

## Your task

If the review above contains feedback or annotations, address them. If no changes were requested, acknowledge and continue.
COMMAND_EOF

echo "Installed /plannotator-review command to ${CLAUDE_COMMANDS_DIR}/plannotator-review.md"

# Install /annotate slash command for Claude Code
cat > "$CLAUDE_COMMANDS_DIR/plannotator-annotate.md" << 'COMMAND_EOF'
---
description: Open interactive annotation UI for a markdown file
allowed-tools: Bash(plannotator:*)
---

## Markdown Annotations

!`plannotator annotate $ARGUMENTS`

## Your task

Address the annotation feedback above. The user has reviewed the markdown file and provided specific annotations and comments.
COMMAND_EOF

echo "Installed /plannotator-annotate command to ${CLAUDE_COMMANDS_DIR}/plannotator-annotate.md"

# Install /plannotator-last slash command for Claude Code
cat > "$CLAUDE_COMMANDS_DIR/plannotator-last.md" << 'COMMAND_EOF'
---
description: Annotate the last rendered assistant message
allowed-tools: Bash(plannotator:*)
---

## Message Annotations

!`plannotator annotate-last`

## Your task

Address the annotation feedback above. The user has reviewed your last message and provided specific annotations and comments.
COMMAND_EOF

echo "Installed /plannotator-last command to ${CLAUDE_COMMANDS_DIR}/plannotator-last.md"

# Install OpenCode slash command
OPENCODE_COMMANDS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode/command"
mkdir -p "$OPENCODE_COMMANDS_DIR"

cat > "$OPENCODE_COMMANDS_DIR/plannotator-review.md" << 'COMMAND_EOF'
---
description: Open interactive code review for current changes
---

The Plannotator Code Review has been triggered. Opening the review UI...
Acknowledge "Opening code review..." and wait for the user's feedback.
COMMAND_EOF

echo "Installed /plannotator-review command to ${OPENCODE_COMMANDS_DIR}/plannotator-review.md"

# Install /annotate slash command for OpenCode
cat > "$OPENCODE_COMMANDS_DIR/plannotator-annotate.md" << 'COMMAND_EOF'
---
description: Open interactive annotation UI for a markdown file
---

The Plannotator Annotate has been triggered. Opening the annotation UI...
Acknowledge "Opening annotation UI..." and wait for the user's feedback.
COMMAND_EOF

echo "Installed /plannotator-annotate command to ${OPENCODE_COMMANDS_DIR}/plannotator-annotate.md"

# Install /plannotator-last slash command for OpenCode
cat > "$OPENCODE_COMMANDS_DIR/plannotator-last.md" << 'COMMAND_EOF'
---
description: Annotate the last assistant message
---
COMMAND_EOF

echo "Installed /plannotator-last command to ${OPENCODE_COMMANDS_DIR}/plannotator-last.md"

# Install skills (requires git)
if command -v git &>/dev/null; then
    CLAUDE_SKILLS_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills"
    AGENTS_SKILLS_DIR="$HOME/.agents/skills"
    skills_tmp=$(mktemp -d)

    if git clone --depth 1 --filter=blob:none --sparse \
        "https://github.com/${SKILLS_REPO}.git" "$skills_tmp/repo" 2>/dev/null && \
        cd "$skills_tmp/repo" && git sparse-checkout set apps/skills 2>/dev/null; then

        if [ -d "apps/skills" ] && [ "$(ls -A apps/skills 2>/dev/null)" ]; then
            mkdir -p "$CLAUDE_SKILLS_DIR" "$AGENTS_SKILLS_DIR"
            cp -r apps/skills/* "$CLAUDE_SKILLS_DIR/"
            cp -r apps/skills/* "$AGENTS_SKILLS_DIR/"
            echo "Installed skills to ${CLAUDE_SKILLS_DIR}/ and ${AGENTS_SKILLS_DIR}/"
        fi

        cd - >/dev/null
    else
        echo "Skipping skills install (git sparse-checkout failed)"
    fi

    rm -rf "$skills_tmp"
else
    echo "Skipping skills install (git not found)"
fi

# --- Gemini CLI support (only if Gemini is installed) ---
if [ -d "$HOME/.gemini" ]; then
    # Install policy file
    GEMINI_POLICIES_DIR="$HOME/.gemini/policies"
    mkdir -p "$GEMINI_POLICIES_DIR"
    cat > "$GEMINI_POLICIES_DIR/plannotator.toml" << 'GEMINI_POLICY_EOF'
# Plannotator policy for Gemini CLI
# Allows exit_plan_mode without TUI confirmation so the browser UI is the sole gate.
[[rule]]
toolName = "exit_plan_mode"
decision = "allow"
priority = 100
GEMINI_POLICY_EOF
    echo "Installed Gemini policy to ${GEMINI_POLICIES_DIR}/plannotator.toml"

    # Configure hook in settings.json
    GEMINI_SETTINGS="$HOME/.gemini/settings.json"
    PLANNOTATOR_HOOK='{"matcher":"exit_plan_mode","hooks":[{"type":"command","command":"plannotator","timeout":345600}]}'

    if [ -f "$GEMINI_SETTINGS" ]; then
        if ! grep -q '"plannotator"' "$GEMINI_SETTINGS" 2>/dev/null; then
            # Merge hook into existing settings.json using node (ships with Gemini CLI)
            if command -v node &>/dev/null; then
                node -e "
                  const fs = require('fs');
                  const settings = JSON.parse(fs.readFileSync('$GEMINI_SETTINGS', 'utf8'));
                  if (!settings.hooks) settings.hooks = {};
                  if (!settings.hooks.BeforeTool) settings.hooks.BeforeTool = [];
                  settings.hooks.BeforeTool.push($PLANNOTATOR_HOOK);
                  fs.writeFileSync('$GEMINI_SETTINGS', JSON.stringify(settings, null, 2) + '\n');
                "
                echo "Added plannotator hook to ${GEMINI_SETTINGS}"
            else
                echo ""
                echo "Add the following to your ~/.gemini/settings.json hooks:"
                echo ""
                echo '  "hooks": {'
                echo '    "BeforeTool": [{'
                echo '      "matcher": "exit_plan_mode",'
                echo '      "hooks": [{"type": "command", "command": "plannotator", "timeout": 345600}]'
                echo '    }]'
                echo '  }'
            fi
        fi
    else
        cat > "$GEMINI_SETTINGS" << 'GEMINI_SETTINGS_EOF'
{
  "hooks": {
    "BeforeTool": [
      {
        "matcher": "exit_plan_mode",
        "hooks": [
          {
            "type": "command",
            "command": "plannotator",
            "timeout": 345600
          }
        ]
      }
    ]
  },
  "experimental": {
    "plan": true
  }
}
GEMINI_SETTINGS_EOF
        echo "Created Gemini settings at ${GEMINI_SETTINGS}"
    fi

    # Install slash commands
    GEMINI_COMMANDS_DIR="$HOME/.gemini/commands"
    mkdir -p "$GEMINI_COMMANDS_DIR"

    cat > "$GEMINI_COMMANDS_DIR/plannotator-review.toml" << 'GEMINI_CMD_EOF'
description = "Open interactive code review for current changes or a PR URL"
prompt = """
## Code Review Feedback

!{plannotator review {{args}}}

## Your task

If the review above contains feedback or annotations, address them. If no changes were requested, acknowledge and continue.
"""
GEMINI_CMD_EOF

    cat > "$GEMINI_COMMANDS_DIR/plannotator-annotate.toml" << 'GEMINI_CMD_EOF'
description = "Open interactive annotation UI for a markdown file or folder"
prompt = """
## Markdown Annotations

!{plannotator annotate {{args}}}

## Your task

Address the annotation feedback above. The user has reviewed the markdown file and provided specific annotations and comments.
"""
GEMINI_CMD_EOF

    echo "Installed Gemini slash commands to ${GEMINI_COMMANDS_DIR}/"
fi

echo ""
echo "=========================================="
echo "  OPENCODE USERS"
echo "=========================================="
echo ""
echo "Add the plugin to your opencode.json:"
echo ""
echo '  "plugin": ["@plannotator/opencode@latest"]'
echo ""
echo "Then restart OpenCode. The /plannotator-review, /plannotator-annotate, and /plannotator-last commands are ready!"
echo ""
echo "=========================================="
echo "  PI USERS"
echo "=========================================="
echo ""
echo "Install or update the extension:"
echo ""
echo "  pi install npm:@plannotator/pi-extension"
echo ""
echo "=========================================="
echo "  GEMINI CLI USERS"
echo "=========================================="
echo ""
echo "Enable plan mode in Gemini settings, then run:"
echo ""
echo "  gemini"
echo "  /plan"
echo ""
echo "Plans will open in your browser for review."
echo "If settings.json was not auto-configured, see:"
echo "  ~/.gemini/settings.json (add BeforeTool hook)"
echo ""
echo "=========================================="
echo "  CLAUDE CODE USERS: YOU'RE ALL SET!"
echo "=========================================="
echo ""
echo "Install the Claude Code plugin:"
echo "  /plugin marketplace add kingkillery/pk-plannotator"
echo "  /plugin install plannotator@plannotator"
echo ""
echo "The /plannotator-review, /plannotator-annotate, and /plannotator-last commands are ready to use after you restart Claude Code!"

# Warn if plannotator is configured in both settings.json hooks AND the plugin (causes double execution)
# Only warn when the plugin is installed — manual-only users won't have overlap
CLAUDE_SETTINGS="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json"
if [ -f "$PLUGIN_HOOKS" ] && [ -f "$CLAUDE_SETTINGS" ] && grep -q '"command".*plannotator' "$CLAUDE_SETTINGS" 2>/dev/null; then
    echo ""
    echo "⚠️ ⚠️ ⚠️  WARNING: DUPLICATE HOOK DETECTED  ⚠️ ⚠️ ⚠️"
    echo ""
    echo "  plannotator was found in your settings.json hooks:"
    echo "  $CLAUDE_SETTINGS"
    echo ""
    echo "  This will cause plannotator to run TWICE on each plan review."
    echo "  Remove the plannotator hook from settings.json and rely on the"
    echo "  plugin instead (installed automatically via marketplace)."
    echo ""
    echo "⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️"
fi
