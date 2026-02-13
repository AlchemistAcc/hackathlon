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
echo "Note: Some Claude Code plugins may need to be installed manually:"
echo "  Run: /plugin install glm-plan-usage@zai-coding-plugins"
echo ""
echo "MCP Servers configured via environment variables:"
if [ -n "$GITHUB_PERSONAL_ACCESS_TOKEN" ]; then
    echo "  ✓ GitHub MCP Server"
else
    echo "  ○ GitHub MCP Server (set GITHUB_PERSONAL_ACCESS_TOKEN in .env)"
fi

echo ""
echo "------------------------------------------"
echo "Step 6: Fixing Claude Code settings..."
echo "------------------------------------------"
# Replace ANTHROPIC_AUTH_TOKEN with ANTHROPIC_API_KEY in Claude settings
if [ -f "$HOME/.claude/settings.json" ]; then
    if grep -q "ANTHROPIC_AUTH_TOKEN" "$HOME/.claude/settings.json"; then
        echo "  Replacing ANTHROPIC_AUTH_TOKEN with ANTHROPIC_API_KEY in settings.json..."
        sed -i'.bak' 's/"ANTHROPIC_AUTH_TOKEN"/"ANTHROPIC_API_KEY"/g' "$HOME/.claude/settings.json"
        echo "  ✓ Settings updated (backup saved as settings.json.bak)"
    else
        echo "  ✓ ANTHROPIC_API_KEY already configured in settings.json"
    fi
else
    echo "  ⚠ Claude Code settings.json not found, skipping"
fi


