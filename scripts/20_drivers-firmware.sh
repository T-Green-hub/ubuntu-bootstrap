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
  i965-va-driver
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
    apt_safe update -qq || return 1
    if apt_safe install -y "${to_install[@]}"; then
      log "✓ $description installed successfully"
    else
      log "ERROR: Failed to install $description"
      return 1
    fi
  else
    log "✓ $description already installed"
  fi
}

# --- Installation Functions ---

# Detect CPU vendor and install appropriate microcode.
install_microcode() {
  local vendor cpu_info pkg
  cpu_info="$(lscpu | grep 'Vendor ID' || true)"

  if [[ "$cpu_info" =~ GenuineIntel ]]; then
    vendor="intel"
    log "Detected Intel CPU"
  elif [[ "$cpu_info" =~ AuthenticAMD ]]; then
    vendor="amd"
    log "Detected AMD CPU"
  else
    log "⚠ Unknown CPU vendor, skipping microcode"
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
    log "✓ Bluetooth service already enabled"
  else
    log "Enabling Bluetooth service…"
    if run $(need_sudo) systemctl enable bluetooth.service; then
      log "✓ Bluetooth service enabled"
    else
      log "⚠ Failed to enable Bluetooth service (may not have hardware)"
    fi
    # Start the service, but don't fail if it can't (e.g., no hardware).
    if run $(need_sudo) systemctl start bluetooth.service; then
      log "✓ Bluetooth service started"
    else
      log "⚠ Could not start Bluetooth service (this is normal without BT hardware)"
    fi
  fi
}

# Graphics drivers (detect GPU vendor and install appropriate drivers).
install_graphics() {
  local gpu_info pkgs_to_install=()
  gpu_info="$(lspci | grep -i vga || true)"

  # Detect GPU vendor
  if [[ "$gpu_info" =~ Intel ]]; then
    log "Intel GPU detected, installing Intel graphics drivers…"
    pkgs_to_install+=("${INTEL_GRAPHICS_PKGS[@]}")
  elif [[ "$gpu_info" =~ NVIDIA ]]; then
    log "NVIDIA GPU detected. For proprietary drivers, install via 'ubuntu-drivers' or 'Additional Drivers'."
    # Add basic mesa support
    pkgs_to_install+=(mesa-vulkan-drivers vulkan-tools)
  elif [[ "$gpu_info" =~ AMD ]]; then
    log "AMD GPU detected, installing Mesa drivers…"
    pkgs_to_install+=(mesa-vulkan-drivers mesa-va-drivers vulkan-tools)
  else
    log "Unknown or no dedicated GPU detected, installing generic Mesa drivers…"
    pkgs_to_install+=(mesa-vulkan-drivers vulkan-tools)
  fi

  if ((${#pkgs_to_install[@]})); then
    # Use a subshell to temporarily ignore errors if non-free packages aren't available.
    (install_pkgs "graphics drivers" "${pkgs_to_install[@]}") || {
      log "Some graphics packages might be unavailable (non-free repo may be needed)."
    }
  fi
}

# ACPI and other essential laptop support packages.
install_laptop_support() {
  # Note: laptop-mode-tools is not installed as it conflicts with TLP.
  install_pkgs "laptop support (ACPI)" "${LAPTOP_PKGS[@]}"
    # Ensure ACPI service is enabled and started
    if systemctl is-enabled acpid.service >/dev/null 2>&1; then
      log "✓ ACPI service already enabled"
    else
      log "Enabling ACPI (acpid) service…"
      if run $(need_sudo) systemctl enable acpid.service; then
        log "✓ ACPI service enabled"
      else
        log "⚠ Failed to enable ACPI service"
      fi
    fi
    if systemctl is-active acpid.service >/dev/null 2>&1; then
      log "✓ ACPI service is active"
    else
      log "Starting ACPI (acpid) service…"
      if run $(need_sudo) systemctl start acpid.service; then
        log "✓ ACPI service started"
      else
        log "⚠ Failed to start ACPI service"
      fi
    fi
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
