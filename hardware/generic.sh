#!/usr/bin/env bash
# Generic laptop optimizations (safe, conservative defaults)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

main() {
  log "=== Generic Laptop Hardware Optimizations ==="

  # Power management (conservative). Thresholds only take effect if supported.
  log "Installing TLP with battery conservation (20-80%) if supported…"
  install_tlp 20 80

  # Ensure ACPI daemon present for button events on some laptops
  if is_installed acpid; then
    log "acpid already installed"
  else
    apt_safe update -qq || true
    apt_safe install -y acpid || log "WARNING: acpid install failed; continuing."
  fi

  # Enable middle-button paste on GNOME if present
  if command_exists gsettings && [[ -n "${DISPLAY:-}" ]]; then
    gsettings set org.gnome.desktop.interface enable-middle-mouse-button-paste true 2>/dev/null || true
    log "Enabled middle-button paste in GNOME"
  fi

  # Fingerprint support (only if a reader is detected)
  install_fingerprint_support

  # Sensors quick check
  verify_sensors || true

  log "=== Generic Optimizations Complete ==="
}

main "$@"
