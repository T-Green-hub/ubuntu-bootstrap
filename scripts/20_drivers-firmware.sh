#!/usr/bin/env bash
# Ubuntu 24.04 hardware drivers and firmware (idempotent).
# CPU microcode, WiFi, graphics, Bluetooth, and laptop-specific drivers.

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../hardware/common.sh"

log(){ printf '[%s] %s\n' "$(date -Iseconds)" "$*"; }
need_sudo(){ if [[ $EUID -ne 0 ]]; then echo sudo; fi; }

# Detect CPU vendor and install appropriate microcode
install_microcode(){
  local vendor cpu_info
  cpu_info="$(lscpu | grep 'Vendor ID' || true)"

  if [[ "$cpu_info" =~ GenuineIntel ]]; then
    vendor="intel"
  elif [[ "$cpu_info" =~ AuthenticAMD ]]; then
    vendor="amd"
  else
    log "Unknown CPU vendor, skipping microcode."
    return 0
  fi

  local pkg="${vendor}-microcode"

  if dpkg -s "$pkg" >/dev/null 2>&1; then
    log "Microcode already installed: $pkg"
  else
    log "Installing $vendor CPU microcode: $pkg"
    apt_safe update -qq
    apt_safe install -y "$pkg"
    log "Microcode installed. Reboot recommended to apply."
  fi
}

# WiFi and Bluetooth firmware
install_wireless(){
  local pkgs=( linux-firmware )
  local to_install=()

  # linux-firmware includes Intel WiFi (iwlwifi), Bluetooth, and more
  for pkg in "${pkgs[@]}"; do
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
      to_install+=("$pkg")
    fi
  done

  if ((${#to_install[@]})); then
    log "Installing wireless firmware: ${to_install[*]}"
    apt_safe install -y "${to_install[@]}"
  else
    log "Wireless firmware already installed."
  fi
}

# Bluetooth support
install_bluetooth(){
  local pkgs=( bluez bluez-tools )
  local to_install=()

  for pkg in "${pkgs[@]}"; do
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
      to_install+=("$pkg")
    fi
  done

  if ((${#to_install[@]})); then
    log "Installing Bluetooth support: ${to_install[*]}"
    apt_safe install -y "${to_install[@]}"
  else
    log "Bluetooth already installed."
  fi

  # Ensure Bluetooth service is enabled
  if systemctl is-enabled bluetooth.service >/dev/null 2>&1; then
    log "Bluetooth service already enabled."
  else
    log "Enabling Bluetooth service…"
    $(need_sudo) systemctl enable bluetooth.service
    $(need_sudo) systemctl start bluetooth.service || true
  fi
}

# Graphics drivers (Intel integrated)
install_graphics(){
  local pkgs=(
    mesa-vulkan-drivers
    libva-intel-driver
    intel-media-va-driver-non-free
    vulkan-tools
  )
  local to_install=()

  for pkg in "${pkgs[@]}"; do
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
      to_install+=("$pkg")
    fi
  done

  if ((${#to_install[@]})); then
    log "Installing graphics drivers: ${to_install[*]}"
    apt_safe install -y "${to_install[@]}" 2>/dev/null || {
      log "Some graphics packages unavailable (non-free repo may be needed)."
    }
  else
    log "Graphics drivers already installed."
  fi
}

# ACPI and laptop support
install_laptop_support(){
  local pkgs=( acpid )
  local to_install=()

  # Note: laptop-mode-tools conflicts with TLP (installed in 50_laptop.sh)
  # So we only install acpid here

  for pkg in "${pkgs[@]}"; do
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
      to_install+=("$pkg")
    fi
  done

  if ((${#to_install[@]})); then
    log "Installing laptop support: ${to_install[*]}"
    apt_safe install -y "${to_install[@]}"
  else
    log "Laptop support already installed."
  fi
}

# Verification: check loaded modules and firmware
verify_drivers(){
  log "Verifying driver status…"

  # Check WiFi
  if lspci | grep -qi "network.*intel"; then
    if lsmod | grep -q "iwlwifi"; then
      log "✓ Intel WiFi driver (iwlwifi) loaded."
    else
      log "⚠ Intel WiFi detected but driver not loaded."
    fi
  fi

  # Check Bluetooth
  if systemctl is-active bluetooth.service >/dev/null 2>&1; then
    log "✓ Bluetooth service active."
  else
    log "⚠ Bluetooth service not active."
  fi

  # Check graphics
  if command -v vulkaninfo >/dev/null 2>&1; then
    log "✓ Vulkan tools installed."
  fi
}

main(){
  log "=== Hardware Drivers & Firmware Installation ==="
  install_microcode
  install_wireless
  install_bluetooth
  install_graphics
  install_laptop_support
  verify_drivers
  log "Driver installation complete."
}

main "$@"
