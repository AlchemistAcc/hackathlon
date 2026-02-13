# Welcome to the Alchemist AI Hackathon!

Grab your caffeine, put on your thinking cap, and prepare to have your mind mildly-to-moderately blown by the power of AI-assisted development. This repo is your portal to a pre-configured, ready-to-code environment designed to let you focus on *building* instead of *configuring for 47 hours straight*.

## What This Actually Is

A VS Code Dev Container that comes pre-loaded with:
- **Python 3.14** via `uv` (faster than your average snake)
- **AI Tools**: Claude Code, MCP servers, and Codex — your digital assistants
- **Playwright** for browser automation (go forth and automate the web)
- **TypeScript** for all your type-safe adventures
- **A cozy little home** where everything just works™

---

## Phase 1: The Host Prerequisites (Do This First)

Before you can enter the container dimension, your host machine needs some things. Don't worry, we believe in you.

### For Everyone (Git Required!)
```bash
# You need git. Check if you have it:
git --version

# If not, go to git-scm.com and install it.
# We'll wait.
```

Then clone this repo:
```bash
git clone https://github.com/AlchemistAcc/hackathon.git
cd hackathon
```

### Windows Warriors
1. **Install Docker Desktop** from [docker.com](https://www.docker.com/products/docker-desktop/)
2. **Install WSL2** with a recent Ubuntu distro (highly recommended)
   - Open PowerShell as Admin: `wsl --install`
   - Confirm with `wsl --status` — it should say WSL version 2
3. **Tell Docker Desktop to use WSL2** in Settings → Resources → WSL Integration
4. **Install VS Code** from [code.visualstudio.com](https://code.visualstudio.com/)
5. **Install the Dev Containers extension** in VS Code

### macOS Mavericks
1. **Install Docker Desktop for Mac** from [docker.com](https://www.docker.com/products/docker-desktop/)
2. **Install VS Code** from [code.visualstudio.com](https://code.visualstudio.com/)
3. **Install the Dev Containers extension** in VS Code
4. **Pro tip**: Crank up the RAM/CPU in Docker Desktop settings if builds feel sluggish

### Linux Legends
```bash
# Install Docker Engine (not Desktop, unless you want it)
# Follow: https://docs.docker.com/engine/install/

# Add yourself to the docker group (so you don't need sudo everywhere)
sudo usermod -aG docker $USER
# Log out and back in for this to take effect

# Install VS Code
# Follow: https://code.visualstudio.com/

# Install the Dev Containers extension
```

---

## Phase 2: The Environment Variables (Secrets, Secrets!)

Before building the container, you need to set up your API keys. This is where the magic happens.

### Step 1: Copy the Example File
```bash
# From the repo root:
cp .devcontainer/.env.example .devcontainer/.env
```

### Step 2: Edit `.devcontainer/.env` with Your Keys

Open `.devcontainer/.env` in your editor and fill in the relevant values:

```bash
# ============================================================================
# MCP Server API Keys
# ============================================================================

# GitHub MCP Server (for repo reading, PR operations, etc.)
# Get from: https://github.com/settings/tokens
# You'll need `repo` scope for most operations
GITHUB_PERSONAL_ACCESS_TOKEN=your_actual_token_here

# ============================================================================
# Claude Code API Configuration
# ============================================================================

# Anthropic API Key — Required for GLM Coding Plan
# Get from: https://console.anthropic.com/
# The setup script will run: npx @z_ai/coding-helper auth glm_coding_plan_global
ANTHROPIC_API_KEY=your_actual_key_here

# Custom API Endpoint (only if you use a proxy/service)
# ANTHROPIC_BASE_URL=https://api.example.com
```

### Step 3: To GLM or Not to GLM?

**Option A: Use the GLM Coding Plan**
- Fill in `ANTHROPIC_API_KEY` with your actual key
- The setup script will auto-configure everything for you
- Faster, more magical experience

**Option B: Use Default Claude Config**
- Leave `ANTHROPIC_API_KEY` empty (`ANTHROPIC_API_KEY=`)
- You'll authenticate via the official Claude Code process inside the container
- Slightly more manual, but totally valid

> **Security Note**: `.devcontainer/.env` is `.gitignore`d, so your secrets stay secret. Don't commit it!

---

## Phase 3: Enter the Container

1. Open VS Code
2. Open the cloned `hackathon` folder
3. When VS Code pops up a notification asking **"Reopen in Container?"** — click that button!
   - Or press `F1` → type "Dev Containers: Reopen in Container"
4. Wait for the magic to happen (first build takes a few minutes — grab a snack)

The `postCreateCommand` will automatically run `.devcontainer/setup.sh`, which:
- Creates a Python 3.14 venv at `$HOME/.python_env`
- Installs: `flask`, `streamlit`, `numpy`, `pandas`, `requests`, `python-dotenv`, `pytest`
- Sets up Claude Code with MCP servers
- Wires up your environment variables
- Activates everything in your shell

---

## Phase 4: Verify All Is Well

Once inside the container, open a terminal and check:

```bash
# Check Python (should be 3.14)
python --version

# Check that the venv is active (you'll see (.python_env) in your prompt)
which python

# Check that Claude Code is available
npx @z_ai/coding-helper --version

# Check that your env variables are loaded
echo $GITHUB_PERSONAL_ACCESS_TOKEN  # Should show your token (or empty if you set it that way)
echo $ANTHROPIC_API_KEY             # Should show your key (or empty)
```

---

## Need to Rerun Setup?

If something went sideways or you want to redo the automation:

```bash
bash .devcontainer/setup.sh
```

The script is idempotent — it won't break if you run it multiple times.

---

## What's In The Box?

| Tool | Version | Purpose |
|------|---------|---------|
| Python | 3.14 | All your AI scripting needs |
| uv | latest | Blazing fast Python package manager |
| Node.js | LTS | For Claude Code & MCP servers |
| TypeScript | latest | Type-safe JavaScript adventures |
| Playwright | latest | Browser automation & testing |
| Claude Code | latest | Your AI coding companion |
| Codex | latest | Alternative AI assistant |

---

## Troubleshooting (When Things Go Wrong™)

**"Docker won't start!"**
- Make sure virtualization is enabled in BIOS (VT-x/AMD-V)
- Restart Docker Desktop completely

**"Container build fails!"**
- Check Docker has enough RAM (4GB+ recommended)
- Check you're not running out of disk space

**"Claude Code can't authenticate!"**
- Make sure `.devcontainer/.env` exists and has valid keys
- Try re-running `bash .devcontainer/setup.sh`

**"Python commands don't work!"**
- Make sure you're in a fresh terminal inside the container
- The venv should auto-activate — look for `(.python_env)` in your prompt

---

## Go Forth and Hack!

You're now ready to join the hackathon. Remember:
- **Goal**: Learn, experiment, have fun
- **Not Goal**: Ship perfect production code
- **Success Metric**: Did you try something new? Yes? Win. 🏆

See you at the demos!

---

*Questions? Ping Annika or find one of the helpers floating around during the event.*
