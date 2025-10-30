#!/usr/bin/env bash
# HP Laptop 15 series optimizations (Ubuntu 24.04)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

ensure_module_load() {
  local mod="$1"
  if lsmod | grep -q "^${mod}\\b"; then
    log "Kernel module ${mod} already loaded"
  else
    if ! run $(need_sudo) modprobe "$mod"; then
      log "WARNING: could not load ${mod} (module may not be available on this hardware)"
      return 1
    fi
  fi
  local conf="/etc/modules-load.d/${mod}.conf"
  if [[ ! -f "$conf" ]]; then
    if echo "$mod" | $(need_sudo) tee "$conf" >/dev/null; then
      log "Ensured ${mod} persists across reboots"
    else
      log "WARNING: Could not create persistent module config for ${mod}"
    fi
  fi
}

main() {
  log "=== HP Laptop 15 Optimizations ==="

  # Power management with thresholds when supported
  log "Installing TLP with battery conservation (20-80%)…"
  install_tlp 20 80

  # HP WMI provides hotkeys/thermal controls on many HP laptops
  ensure_module_load hp_wmi || true

  # Fingerprint support if present
  install_fingerprint_support

  # GNOME touchpad convenience (tap-to-click) if GNOME is present
  if command_exists gsettings && [[ -n "${DISPLAY:-}" ]]; then
    gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true 2>/dev/null || true
    log "Enabled tap-to-click (GNOME)"
  fi

  # Sensors verification
  verify_sensors || true

  log "=== HP Laptop 15 Optimizations Complete ==="
}

main "$@"
