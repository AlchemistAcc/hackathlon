#!/bin/bash
set -e

echo "=========================================="
echo "Setting up Development Environment"
echo "=========================================="

# Load environment variables from .devcontainer/.env if it exists
ENV_FILE="$(dirname "$0")/.env"
if [ -f "$ENV_FILE" ]; then
    echo "Loading environment variables from .env..."
    set -a  # Automatically export all variables
    source "$ENV_FILE"
    set +a
else
    echo "Warning: .env file not found. Skipping API key configuration."
fi

echo ""
echo "------------------------------------------"
echo "Step 1: Installing Python 3.14..."
echo "------------------------------------------"
# Install expect if not already installed
if ! command -v expect &> /dev/null; then
    echo "Installing expect for interactive automation..."
    apt-get update &>/dev/null && apt-get install -y expect &>/dev/null
fi

uv python install 3.14

# Get the path to the installed python
PYTHON_PATH=$(uv python find 3.14)

echo "Setting Python 3.14 as default with a virtual environment..."
uv venv "$HOME/.python_env" --python 3.14 --clear

# Activate the venv for the rest of this script
source "$HOME/.python_env/bin/activate"

# Ensure ~/.bashrc activates this venv for all future shells
if ! grep -q "source \$HOME/.python_env/bin/activate" "$HOME/.bashrc"; then
    echo 'source "$HOME/.python_env/bin/activate"' >> "$HOME/.bashrc"
fi

echo ""
echo "------------------------------------------"
echo "Step 2: Installing Python dependencies..."
echo "------------------------------------------"
# Common Replit packages: flask, replit, and others they often use.
# Since we activated the venv, we don't need --python flag
uv pip install \
    flask \
    streamlit \
    requests \
    python-dotenv \
    pytest

python --version
python -c "import flask; import streamlit; import numpy; import pandas; print('Common Python packages installed successfully')"

echo ""
echo "------------------------------------------"
echo "Step 2.5: Setting up Playwright browser support..."
echo "------------------------------------------"
# Create symlink for Chrome so Playwright can find it
# Playwright looks for Chrome at /opt/google/chrome/chrome by default
# This container has Chrome installed at /opt/chrome/chrome
if [ -f "/opt/chrome/chrome" ]; then
    # Create/overwrite wrapper script that adds --no-sandbox flag (required for containerized Chrome)
    echo "Creating Chrome wrapper script with --no-sandbox..."
    sudo tee /opt/chrome/chrome-wrapper > /dev/null << 'WRAPPER_EOF'
#!/bin/bash
/opt/chrome/chrome --no-sandbox "$@"
WRAPPER_EOF
    sudo chmod +x /opt/chrome/chrome-wrapper
    echo "  ✓ Chrome wrapper created"

    # Create symlink from Playwright's expected path to the wrapper
    if [ ! -L "/opt/google/chrome/chrome" ]; then
        echo "Creating symlink for Playwright to use Chrome..."
        sudo mkdir -p /opt/google/chrome
        sudo ln -sf /opt/chrome/chrome-wrapper /opt/google/chrome/chrome
        echo "  ✓ Chrome symlink created at /opt/google/chrome/chrome"
    else
        echo "  ✓ Chrome symlink already exists"
    fi
else
    echo "  ⚠ Warning: Chrome not found at /opt/chrome/chrome"
fi

# Install emoji fonts for proper icon rendering in browsers
if ! dpkg -l | grep -q "fonts-noto-color-emoji"; then
    echo "Installing emoji fonts..."
    sudo apt update > /dev/null 2>&1
    sudo apt install -y fonts-noto-color-emoji > /dev/null 2>&1
    echo "  ✓ Emoji fonts installed"
else
    echo "  ✓ Emoji fonts already installed"
fi

echo ""
echo "------------------------------------------"
echo "Step 3: Setup GLM Coding Plan..."
echo "------------------------------------------"

# Authenticate with GLM coding plan if API key is provided
if [ -n "$ANTHROPIC_API_KEY" ]; then
    echo "Authenticating with GLM coding plan..."
    npx --yes @z_ai/coding-helper auth glm_coding_plan_global "$ANTHROPIC_API_KEY"
fi

# Use expect to automate the interactive claude-code setup
sudo apt update && sudo apt install expect -y 
# Only proceed if expect is available and ANTHROPIC_API_KEY is set
if ! command -v expect &> /dev/null; then
    echo "  ⚠ 'expect' not installed, skipping interactive setup"
    echo "    Install with: apt-get install -y expect"
