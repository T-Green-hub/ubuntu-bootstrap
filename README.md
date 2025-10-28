# ubuntu-bootstrap

[![verify](https://github.com/T-Green-hub/ubuntu-bootstrap/actions/workflows/verify.yml/badge.svg)](https://github.com/T-Green-hub/ubuntu-bootstrap/actions/workflows/verify.yml)

Minimal, **idempotent** post-install bootstrap for **Ubuntu 24.04 (Noble)** on ThinkPad T14 Gen 2–style laptops.  
Safe defaults, user-space where possible, and quick verification.

## Quick Start

See **[docs/QUICK_START.md](docs/QUICK_START.md)** for step-by-step usage.

## Hardware profiles

- Auto-detects common laptops via `scripts/50_laptop.sh` and applies a matching profile under `hardware/`.
- Profiles available: `thinkpad-t14`, `hp-laptop-15`, and a safe `generic` fallback.
- Override detection by setting `HARDWARE_PROFILE` (e.g., `HARDWARE_PROFILE=thinkpad-t14`).

## Dry run mode

- Set `DRY_RUN=1` to preview actions without making changes. APT and systemd operations are logged but skipped where supported.
- Examples:
  - `DRY_RUN=1 bash scripts/50_laptop.sh`
  - `DRY_RUN=1 make run`

## Make targets

```bash
make run      # install base packages + verify
make base     # base packages only
make verify   # verification only
make release TAG=v0.1.0   # create a tag + GitHub release (requires gh auth)
```
