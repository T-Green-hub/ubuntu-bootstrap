# ubuntu-bootstrap

[![verify](https://github.com/T-Green-hub/ubuntu-bootstrap/actions/workflows/verify.yml/badge.svg)](https://github.com/T-Green-hub/ubuntu-bootstrap/actions/workflows/verify.yml)

Minimal, **idempotent** post-install bootstrap for **Ubuntu 24.04 (Noble)** on ThinkPad T14 Gen 2–style laptops.  
Safe defaults, user-space where possible, and quick verification.

## Quick Start
See **[docs/QUICK_START.md](docs/QUICK_START.md)** for step-by-step usage.

## Make targets
```bash
make run      # install base packages + verify
make base     # base packages only
make verify   # verification only
make release TAG=v0.1.0   # create a tag + GitHub release (requires gh auth)