elif [ -z "$ANTHROPIC_API_KEY" ]; then
    echo "  ⚠ ANTHROPIC_API_KEY not set, skipping Claude Code setup"
    echo "    Add your API key to .devcontainer/.env"
else
    echo "    expect"
    expect << 'EXPECT_EOF'
set timeout 60

spawn npx --yes @z_ai/coding-helper enter claude-code

# 1. Main Menu: Select "Apply Configuration" or "Configuration Refresh"
expect {
    "Apply Configuration" {}
    "Configuration Refresh" {}
}
send "\r"

# 2. Post-config Menu: Wait for menu to redraw, then navigate
expect "Configuration synchronized"
expect "Select action" ;# Wait for the prompt to reappear
# Send two down arrows to select "MCP Configuration"
send "\033\[B"
send "\033\[B"
send "\r"

# 3. MCP Menu: If "Install All" exists, run it; otherwise continue
expect {
    "Install All Plan Built-in MCP Services" {
        send "\r"
        expect "Are you sure"
        send "y\r"
        expect "Select MCP service"
    }
    "Select MCP service" {}
}

# 4. Exit immediately after reaching MCP menu with Ctrl+C
send "\003"
expect eof
wait
EXPECT_EOF
    if [ $? -eq 0 ]; then
        echo "  ✓ Claude Code environment configured with MCP services"
    else
        echo "  ⚠ Warning: Claude Code setup may have been incomplete"
    fi

    # Install glm-plan-usage plugin via Plugin Marketplace
    echo ""
    echo "  Installing glm-plan-usage plugin..."
    expect << 'PLUGIN_EOF'
set timeout 60

spawn npx --yes @z_ai/coding-helper enter claude-code

# Wait for main menu
expect {
    "Apply Configuration" {}
    "Configuration Refresh" {}
}
# Navigate to Plugin Marketplace (2 down arrows)
send "\033\[B"
send "\033\[B"
send "\r"

# Wait for Plugin Marketplace menu
expect "Plugin Marketplace"
# Select the first plugin (glm-plan-usage) and install
send "\r"

# Wait for installation to complete or plugin details
expect {
    "Installation" { send "\r" }
    "glm-plan-usage" { send "\r" }
    timeout { }
}

# Exit with Ctrl+C
send "\003"
expect eof
wait
PLUGIN_EOF
    if [ $? -eq 0 ]; then
        echo "  ✓ glm-plan-usage plugin installed"
    else
        echo "  ⚠ Warning: Plugin installation may have been incomplete"
    fi
fi
echo ""

echo ""
echo "=========================================="
echo "Setup complete!"
echo "=========================================="
echo ""
echo "Python 3.14 is now the default in the active venv."
echo "Claude Code environment variables configured."
echo ""
echo "MCP Servers configured via environment variables:"
if [ -n "$GITHUB_PERSONAL_ACCESS_TOKEN" ]; then
    echo "  ✓ GitHub MCP Server"
else
    echo "  ○ GitHub MCP Server (set GITHUB_PERSONAL_ACCESS_TOKEN in .env)"
fi

echo ""
echo "------------------------------------------"
echo "Step 6: Modifying Claude Code settings..."
echo "------------------------------------------"

# Configure .vscode/settings.json for VSCode plugin
VSCODE_SETTINGS="/workspaces/hackathon/.vscode/settings.json"
VSCODE_DIR="/workspaces/hackathon/.vscode"

if [ ! -f "$VSCODE_SETTINGS" ]; then
    echo "  Creating .vscode/settings.json for VSCode plugin..."
    mkdir -p "$VSCODE_DIR"
    cat > "$VSCODE_SETTINGS" << 'EOF'
{
  "claudeCode.environmentVariables": [
    {
      "name": "ANTHROPIC_BASE_URL",
      "value": "https://api.z.ai/api/anthropic"
    }
  ],
  "claudeCode.disableLoginPrompt": true
}
EOF
    echo "  ✓ .vscode/settings.json created"
else
    # Check if claudeCode.environmentVariables already exists
    if ! grep -q "claudeCode.environmentVariables" "$VSCODE_SETTINGS" 2>/dev/null; then
        echo "  Adding claudeCode.environmentVariables to existing .vscode/settings.json..."
        if command -v jq &> /dev/null; then
            tmp_file=$(mktemp)
            jq '. + {
                "claudeCode.environmentVariables": [
                    {
                        "name": "ANTHROPIC_BASE_URL",
                        "value": "https://api.z.ai/api/anthropic"
                    }
                ],
                "claudeCode.disableLoginPrompt": true
            }' "$VSCODE_SETTINGS" > "$tmp_file" && mv "$tmp_file" "$VSCODE_SETTINGS"
            echo "  ✓ claudeCode.environmentVariables added via jq"
        else
            # Fallback: use Python to modify the JSON
            python3 << PYTHON_EOF
