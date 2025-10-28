# ubuntu-bootstrap — Quick Start (Ubuntu 24.04, ThinkPad T14s Gen2)

## One-liners

```bash
# Base packages + verification (idempotent)
make run

# Verification only (fstrim, SMART, sensors, fstrim.timer snapshot)
make verify

# Base package step only
make base

# Tag + GitHub release (requires 'gh auth login' once)
make release TAG=v0.1.0
