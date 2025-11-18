# Ubuntu Bootstrap

[![verify](https://github.com/T-Green-hub/ubuntu-bootstrap/actions/workflows/verify.yml/badge.svg)](https://github.com/T-Green-hub/ubuntu-bootstrap/actions/workflows/verify.yml)
[![ci](https://github.com/T-Green-hub/ubuntu-bootstrap/actions/workflows/ci.yml/badge.svg)](https://github.com/T-Green-hub/ubuntu-bootstrap/actions/workflows/ci.yml)

Set up Ubuntu 24.04 (Noble) for development and daily use with one command. Features:

- 🚀 **5-minute setup** - Everything you need, installed correctly
- 🎯 **Interactive menu** - User-friendly guided installation
- 🔋 **Smart power management** - Better battery life on laptops  
- 💻 **Hardware-specific optimizations** - ThinkPad T14s Gen 2 & more
- 🛡️ **Privacy & security** - Hardened settings and firewall
- 🛠️ **Developer ready** - Docker, Python, Node.js, and more
- ✅ **Safe to run** - Preview changes, progress tracking, no surprises

## Getting Started

### 🌟 First Time User? Start Here!

**Copy, paste, and press Enter - that's it!**

```bash
sudo apt update && sudo apt install -y git make && \
git clone https://github.com/T-Green-hub/ubuntu-bootstrap.git && \
cd ubuntu-bootstrap && \
make run
```

☕ **Grab coffee! Installation takes 5-15 minutes.**

---

### Interactive Menu (Guided Setup)

Prefer a menu-driven experience?

```bash
# Install prerequisites
sudo apt update && sudo apt install -y git curl make

# Clone and run interactive menu
git clone https://github.com/T-Green-hub/ubuntu-bootstrap.git
cd ubuntu-bootstrap
bash scripts/interactive_menu.sh
```

**Perfect for beginners!** The interactive menu provides:
- 🎯 **Auto hardware detection** (knows your ThinkPad, HP, etc.)
- 📊 **Real-time progress** - See exactly what's happening
- 🔍 **System checks first** - Catches problems before starting
- 📚 **Built-in help** - Read guides without leaving the menu
- ⚙️ **Choose what to install** - Full setup or just basics
- 🎨 **Beautiful interface** - No confusing terminal output

**What it does:** Walks you through every step with clear explanations and lets you preview changes before applying them.

### Traditional Method

```bash
git clone https://github.com/T-Green-hub/ubuntu-bootstrap.git
cd ubuntu-bootstrap
make run
```

## Hardware Support

### ThinkPad T14s Gen 2 (11th Gen Intel Tiger Lake)

**Special optimizations included:**
- ✅ Intel Iris Xe graphics (hardware acceleration)
- ✅ WiFi 6 AX201 (stability & performance)
- ✅ Battery charge thresholds (20-80% for longevity)
- ✅ TrackPoint configuration
- ✅ Power management tuning
- ✅ Kernel 6.x compatibility

**Quick setup:**
```bash
cd ubuntu-bootstrap

# 1. Check system readiness
bash scripts/preflight_check.sh

# 2. Run bootstrap
make run

# 3. Apply T14s-specific fixes
bash scripts/fix_t14s_gen2.sh

# 4. Reboot
sudo reboot
```

📖 **See:** [ThinkPad T14s Gen 2 Complete Guide](docs/T14S_GEN2_QUICK_START.md)

### Other Laptops

- ThinkPad T14 (auto-detected)
- HP Laptop 15 (auto-detected)
- Generic laptop profile (fallback)

## Documentation

- 🎯 **[Interactive Menu](scripts/interactive_menu.sh)** - User-friendly guided setup ⭐ NEW
- 💻 **[ThinkPad T14s Gen 2 Guide](docs/T14S_GEN2_QUICK_START.md)** - Complete Tiger Lake setup ⭐ NEW
- 🔍 **[Pre-Flight Check](scripts/preflight_check.sh)** - System readiness verification ⭐ NEW
- 📖 [Quick Start Guide](docs/QUICK_START.md) - Step by step instructions
- 📚 [Full Installation Guide](docs/INSTALL.md) - Detailed explanations
- 🔧 [Troubleshooting](docs/TROUBLESHOOTING.md) - Solutions to common issues
- 🗑️ [Uninstall Guide](docs/UNINSTALL.md) - Safe removal of installed components
- 💻 [Hardware Profiles](docs/HARDWARE_PROFILES.md) - Laptop optimizations
- 🔍 [System Detection](docs/SYSTEM_DETECTION.md) - Hardware detection and compatibility
- ✅ [Post‑Install Guide](docs/POST_INSTALL.md) - Best order and practices after bootstrap

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

### Optional Features

Recommended order: install optional features after base/dev-tools for faster runs and fewer apt refreshes. Prefer privacy-first? Use the "privacy-first" target below.

- **ProtonVPN** - Official Linux app (daemon + GTK GUI). Note: the legacy community CLI is not included.
- **Brave Browser** - Privacy-focused browser with built-in ad blocking
- **TimeShift** - System snapshots and restore
- **VLC Media Player** - Feature-rich multimedia player with codec support
- **LibreOffice** - Full office suite (Writer, Calc, Impress, Draw, Base, Math)

### Safety Features

- Preview mode (`DRY_RUN=1`)
- Automatic apt-lock handling
- Network operation retries
- Per-script logging
- Full uninstall support for dev modules
- Automatic backups before uninstall

## Quick Commands

```bash
# Interactive menu (recommended for new users)
bash scripts/interactive_menu.sh

# Pre-flight check (verify system readiness)
bash scripts/preflight_check.sh

# Full installation
make run

# Preview changes without installing
DRY_RUN=1 make run

# Skip developer tools
scripts/run_bootstrap.sh --skip-script=40

# Install specific dev tools
scripts/40_dev-tools.sh docker nodejs python

# ThinkPad T14s Gen 2 specific fixes
bash scripts/fix_t14s_gen2.sh

# Install optional features (Brave, ProtonVPN, VLC, LibreOffice)
make optional                                    # Show available features
scripts/60_optional-features.sh brave protonvpn  # Install privacy tools
scripts/60_optional-features.sh vlc libreoffice  # Install desktop apps
scripts/60_optional-features.sh brave            # Install Brave only

# Privacy-first preset (optional): install privacy extras before dev tools
make privacy-first

# Hardware detection and compatibility check
make detect    # Show hardware info and recommendations
make check     # Check for deprecated packages

# Uninstall developer modules (safe with backups)
source scripts/dev-modules/python.sh && uninstall_python
source scripts/dev-modules/nodejs.sh && uninstall_nodejs
source scripts/dev-modules/rust.sh && uninstall_rust
# See docs/UNINSTALL.md for complete guide

# Verify installation
make verify
```

## Need Help?

- Try running in preview mode first:

```bash
DRY_RUN=1 make run
```

- Check the [Troubleshooting Guide](docs/TROUBLESHOOTING.md)

- Open an issue: https://github.com/T-Green-hub/ubuntu-bootstrap/issues

## License

[MIT](LICENSE) © 2025 T-Green-hub  
Repository: https://github.com/T-Green-hub/ubuntu-bootstrap

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