import json
settings_path = "$VSCODE_SETTINGS"
try:
    with open(settings_path, 'r') as f:
        data = json.load(f)
    data['claudeCode.environmentVariables'] = [
        {
            "name": "ANTHROPIC_BASE_URL",
            "value": "https://api.z.ai/api/anthropic"
        }
    ]
    data['claudeCode.disableLoginPrompt'] = True
    with open(settings_path, 'w') as f:
        json.dump(data, f, indent=2)
    print("  ✓ claudeCode.environmentVariables added via Python")
except Exception as e:
    print(f"  ⚠ Failed to update settings.json: {e}")
PYTHON_EOF
        fi
    else
        echo "  ✓ claudeCode.environmentVariables already configured in .vscode/settings.json"
    fi
fi

# Create ~/.claude/config.json for VSCode plugin
if [ -n "$ANTHROPIC_API_KEY" ]; then
    echo "  Configuring Claude Code VSCode plugin API key..."
    mkdir -p "$HOME/.claude"
    echo "{\"primaryApiKey\": \"$ANTHROPIC_API_KEY\"}" > "$HOME/.claude/config.json"
    echo "  ✓ VSCode plugin config.json created with API key"
else
    echo "  ⚠ ANTHROPIC_API_KEY not set, skipping VSCode plugin API key configuration"
fi

# Replace ANTHROPIC_AUTH_TOKEN with ANTHROPIC_API_KEY in Claude settings
if [ -f "$HOME/.claude/settings.json" ]; then
    if grep -q "ANTHROPIC_AUTH_TOKEN" "$HOME/.claude/settings.json"; then
        echo "  Replacing ANTHROPIC_AUTH_TOKEN with ANTHROPIC_API_KEY in settings.json..."
        sed -i'.bak' 's/"ANTHROPIC_AUTH_TOKEN"/"ANTHROPIC_API_KEY"/g' "$HOME/.claude/settings.json"
        echo "  ✓ Settings updated (backup saved as settings.json.bak)"
    else
        echo "  ✓ ANTHROPIC_API_KEY already configured in settings.json"
    fi

    # Add GLM coding plan model configuration if not already present
    if ! grep -q "ANTHROPIC_DEFAULT_HAIKU_MODEL" "$HOME/.claude/settings.json"; then
        echo "  Adding GLM coding plan model configuration..."
        # Use jq to add the env variables, or fall back to Python if jq is not available
        if command -v jq &> /dev/null; then
            jq --arg haiku "glm-4.7-air" \
               --arg sonnet "glm-5" \
               --arg opus "glm-5" \
               '.env += {
                   "ANTHROPIC_DEFAULT_HAIKU_MODEL": $haiku,
                   "ANTHROPIC_DEFAULT_SONNET_MODEL": $sonnet,
                   "ANTHROPIC_DEFAULT_OPUS_MODEL": $opus
               }' "$HOME/.claude/settings.json" > "$HOME/.claude/settings.json.tmp" && \
               mv "$HOME/.claude/settings.json.tmp" "$HOME/.claude/settings.json"
            echo "  ✓ GLM coding plan models configured via jq"
        else
            # Fallback: use Python to modify the JSON
            python3 << 'PYTHON_EOF'
import json
settings_path = "$HOME/.claude/settings.json"
try:
    with open(settings_path, 'r') as f:
        data = json.load(f)
    if 'env' not in data:
        data['env'] = {}
    data['env']['ANTHROPIC_DEFAULT_HAIKU_MODEL'] = 'glm-4.7-air'
    data['env']['ANTHROPIC_DEFAULT_SONNET_MODEL'] = 'glm-5'
    data['env']['ANTHROPIC_DEFAULT_OPUS_MODEL'] = 'glm-5'
    with open(settings_path, 'w') as f:
        json.dump(data, f, indent=2)
    print("  ✓ GLM coding plan models configured via Python")
except Exception as e:
    print(f"  ⚠ Failed to configure GLM models: {e}")
PYTHON_EOF
        fi
    else
        echo "  ✓ GLM coding plan models already configured"
    fi
else
    echo "  ⚠ Claude Code settings.json not found, skipping"
fi


