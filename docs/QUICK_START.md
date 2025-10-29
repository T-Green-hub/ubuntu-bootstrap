# ubuntu-bootstrap — Quick Start

Complete idempotent bootstrap for Ubuntu 24.04 on laptops with hardware-specific optimization profiles.

## One-liners

```bash
# Full bootstrap (all scripts + verification)
make run

# Dry-run mode (preview actions, no changes)
DRY_RUN=1 make run

# Skip a specific script (e.g., dev-tools)
scripts/run_bootstrap.sh --skip-script=40

# Verification only (fstrim, SMART, sensors, timers)
make verify

# Lint all scripts (requires shellcheck installed)
make lint

# Tag + GitHub release (requires 'gh auth login')
make release TAG=v0.2.0
```

## Hardware profiles

The runner auto-detects your laptop and applies optimizations:

- **thinkpad-t14**: ThinkPad T14/T14s (TLP, TrackPoint tuning, fingerprint support, thinkfan)
- **hp-laptop-15**: HP Laptop 15 (TLP, hp_wmi module, tap-to-click)
- **generic**: Safe fallback for any laptop (TLP with auto-detect thresholds, acpid)

Override detection:
```bash
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
