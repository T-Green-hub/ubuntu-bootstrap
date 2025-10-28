# Hardware profiles

This repo auto-detects hardware and applies a matching profile:

- thinkpad-t14 — ThinkPad T14/T14s Gen 2 specifics (TLP thresholds, TrackPoint tuning, optional thinkfan, fingerprint when present)
- hp-laptop-15 — HP Laptop 15 specifics (hp_wmi, tap-to-click on GNOME, fingerprint when present)
- generic — Safe defaults for any laptop (TLP with thresholds if supported, acpid)

Override detection:

```bash
# Force a profile
HARDWARE_PROFILE=thinkpad-t14 bash scripts/50_laptop.sh
```

Dry-run (no changes):

```bash
DRY_RUN=1 bash scripts/50_laptop.sh
```
