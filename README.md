# Ubuntu Bootstrap

[![verify](https://github.com/T-Green-hub/ubuntu-bootstrap/actions/workflows/verify.yml/badge.svg)](https://github.com/T-Green-hub/ubuntu-bootstrap/actions/workflows/verify.yml)
[![ci](https://github.com/T-Green-hub/ubuntu-bootstrap/actions/workflows/ci.yml/badge.svg)](https://github.com/T-Green-hub/ubuntu-bootstrap/actions/workflows/ci.yml)

Set up Ubuntu 24.04 (Noble) for development and daily use with one command. Features:

- 🚀 **5-minute setup** - Everything you need, installed correctly
- 🔋 **Smart power management** - Better battery life on laptops
- 🛡️ **Privacy & security** - Hardened settings and firewall
- 🛠️ **Developer ready** - Docker, Python, Node.js, and more
- ✅ **Safe to run** - Preview changes, no surprises

## Getting Started

First, install prerequisites:

```bash
sudo apt update && sudo apt install -y git curl make
```

Then get the code and run:

```bash
git clone https://github.com/T-Green-hub/ubuntu-bootstrap.git
cd ubuntu-bootstrap
make run
```

## Documentation

- 📖 [Quick Start Guide](docs/QUICK_START.md) - Step by step instructions
- 📚 [Full Installation Guide](docs/INSTALL.md) - Detailed explanations
- 🔧 [Troubleshooting](docs/TROUBLESHOOTING.md) - Solutions to common issues
- 💻 [Hardware Profiles](docs/HARDWARE_PROFILES.md) - Laptop optimizations

## Key Features

### Base System Setup

- Essential system packages and tools
- Privacy-focused settings
- Firewall configuration (UFW)
- Laptop power optimization
- System maintenance automation

### Developer Tools (Optional)

- Docker with rootless mode
- Node.js (via nvm) with latest LTS
- Python (via pyenv) with build tools
- Rust (via rustup) with cargo
- Go with proper PATH setup
- VS Code with essential extensions
- Development utilities (jq, ripgrep, etc.)

### Safety Features

- Preview mode (`DRY_RUN=1`)
- Automatic apt-lock handling
- Network operation retries
- Per-script logging
- Full rollback stubs

## Quick Commands

```bash
# Full installation
make run

# Preview changes without installing
DRY_RUN=1 make run

# Skip developer tools
scripts/run_bootstrap.sh --skip-script=40

# Install specific dev tools
scripts/40_dev-tools.sh docker nodejs python

# Verify installation
make verify
```

## Need Help?

- Try running in preview mode first:

```bash
DRY_RUN=1 make run
```

- Check the [Troubleshooting Guide](docs/TROUBLESHOOTING.md)

- Open an issue on GitHub

## License

[MIT](LICENSE) © 2025 T-Green-hub

## Hardware profiles

- Auto-detects common laptops via `scripts/50_laptop.sh` and applies a matching profile under `hardware/`.
- Profiles available: `thinkpad-t14`, `hp-laptop-15`, and a safe `generic` fallback.
- Override detection by setting `HARDWARE_PROFILE` (e.g., `HARDWARE_PROFILE=thinkpad-t14`).

## Dry run mode

- Set `DRY_RUN=1` to preview actions without making changes. APT and systemd operations are logged but skipped where supported.
- Examples:
  - `DRY_RUN=1 bash scripts/50_laptop.sh`
  - `DRY_RUN=1 make run`

## Apt lock guard

`scripts/run_bootstrap.sh` temporarily stops background services that often hold apt/dpkg locks (PackageKit, unattended-upgrades, apt-daily timers) for the duration of the run, then restores them automatically. This reduces flakiness during larger installs (e.g., dev-tools). Set `STRICT=1` to fail on non-critical warnings instead of treating them as success.

## Logging

Per-script logs are saved under `logs/<timestamp>/` during a run. Override the location with `LOG_DIR=/path/to/logs`. In dry-run mode, the runner records what would have been executed.

## Make targets

```bash
make run      # install base packages + verify
make base     # base packages only
make verify   # verification only
make release TAG=v0.1.0   # create a tag + GitHub release (requires gh auth)
```

## No make? Use bash directly

```bash
git clone https://github.com/T-Green-hub/ubuntu-bootstrap.git
cd ubuntu-bootstrap
bash scripts/run_bootstrap.sh
```

## Selective dev tools install

You can install individual developer tools with our modular script:

```bash
# Install all dev tools
scripts/40_dev-tools.sh

# Or install specific tools only
scripts/40_dev-tools.sh docker nodejs python rust go vscode utilities
```

Notes after install:

- Docker: log out/in to use without sudo
- Node.js: `source ~/.nvm/nvm.sh`
- pyenv: `source ~/.bashrc`
- Rust: `source ~/.cargo/env`
- Go: `source ~/.bashrc`
