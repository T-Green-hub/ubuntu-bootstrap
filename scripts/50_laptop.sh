#!/usr/bin/env bash
# Hardware detection and optimization dispatcher
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARDWARE_DIR="${SCRIPT_DIR}/../hardware"

log() {
    printf '[%s] %s\n' "$(date -Iseconds)" "$*"
}

# Detect hardware using dmidecode
detect_hardware() {
    local vendor model
    
    # Try dmidecode first (most reliable)
    if command -v dmidecode &>/dev/null; then
        vendor=$(sudo dmidecode -s system-manufacturer 2>/dev/null | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]' || echo "unknown")
        model=$(sudo dmidecode -s system-product-name 2>/dev/null | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]' || echo "unknown")
    else
        log "WARNING: dmidecode not found, trying alternative detection..."
        vendor=$(cat /sys/devices/virtual/dmi/id/sys_vendor 2>/dev/null | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]' || echo "unknown")
        model=$(cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]' || echo "unknown")
    fi
    
    # Normalize and match to profile
    local hardware_id="${vendor}-${model}"
    
    case "${hardware_id}" in
        *lenovo*thinkpad*t14*|*lenovo*20w4*|*lenovo*20w5*|*lenovo*20wn*)
            echo "thinkpad-t14"
            ;;
        *hp*15*|*hp*laptop*15*)
            echo "hp-laptop-15"
            ;;
        *)
            echo "generic"  # Safe fallback profile
            ;;
    esac
}

# Get hardware information for logging
get_hardware_info() {
    local vendor model product
    
    if command -v dmidecode &>/dev/null; then
        vendor=$(sudo dmidecode -s system-manufacturer 2>/dev/null || echo "Unknown")
        model=$(sudo dmidecode -s system-product-name 2>/dev/null || echo "Unknown")
        product=$(sudo dmidecode -s system-version 2>/dev/null || echo "Unknown")
    else
        vendor=$(cat /sys/devices/virtual/dmi/id/sys_vendor 2>/dev/null || echo "Unknown")
        model=$(cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null || echo "Unknown")
        product=$(cat /sys/devices/virtual/dmi/id/product_version 2>/dev/null || echo "Unknown")
    fi
    
    echo "${vendor} ${model} (${product})"
}

main() {
    log "=== Hardware Detection and Optimization ==="
    
    # Show detected hardware
    local hw_info
    hw_info=$(get_hardware_info)
    log "Detected hardware: ${hw_info}"
    
    # Allow manual override via environment variable
    local profile="${HARDWARE_PROFILE:-auto}"
    
    if [[ "${profile}" == "auto" ]]; then
        profile=$(detect_hardware)
        log "Auto-detected profile: ${profile}"
    else
        log "Using manual profile override: ${profile}"
    fi
    
    # Find and execute profile script
    local profile_script="${HARDWARE_DIR}/${profile}.sh"
    
    if [[ -f "${profile_script}" ]]; then
        log "Executing hardware profile: ${profile}"
        log "---"
        bash "${profile_script}"
        log "---"
        log "Hardware optimization complete"
    else
        log "ERROR: Profile script not found: ${profile_script}"
        log "Available profiles: thinkpad-t14, hp-laptop-15, generic"
        log "Override with: HARDWARE_PROFILE=generic bash $0"
        exit 1
    fi
    
    log "=== Hardware Optimization Complete ==="
}

main "$@"
