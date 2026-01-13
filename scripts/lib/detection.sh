#!/usr/bin/env bash
# Hardware and system detection utilities for ubuntu-bootstrap
# Non-destructive detection functions

# Privileged wrapper (for safe dry-run/CI behavior)
if ! declare -F run_privileged >/dev/null 2>&1; then
    DETECTION_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    # shellcheck source=/dev/null
    source "$DETECTION_LIB_DIR/privileged.sh" 2>/dev/null || true
fi

# Detect CPU vendor (AuthenticAMD, GenuineIntel, or Unknown)
detect_cpu_vendor() {
    if [[ -r /proc/cpuinfo ]]; then
        grep -m1 "vendor_id" /proc/cpuinfo | awk '{print $3}' || echo "Unknown"
    else
        echo "Unknown"
    fi
}

# Detect CPU model name
detect_cpu_model() {
    if [[ -r /proc/cpuinfo ]]; then
        grep -m1 "model name" /proc/cpuinfo | sed 's/model name.*: //' || echo "Unknown"
    else
        echo "Unknown"
    fi
}

# Detect CPU core count
detect_cpu_cores() {
    if [[ -r /proc/cpuinfo ]]; then
        grep -c "^processor" /proc/cpuinfo || echo "Unknown"
    else
        echo "Unknown"
    fi
}

# Detect if system has NVIDIA GPU
has_nvidia_gpu() {
    command -v lspci >/dev/null 2>&1 || return 1
    lspci | grep -qi "nvidia" && return 0
    return 1
}

# Detect if system has AMD GPU
has_amd_gpu() {
    command -v lspci >/dev/null 2>&1 || return 1
    lspci | grep -iE "vga|3d|display" | grep -qi "amd" && return 0
    return 1
}

# Detect if system has Intel GPU
has_intel_gpu() {
    command -v lspci >/dev/null 2>&1 || return 1
    lspci | grep -iE "vga|3d|display" | grep -qi "intel" && return 0
    return 1
}

# Detect laptop (via chassis type or battery presence)
is_laptop() {
    # Check dmidecode chassis type
    if command -v dmidecode >/dev/null 2>&1 && privileged_allowed; then
        local chassis
        chassis=$(run_privileged dmidecode -s chassis-type 2>/dev/null || true)
        case "$chassis" in
            "Notebook"|"Laptop"|"Portable"|"Sub Notebook")
                return 0
                ;;
        esac
    fi

    # Fallback: check for battery
    if [[ -d /sys/class/power_supply ]]; then
        ls /sys/class/power_supply/ | grep -qi "bat" && return 0
    fi

    return 1
}

# Detect system manufacturer
detect_manufacturer() {
    if command -v dmidecode >/dev/null 2>&1; then
        local manuf
        if privileged_allowed; then
            manuf=$(run_privileged dmidecode -s system-manufacturer 2>/dev/null || echo "Unknown")
        else
            manuf="Unknown"
        fi
        echo "$manuf"
    else
        echo "Unknown"
    fi
}

# Detect system product name
detect_product_name() {
    if command -v dmidecode >/dev/null 2>&1; then
        local prod
        if privileged_allowed; then
            prod=$(run_privileged dmidecode -s system-product-name 2>/dev/null || echo "Unknown")
        else
            prod="Unknown"
        fi
        echo "$prod"
    else
        echo "Unknown"
    fi
}

# Detect Ubuntu version (returns version like "24.04" or "22.04")
detect_ubuntu_version() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        echo "${VERSION_ID:-unknown}"
    else
        echo "unknown"
    fi
}

# Detect secure boot state (enabled/disabled/unknown)
detect_secure_boot() {
    if command -v mokutil >/dev/null 2>&1; then
        if mokutil --sb-state 2>/dev/null | grep -qi "enabled"; then
            echo "enabled"
        elif mokutil --sb-state 2>/dev/null | grep -qi "disabled"; then
            echo "disabled"
        else
            echo "unknown"
        fi
    elif [[ -f /sys/firmware/efi/efivars/SecureBoot-* ]]; then
        # Fallback: check EFI var (requires root)
        echo "unknown"
    else
        echo "unknown"
    fi
}

# Detect TPM presence
has_tpm() {
    if [[ -d /sys/class/tpm ]]; then
        return 0
    fi
    return 1
}

# Get total memory in GB
get_total_memory_gb() {
    if [[ -r /proc/meminfo ]]; then
        local mem_kb
        mem_kb=$(grep "MemTotal" /proc/meminfo | awk '{print $2}')
        echo $(( mem_kb / 1024 / 1024 ))
    else
        echo "Unknown"
    fi
}

# Get total disk size for root filesystem
get_root_disk_size() {
    df -h / | awk 'NR==2 {print $2}' || echo "Unknown"
}

# Detect if running in VM
is_virtual_machine() {
    if command -v systemd-detect-virt >/dev/null 2>&1; then
        systemd-detect-virt -q && return 0
    fi

    # Fallback checks
    if grep -qi "hypervisor" /proc/cpuinfo 2>/dev/null; then
        return 0
    fi

    return 1
}
