#!/usr/bin/env bash
# ThinkPad T14/T14s Gen 2 hardware optimizations for Ubuntu 24.04
# Uses common helpers for safe apt and idempotent configuration.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

main() {
  log "=== ThinkPad T14/T14s Gen 2 Hardware Optimizations ==="

  # 1) Power management with battery thresholds
  log "Step 1: Installing TLP with battery conservation (20-80%)…"
  install_tlp 20 80

  # 2) ThinkPad kernel utilities (best-effort)
  log "Step 2: Installing ThinkPad kernel utilities (best-effort)…"
  for pkg in acpi-call-dkms tp-smapi-dkms; do
    if is_installed "$pkg"; then
      log "$pkg already installed"
    else
      log "Installing $pkg…"
      apt_safe install -y "$pkg" || log "WARNING: $pkg install failed; continuing."
    fi
  done

  # 3) TrackPoint tuning (udev rule; persistent)
  log "Step 3: Configuring TrackPoint sensitivity/speed…"
  TRACKPOINT_UDEV="/etc/udev/rules.d/10-trackpoint.rules"
  if [[ ! -f "$TRACKPOINT_UDEV" ]]; then
    $(need_sudo) tee "$TRACKPOINT_UDEV" >/dev/null <<'EOF'
# ThinkPad TrackPoint configuration
ACTION=="add", SUBSYSTEM=="input", ATTR{name}=="TPPS/2 IBM TrackPoint", \
  ATTR{device/sensitivity}="200", \
  ATTR{device/speed}="120"
EOF
    log "TrackPoint sensitivity=200, speed=120 configured (udev)"
  else
    log "TrackPoint udev rule already present"
  fi

  # Try to apply immediately if sysfs is writable
  TP_SENS_PATH=$(find /sys/devices/platform/i8042 -name sensitivity 2>/dev/null | head -n1 || true)
  if [[ -n "${TP_SENS_PATH:-}" ]]; then
    TP_DIR=$(dirname "$TP_SENS_PATH")
    echo 200 | $(need_sudo) tee "$TP_DIR/sensitivity" >/dev/null || true
    echo 120 | $(need_sudo) tee "$TP_DIR/speed" >/dev/null || true
    log "Applied TrackPoint settings immediately"
  fi

  # 4) GNOME convenience (middle-button paste)
  if command_exists gsettings && [[ -n "${DISPLAY:-}" ]]; then
    gsettings set org.gnome.desktop.interface enable-middle-mouse-button-paste true 2>/dev/null || true
    log "Enabled middle-button paste in GNOME"
  fi

  # 5) Fingerprint (if present)
  log "Step 4: Checking fingerprint support…"
  install_fingerprint_support

  # 6) Optional fan control utility (manual config)
  log "Step 5: Installing thinkfan (optional)…"
  if is_installed thinkfan; then
    log "thinkfan already installed"
  else
    apt_safe install -y thinkfan || log "WARNING: thinkfan install failed; continuing."
    log "Note: configure /etc/thinkfan.conf if you intend to use fan curves."
  fi

  # 7) Fn keys info
  log "Step 6: Checking Fn key mode (if exposed by kernel)…"
  FNLOCK="/sys/module/hid_lenovo/parameters/fnlock"
  if [[ -f "$FNLOCK" ]]; then
    log "Fn-Lock mode: $(cat "$FNLOCK") (0=F-keys default, 1=special functions default)"
  else
    log "Fn-Lock control not exposed; use BIOS to configure."
  fi

  # 8) Verify
  log "Step 7: Verifying…"
  if $(need_sudo) systemctl is-active --quiet tlp.service; then
    log "✓ TLP active"
  else
    log "✗ TLP not active"
  fi

  if [[ -f "/etc/tlp.d/01-battery-thresholds.conf" ]]; then
    log "✓ Battery thresholds configured"
  else
    log "ℹ Battery thresholds not configured (maybe unsupported)"
  fi

  verify_sensors

  log "=== ThinkPad T14/T14s Optimizations Complete ==="
  log "Reboot recommended to ensure all settings apply (udev, kernel modules)."
}

main "$@"
