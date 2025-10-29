#!/usr/bin/env bash
# Ubuntu 24.04 hardware drivers and firmware (idempotent).
# CPU microcode, WiFi, graphics, Bluetooth, and laptop-specific drivers.

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../hardware/common.sh"

# --- Package Definitions ---
readonly INTEL_GRAPHICS_PKGS=(
  mesa-vulkan-drivers
  libva-intel-driver
  intel-media-va-driver-non-free
  vulkan-tools
)
readonly WIRELESS_PKGS=(linux-firmware)
readonly BLUETOOTH_PKGS=(bluez bluez-tools)
readonly LAPTOP_PKGS=(acpid)

# --- Helper Functions ---

# Generic function to install a list of packages if they are not present.
# Usage: install_pkgs "Description" "${PKGS_ARRAY[@]}"
install_pkgs() {
  local description="$1"
  shift
  local pkgs_to_install=("$@")
  local to_install=()

  for pkg in "${pkgs_to_install[@]}"; do
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
      to_install+=("$pkg")
    fi
  done

  if ((${#to_install[@]})); then
    log "Installing $description: ${to_install[*]}"
    apt_safe update -qq
    apt_safe install -y "${to_install[@]}"
  else
    log "$description already installed."
  fi
}

# --- Installation Functions ---

# Detect CPU vendor and install appropriate microcode.
install_microcode() {
  local vendor cpu_info pkg
  cpu_info="$(lscpu | grep 'Vendor ID' || true)"

  if [[ "$cpu_info" =~ GenuineIntel ]]; then
    vendor="intel"
  elif [[ "$cpu_info" =~ AuthenticAMD ]]; then
    vendor="amd"
  else
    log "Unknown CPU vendor, skipping microcode."
    return 0
  fi

  pkg="${vendor}-microcode"
  install_pkgs "$vendor CPU microcode" "$pkg"
}

# WiFi and Bluetooth firmware.
install_wireless() {
  install_pkgs "wireless firmware" "${WIRELESS_PKGS[@]}"
}

# Bluetooth support and service.
install_bluetooth() {
  install_pkgs "Bluetooth support" "${BLUETOOTH_PKGS[@]}"

  # Ensure Bluetooth service is enabled.
  if systemctl is-enabled bluetooth.service >/dev/null 2>&1; then
    log "Bluetooth service already enabled."
  else
    log "Enabling Bluetooth service…"
    $(need_sudo) systemctl enable bluetooth.service
    # Start the service, but don't fail if it can't (e.g., no hardware).
    $(need_sudo) systemctl start bluetooth.service || true
  fi
}

# Graphics drivers (primarily for Intel integrated GPUs).
install_graphics() {
  # Use a subshell to temporarily ignore errors if non-free packages aren't available.
  (install_pkgs "graphics drivers" "${INTEL_GRAPHICS_PKGS[@]}") || {
    log "Some graphics packages might be unavailable (non-free repo may be needed)."
  }
}

# ACPI and other essential laptop support packages.
install_laptop_support() {
  # Note: laptop-mode-tools is not installed as it conflicts with TLP.
  install_pkgs "laptop support (ACPI)" "${LAPTOP_PKGS[@]}"
}

# --- Verification ---

# Check for loaded modules and active services.
verify_drivers() {
  log "Verifying driver status…"

  # Check WiFi driver.
  if lspci | grep -qi "network.*intel"; then
    if lsmod | grep -q "iwlwifi"; then
      log "✓ Intel WiFi driver (iwlwifi) is loaded."
    else
      log "⚠ Intel WiFi hardware detected, but iwlwifi driver is not loaded."
    fi
  fi

  # Check Bluetooth service.
  if systemctl is-active bluetooth.service >/dev/null 2>&1; then
    log "✓ Bluetooth service is active."
  else
    log "⚠ Bluetooth service is not active (this is normal if no BT hardware is present)."
  fi

  # Check graphics/Vulkan driver.
  if command -v vulkaninfo >/dev/null 2>&1; then
    if vulkaninfo --summary | grep -q deviceName; then
      log "✓ Vulkan is properly configured and found a GPU."
    else
      log "⚠ Vulkan tools are installed, but no compatible GPU was found."
    fi
  fi

  # Check ACPI service.
  if systemctl is-active acpid.service >/dev/null 2>&1; then
    log "✓ ACPI service is active."
  else
    log "⚠ ACPI service is not active."
  fi
}

# --- Main Execution ---

main() {
  log "=== Hardware Drivers & Firmware Installation ==="
  install_microcode
  install_wireless
  install_bluetooth
  install_graphics
  install_laptop_support
  log "---"
  verify_drivers
  log "Driver installation and verification complete."
}

main "$@"
