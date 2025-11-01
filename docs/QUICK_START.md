# Quick Start Guide

This guide helps you set up Ubuntu 24.04 with essential tools and optimizations, perfect for developers and daily users.

💡 **New to Ubuntu?** This is the right place to start. We'll walk you through everything step by step.

## Before You Begin

### Prerequisites

Make sure you have:

- ✅ Ubuntu 24.04 (Noble) desktop or server - **Required**
- ✅ Internet connection - **Required**
- ✅ A user account with sudo privileges - **Required**
- 💾 At least 5GB free disk space (more for dev tools)
- ⏱️ 5-15 minutes of time (depending on options)

### System Check

Verify your Ubuntu version:

```bash
lsb_release -a
# Should show: Ubuntu 24.04 LTS (Noble Numbat)
```

Check available disk space:

```bash
df -h /
# Should show at least 5GB available
```

### Install Prerequisites

First, open a terminal (Ctrl+Alt+T) and install some basic tools:

```bash
sudo apt update && sudo apt install -y git curl make
```

**💡 Tip**: You can copy commands by clicking the code block. Paste in terminal with Ctrl+Shift+V.

## Basic Installation (5 minutes)

1. First, get the code:

```bash
git clone https://github.com/T-Green-hub/ubuntu-bootstrap.git
cd ubuntu-bootstrap
```

1. Optional but recommended for beginners - preview what will be installed:

```bash
DRY_RUN=1 make run
```

1. Run the full installation:

```bash
make run
```

This installation will:

- Install essential packages
- Configure power management for your laptop
- Set up security and privacy features
- Install optional developer tools (Docker, Python, Node.js, etc.)
- Verify everything is working

Need to skip the developer tools? Run this instead:

```bash
scripts/run_bootstrap.sh --skip-script=40
```

Want to verify everything is healthy?

```bash
make verify
```

## Laptop Optimization

The bootstrap automatically detects your laptop model and applies the right optimizations:

### Supported Models

- **ThinkPad T14/T14s** - Perfect battery life, TrackPoint tuning, fingerprint unlock
- **HP Laptop 15** - Power savings, special keys, touchpad improvements
- **Any Other Laptop** - Safe, tested defaults that work everywhere

Don't worry if your exact model isn't listed! We'll use safe settings that work well on any laptop.

### Want to Pick Your Own Profile?

If the auto-detection picks the wrong profile, you can force a specific one:

```bash
# For ThinkPad laptops:
HARDWARE_PROFILE=thinkpad-t14 make run

# For HP Laptop 15 series:
HARDWARE_PROFILE=hp-laptop-15 make run

# For any other laptop:
HARDWARE_PROFILE=generic make run
```

## Logging

Per-script logs are saved to `logs/<timestamp>/` by default. Override with:

```bash
LOG_DIR=/tmp/bootstrap-logs make run
```

## Advanced options

- **Strict mode**: Fail on warnings instead of treating them as success

  ```bash
  STRICT=1 make run
  ```

- **Skip multiple scripts**: Use multiple `--skip-script` flags

  ```bash
  scripts/run_bootstrap.sh --skip-script=30 --skip-script=40
  ```

- **Help**: Show all runner options

  ```bash
  scripts/run_bootstrap.sh --help
  ```

## Developer Tools (Optional)

Want to set up a complete development environment? We offer popular programming tools and environments:

### Available Tools

- **Docker** - Run containers and microservices
- **Node.js** (via nvm) - JavaScript/TypeScript development
- **Python** (via pyenv) - Python programming with version management
- **Rust** (via rustup) - Systems programming with Rust
- **Go** - Google's Go language
- **VS Code** - Popular code editor with extensions
- **Dev Utilities** - Essential tools (jq, ripgrep, etc.)

### Installation Options

Install everything (recommended for full-stack developers):

```bash
scripts/40_dev-tools.sh
```

Or pick just what you need:

```bash
# Example: Install only Docker and Node.js
scripts/40_dev-tools.sh docker nodejs

# Example: Python and VS Code only
scripts/40_dev-tools.sh python vscode
```

### After Installation

To start using your new tools, you'll need to either:

1. Log out and log back in (best option)
1. Or run these commands in your current terminal:

```bash
# For Node.js:
source ~/.nvm/nvm.sh

# For Python/pyenv:
source ~/.bashrc

# For Rust:
source ~/.cargo/env

# For Go:
source ~/.bashrc
```

**Note**: For Docker, you must log out and back in to use it without sudo.

## Optional Features (ProtonVPN, Browser, etc.)

You can install privacy and productivity extras via the optional features orchestrator.

Install ProtonVPN only:

```bash
scripts/60_optional-features.sh protonvpn
```

Install multiple features (example: ProtonVPN + Brave + TimeShift):

```bash
scripts/60_optional-features.sh protonvpn brave timeshift
```

Preview without changes:

```bash
DRY_RUN=1 scripts/60_optional-features.sh protonvpn
```

Quick References:

- ProtonVPN quick guide: docs/PROTONVPN_QUICK_REF.md
- Full ProtonVPN doc: docs/PROTONVPN.md

## Post-Installation

### Recommended Next Steps

After installation completes successfully:

1. **Log out and log back in** - Required for Docker and group changes
2. **Verify installation** - Run `make verify` to check system health
3. **Review logs** - Check `logs/` directory for any warnings
4. **Create a system snapshot** - If you installed TimeShift, create your first backup

### Verification Commands

Check that everything is working:

```bash
# Verify Docker (after re-login)
docker --version
docker run hello-world

# Verify Node.js
source ~/.nvm/nvm.sh
node --version
npm --version

# Verify Python
source ~/.bashrc
pyenv versions

# Check system health
make verify
```

## Having Problems?

### Quick Fixes

- **Script fails?** Check logs in `logs/<timestamp>/`
- **Package conflicts?** Try `sudo apt --fix-broken install`
- **Need to retry?** Scripts are idempotent - safe to run again
- **Partial install?** Use `--skip-script=XX` to skip completed sections

### Get Help

- 📖 **Installation fails?** See our [Troubleshooting Guide](TROUBLESHOOTING.md)
- 📚 **Need all the details?** Check the [Full Installation Guide](INSTALL.md)
- 💻 **Hardware questions?** Read about [Hardware Profiles](HARDWARE_PROFILES.md)
- 🔍 **System detection?** See [System Detection Guide](SYSTEM_DETECTION.md)

**💡 Pro tip**: You can always run with `DRY_RUN=1` to safely preview any command before running it.

## Next Steps

- ✅ Review the [Post-Install Guide](POST_INSTALL.md) for optimization tips
- ✅ Configure your development environment
- ✅ Set up ProtonVPN if privacy is important to you
- ✅ Create a TimeShift snapshot for easy rollback
