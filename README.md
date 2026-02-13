# Development Environment Setup

This project is configured for VS Code Dev Containers. Follow the steps below to prepare your host machine and understand what the container provides.

## Host Prerequisites (Win/Mac/Linux)
- Install Docker (Docker Desktop on Windows/Mac; Docker Engine on Linux).
- Enable virtualization in BIOS/firmware (VT-x/AMD-V) if not already on.
- Install VS Code and the **Dev Containers** extension.
- Windows:
  - Use WSL2 with a recent Ubuntu distro (recommended) and ensure Docker Desktop is set to use WSL2 backends.
  - Confirm `wsl --status` reports WSL version 2.
- macOS:
  - Ensure Docker Desktop is running; give it adequate CPU/RAM in settings if builds are slow.
- Linux:
  - Add your user to the `docker` group (`sudo usermod -aG docker $USER` then re-login), or use rootless Docker.

## How to Open the Dev Container
1. Clone the repo locally.
2. Open the folder in VS Code.
3. When prompted, select **Reopen in Container** (or run **Dev Containers: Reopen in Container** from the command palette).
4. The container build will run the `postCreateCommand` defined in `.devcontainer/devcontainer.json`, which calls `.devcontainer/setup.sh`.

## What the Container Sets Up
- **Python**: Installed via `uv` (Python 3.14), with a virtual environment at `$HOME/.python_env` auto-activated in shells.
- **Python packages**: `flask`, `streamlit`, `numpy`, `pandas`, `requests`, `python-dotenv`, `pytest` (installed into the venv via `uv pip`).
- **Automation tools**: `expect` for scripting interactive CLI steps.
- **Claude Code / Coding Helper**: Automated setup via `npx @z_ai/coding-helper enter claude-code`, including MCP service installation when possible.
- **Environment loading**: `.devcontainer/.env` (if present) is sourced during setup and also wired into your shell via `$HOME/.bashrc.claude-code`.

## Environment Variables
Create `.devcontainer/.env` (not committed) with values like:
```
ANTHROPIC_API_KEY="your-key"
GITHUB_PERSONAL_ACCESS_TOKEN="your-token"
ANTHROPIC_BASE_URL="https://api.anthropic.com"  # optional override
```
These are exported for MCP servers and the Coding Helper automation.

## Rerunning Setup
If you need to rerun the provisioning inside the container:
```
bash .devcontainer/setup.sh
```
The script is idempotent: it recreates the venv (`uv venv --clear`), reinstalls the listed Python packages, and re-attempts the Coding Helper automation (skipping interactive parts if prerequisites are missing).

## Useful Notes
- The venv is at `$HOME/.python_env`; it is auto-activated via `.bashrc`.
- If the Coding Helper menu changes, you may need to adjust the `expect` block in `.devcontainer/setup.sh`.
- Docker resources: for large installs, increase Docker memory/CPU in Docker Desktop (Mac/Win) or tune the daemon config on Linux.
