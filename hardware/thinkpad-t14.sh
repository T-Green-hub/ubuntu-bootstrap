#!/usr/bin/env bash
# ThinkPad T14/T14s Gen 2 hardware optimizations for Ubuntu 24.04
# Supports both AMD and Intel variants, with Tiger Lake specific optimizations
# Uses common helpers for safe apt and idempotent configuration.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Detect specific model details
detect_model_specifics() {
  local product_name="$($(need_sudo) dmidecode -s system-product-name 2>/dev/null || echo 'Unknown')"
  local cpu_model="$(grep -m1 'model name' /proc/cpuinfo | sed 's/.*: //' || echo 'Unknown')"
  
  log "Detected: $product_name"
  log "CPU: $cpu_model"
  
  # Check for Tiger Lake (11th gen Intel)
  if echo "$cpu_model" | grep -qE '11th Gen|i[357]-11[0-9]{2}'; then
    log "Tiger Lake CPU detected (11th gen Intel)"
    export TIGER_LAKE=1
  else
    export TIGER_LAKE=0
  fi
  
  # Check kernel version (Tiger Lake needs 5.11+)
  local kernel_ver="$(uname -r | cut -d. -f1,2)"
  local kernel_major="$(echo "$kernel_ver" | cut -d. -f1)"
  local kernel_minor="$(echo "$kernel_ver" | cut -d. -f2)"
  
  if (( kernel_major < 5 || (kernel_major == 5 && kernel_minor < 11) )); then
    log "WARNING: Kernel $kernel_ver may have issues with Tiger Lake hardware"
    log "         Recommend kernel 5.14+ for best results"
  else
    log "Kernel $kernel_ver: OK for Tiger Lake hardware"
  fi
}

main() {
  log "=== ThinkPad T14/T14s Gen 2 Hardware Optimizations ==="
  
  # Detect model specifics first
  detect_model_specifics

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

  # 5) Tiger Lake graphics optimization (Iris Xe)
  if (( TIGER_LAKE == 1 )); then
    log "Step 4: Optimizing Tiger Lake Iris Xe graphics…"
    
    # Iris Xe needs newer media drivers
    if ! is_installed intel-media-va-driver-non-free; then
      log "Installing Intel media drivers for Iris Xe…"
      apt_safe install -y intel-media-va-driver-non-free || log "WARNING: Intel media driver install failed"
    else
      log "Intel media drivers already installed"
    fi
    
    # Check if Wayland is default (better for Iris Xe)
    if [[ -n "${XDG_SESSION_TYPE:-}" ]]; then
      if [[ "${XDG_SESSION_TYPE}" == "wayland" ]]; then
        log "Wayland session detected (optimal for Iris Xe)"
      else
        log "INFO: X11 session detected. Wayland recommended for Iris Xe graphics."
      fi
    fi
  fi
  
  # 6) Fingerprint (if present)
  log "Step 5: Checking fingerprint support…"
  install_fingerprint_support

  # 7) WiFi 6 AX201 optimization (common on Gen 2)
  if lspci | grep -qi 'Intel.*AX201'; then
    log "Step 6: Optimizing WiFi 6 AX201…"
    
    # Check if power saving is causing issues
    local wifi_conf="/etc/modprobe.d/iwlwifi-ax201.conf"
    if [[ ! -f "$wifi_conf" ]]; then
      log "Configuring AX201 for stability (disabling aggressive power save)…"
      $(need_sudo) tee "$wifi_conf" >/dev/null <<'EOF'
# Intel AX201 WiFi 6 optimization
# Disable aggressive power management for better stability
options iwlwifi power_save=0
options iwlwifi uapsd_disable=1
EOF
      log "AX201 optimized. Reboot needed to apply."
    else
      log "AX201 config already exists"
    fi
  fi
  
  # 8) Optional fan control utility (manual config)
  log "Step 7: Installing thinkfan (optional)…"
  if is_installed thinkfan; then
    log "thinkfan already installed"
  else
    apt_safe install -y thinkfan || log "WARNING: thinkfan install failed; continuing."
    log "Note: configure /etc/thinkfan.conf if you intend to use fan curves."
  fi

  # 9) Fn keys info
  log "Step 8: Checking Fn key mode (if exposed by kernel)…"
  FNLOCK="/sys/module/hid_lenovo/parameters/fnlock"
  if [[ -f "$FNLOCK" ]]; then
    log "Fn-Lock mode: $(cat "$FNLOCK") (0=F-keys default, 1=special functions default)"
  else
    log "Fn-Lock control not exposed; use BIOS to configure."
  fi

  # 10) Verify
  log "Step 9: Verifying…"
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
