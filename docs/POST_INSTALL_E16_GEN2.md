# Post-Install Guide — ThinkPad E16 Gen2 (Ubuntu LTS)

Evidence-driven follow-up steps after running the bootstrap. Safe, read-only checks first; apply changes only when intentional.

## Quick Health Check

Run the health checker in doctor mode for comprehensive diagnostics:

```bash
bash scripts/checks/bootstrap_check.sh --doctor --output-dir ~/health-checks
```

This performs extended read-only checks and prints fix commands for any issues detected.

## Firmware and LVFS
- Verify fwupd is present and the LVFS remote is enabled.
- List devices (read-only):
  ```bash
  fwupdmgr get-devices
  ```
- Check for updates (may require sudo):
  ```bash
  sudo fwupdmgr refresh --force
  sudo fwupdmgr get-updates
  ```
- Why: LVFS is the upstream distribution channel for firmware used by fwupd (see https://fwupd.org/).

## Unattended-Upgrades
- Confirm the service is active:
  ```bash
  systemctl status unattended-upgrades
  ```
- Review recent activity (log location from the man page):
  ```bash
  ls -1 /var/log/unattended-upgrades/
  sudo tail -n 50 /var/log/unattended-upgrades/unattended-upgrades.log
  ```
- Inspect config (read-only):
  ```bash
  grep -E "^(Unattended-Upgrade::|APT::Periodic::)" /etc/apt/apt.conf.d/50unattended-upgrades /etc/apt/apt.conf.d/20auto-upgrades
  ```
- Reference: man unattended-upgrades documents logs under /var/log/unattended-upgrades/.

## UFW Firewall Posture
- Check status and defaults (Ubuntu UFW defaults deny incoming, allow outgoing per Ubuntu community docs):
  ```bash
  sudo ufw status verbose
  sudo ufw show raw | head -20
  ```
- Expect `Default: deny (incoming), allow (outgoing)` when enabled. If inactive, enable intentionally: `sudo ufw enable`.
- Reference: https://help.ubuntu.com/community/UFW notes the default deny inbound/allow outbound stance.

## Power Profiles
- Confirm power-profiles-daemon is available and see current profile:
  ```bash
  powerprofilesctl list
  powerprofilesctl get
  ```
- Switch profiles deliberately (balanced, performance, power-saver):
  ```bash
  powerprofilesctl set power-saver
  ```

## Battery Charge Thresholds (if supported)
- Detect support (kernel exposes sysfs entries like charge_control_end_threshold):
  ```bash
  ls /sys/class/power_supply/BAT*/charge_control_end_threshold
  ```
- If present, you can set a limit (example 80%) non-destructively and make persistent via systemd or rc.local:
  ```bash
  echo 80 | sudo tee /sys/class/power_supply/BAT*/charge_control_end_threshold
  ```
- Reference: Linux power supply class documentation describes `charge_control_end_threshold` under /sys/class/power_supply/.

## Secure Boot and TPM
- Check Secure Boot state:
  ```bash
  sudo mokutil --sb-state
  ```
- Check TPM presence (TPM 2.0 expected on modern ThinkPads):
  ```bash
  ls -1 /sys/class/tpm/
  ```

## Storage Health
- SMART is read-only but often requires sudo to query:
  ```bash
  sudo smartctl -H /dev/nvme0
  ```
- If smartmontools is missing, install intentionally: `sudo apt install smartmontools`.

## Journals and Errors
- Review high-priority boot messages:
  ```bash
  sudo journalctl -b --priority=3 --no-pager | head -50
  ```
- Investigate recurring errors before making changes.

## Networking
- Capture current network config for baseline:
  ```bash
  nmcli device status
  ip -4 addr show
  ```

## Evidence Capture
- Re-run the read-only checker and store outputs:
  ```bash
  bash scripts/checks/bootstrap_check.sh --output-dir "$HOME/bootstrap-checks"
  ```
- Attach JSON/text artifacts when filing issues.

## Troubleshooting Quick Wins
- Wi-Fi drops: confirm firmware is current (fwupdmgr) and check `dmesg | grep -i wifi`.
- Suspend/resume hiccups: look at `journalctl -b --priority=3` and firmware levels.
- High fan/thermals: verify power profile, update firmware, and inspect `sensors` output.
- Firewall confusion: `sudo ufw status verbose` to see effective rules.

Stay read-only first; make changes only when you understand the impact. Document what you change so you can revert if needed.
