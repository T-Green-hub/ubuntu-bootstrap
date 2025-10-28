# Dry run mode

To preview actions without making changes, set `DRY_RUN=1`.
APT and systemd operations in supported scripts will be logged but skipped.

Examples:

```bash
# Preview the full bootstrap
DRY_RUN=1 make run

# Preview only hardware profile application
DRY_RUN=1 bash scripts/50_laptop.sh

# Force a specific hardware profile in dry run
DRY_RUN=1 HARDWARE_PROFILE=thinkpad-t14 bash scripts/50_laptop.sh
```
