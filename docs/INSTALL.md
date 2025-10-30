# Installation Guide

This guide walks you through a safe, step‑by‑step installation on Ubuntu 24.04.

If you only need quick commands, see the Quick Start: [QUICK_START.md](QUICK_START.md).

## 1) Prerequisites

- Ubuntu 24.04 (Noble)
- Internet access
- A user with sudo privileges
- Recommended packages: git, curl, make

Install prerequisites:

```bash
sudo apt update && sudo apt install -y git curl make
```

## 2) Get the code

```bash
git clone https://github.com/T-Green-hub/ubuntu-bootstrap.git
cd ubuntu-bootstrap
```

## 3) Optional: Dry run preview

Preview everything without making changes:

```bash
DRY_RUN=1 bash scripts/run_bootstrap.sh
```

## 4) Run the bootstrap

Using make (recommended):

```bash
make run
```

Or directly with bash:

```bash
bash scripts/run_bootstrap.sh
```

This will:

- Install base packages and drivers (idempotent)
- Apply your hardware profile optimizations
- Verify the system (TRIM, sensors, timers)

## 5) Optional: Install developer tools

Install all dev tools at once:

```bash
scripts/40_dev-tools.sh
```

Or select specific tools:

```bash
scripts/40_dev-tools.sh docker nodejs python rust go vscode utilities
```

After installation, apply these session updates:

- Docker: log out/in to use without sudo
- Node.js: `source ~/.nvm/nvm.sh`
- pyenv: `source ~/.bashrc`
- Rust: `source ~/.cargo/env`
- Go: `source ~/.bashrc`

## 6) Hardware profiles (optional override)

Auto-detection picks a matching profile. To force one:

```bash
HARDWARE_PROFILE=thinkpad-t14 bash scripts/run_bootstrap.sh
```

Valid values: `thinkpad-t14`, `hp-laptop-15`, `generic`.

## 7) Logs

Logs are saved under `logs/<timestamp>/`. Override with:

```bash
LOG_DIR=/tmp/bootstrap-logs make run
```

## 8) Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common fixes:

- apt locks or background services
- Docker group membership
- nvm, pyenv, Go, Rust PATH issues
- Network timeouts and retries

## 9) Uninstall / rollback

Each dev tool module provides an `uninstall_<tool>` function stub. Full rollback support is planned; for now, see module files under `scripts/dev-modules/` for guidance.

## 10) Safety & guarantees

- Scripts are idempotent (safe to re-run)
- Network operations use retries and timeouts
- Destructive operations validate target paths
- Dry run mode lets you preview before applying

## 11) Next steps

- Run `make verify` to re-run verification
- Review hardware profile docs: [HARDWARE_PROFILES.md](HARDWARE_PROFILES.md)
- Open issues/PRs on GitHub with feedback
