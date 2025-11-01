#!/usr/bin/env bash
# System hardware and software detection utility
# Identifies CPU, GPU, wireless, battery, and other hardware components
# Suggests optimal packages based on detected hardware

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export SCRIPT_DIR  # Used by sourced scripts

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

log() {
    printf '[%s] %s\n' "$(date -Iseconds)" "$*"
}

log_info() {
    echo -e "${BLUE}ℹ${NC} $*"
}

log_success() {
    echo -e "${GREEN}✓${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $*"
}

log_error() {
    echo -e "${RED}✗${NC} $*"
}

###############################################################################
# CPU Detection
###############################################################################

detect_cpu() {
    local vendor model cores
    
    if [[ -r /proc/cpuinfo ]]; then
        vendor=$(grep -m1 "vendor_id" /proc/cpuinfo | awk '{print $3}' || echo "Unknown")
        model=$(grep -m1 "model name" /proc/cpuinfo | sed 's/model name.*: //' || echo "Unknown")
        cores=$(grep -c "^processor" /proc/cpuinfo || echo "Unknown")
    else
        vendor="Unknown"
        model="Unknown"
        cores="Unknown"
    fi
    
    echo ""
    log_info "=== CPU Information ==="
    echo "  Vendor: $vendor"
    echo "  Model:  $model"
    echo "  Cores:  $cores"
    
    # Suggest microcode package
    case "$vendor" in
        GenuineIntel)
            log_success "Recommended: intel-microcode"
            echo "            intel-microcode"
            ;;
        AuthenticAMD)
            log_success "Recommended: amd64-microcode"
            echo "            amd64-microcode"
            ;;
        *)
            log_warning "Unknown CPU vendor, no microcode package recommended"
            ;;
    esac
}

###############################################################################
# GPU Detection
###############################################################################

detect_gpu() {
    echo ""
    log_info "=== GPU Information ==="
    
    local gpu_count=0
    local has_intel=0
    local has_nvidia=0
    local has_amd=0
    
    if command -v lspci &>/dev/null; then
        while IFS= read -r line; do
            ((gpu_count++)) || true
            echo "  GPU $gpu_count: $line"
            
            case "$line" in
                *Intel*)
                    has_intel=1
                    ;;
                *NVIDIA*)
                    has_nvidia=1
                    ;;
                *AMD*|*ATI*)
                    has_amd=1
                    ;;
            esac
        done < <(lspci | grep -i vga || true)
    else
        log_warning "lspci not found, cannot detect GPU"
        return
    fi
    
    if ((gpu_count == 0)); then
        log_warning "No GPU detected"
        return
    fi
    
    echo ""
    log_success "Recommended GPU packages:"
    
    if ((has_intel)); then
        echo "  Intel GPU packages:"
        echo "    - i965-va-driver (for older Intel GPUs: HD Graphics)"
        echo "    - intel-media-va-driver-non-free (for newer: Gen8+)"
        echo "    - mesa-vulkan-drivers"
        echo "    - vulkan-tools"
    fi
    
    if ((has_nvidia)); then
        echo "  NVIDIA GPU packages:"
        echo "    - nvidia-driver-XXX (check: ubuntu-drivers devices)"
        echo "    - nvidia-settings"
        echo "    - mesa-vulkan-drivers (for hybrid/fallback)"
        log_info "Run 'ubuntu-drivers devices' to see available NVIDIA drivers"
    fi
    
    if ((has_amd)); then
        echo "  AMD GPU packages:"
        echo "    - mesa-vulkan-drivers"
        echo "    - mesa-va-drivers"
        echo "    - vulkan-tools"
        echo "    - radeontop (GPU monitoring)"
    fi
    
    if ((has_intel + has_nvidia + has_amd == 0)); then
        echo "  Generic GPU packages:"
        echo "    - mesa-vulkan-drivers"
        echo "    - vulkan-tools"
    fi
}

###############################################################################
# Wireless Detection
###############################################################################

detect_wireless() {
    echo ""
    log_info "=== Wireless Hardware ==="
    
    local has_wifi=0
    local has_bluetooth=0
    
    if command -v lspci &>/dev/null; then
        if lspci | grep -qi "network.*intel"; then
            log_success "Intel WiFi adapter detected"
            echo "  Recommended: linux-firmware, wireless-regdb"
            has_wifi=1
        elif lspci | grep -qi "network.*realtek"; then
            log_success "Realtek WiFi adapter detected"
            echo "  Recommended: linux-firmware, rtl8xxxu-firmware"
            has_wifi=1
        elif lspci | grep -qi "network.*broadcom"; then
            log_success "Broadcom WiFi adapter detected"
            echo "  Recommended: linux-firmware, bcmwl-kernel-source"
            has_wifi=1
        elif lspci | grep -qi "wireless\|802\.11"; then
            log_success "WiFi adapter detected"
            echo "  Recommended: linux-firmware"
            has_wifi=1
        fi
    fi
    
    if command -v lsusb &>/dev/null; then
        if lsusb | grep -qi "bluetooth"; then
            log_success "Bluetooth adapter detected"
            echo "  Recommended: bluez, bluez-tools"
            has_bluetooth=1
        fi
    fi
    
    if ((has_wifi == 0)); then
        log_warning "No WiFi adapter detected (or lspci not available)"
    fi
    
    if ((has_bluetooth == 0)); then
        log_warning "No Bluetooth adapter detected (or lsusb not available)"
    fi
}

###############################################################################
# Battery and Power Detection
###############################################################################

detect_battery() {
    echo ""
    log_info "=== Power Management ==="
    
    local battery_path="/sys/class/power_supply/BAT0"
    
    if [[ -d "$battery_path" ]]; then
        log "  Battery detected: $battery_path"
        log_success "Battery detected: $(cat ${battery_path}/manufacturer 2>/dev/null || echo 'Unknown')"
        
        # Check for charge threshold support
        if [[ -f "${battery_path}/charge_control_start_threshold" ]] || \
           [[ -f "${battery_path}/charge_start_threshold" ]]; then
            log_success "Battery charge thresholds SUPPORTED"
            echo "  Can configure battery conservation (e.g., 20-80%)"
        else
            log_warning "Battery charge thresholds NOT supported"
        fi
        
        # Check current charge
        if [[ -f "${battery_path}/capacity" ]]; then
            local capacity
            capacity=$(cat "${battery_path}/capacity")
            echo "  Current charge: ${capacity}%"
        fi
        
        echo ""
        log_success "Recommended power packages:"
        echo "    - tlp (advanced power management)"
        echo "    - tlp-rdw (Radio Device Wizard)"
        echo "    - powertop (power monitoring)"
        echo "    - acpi-call-dkms (for ThinkPad battery thresholds)"
    else
        log_warning "No battery detected (desktop system)"
        echo "  Power management tools less critical for desktop"
    fi
}

###############################################################################
# Ubuntu Version Check
###############################################################################

detect_ubuntu_version() {
    echo ""
    log_info "=== Ubuntu Version ==="
    
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        echo "  Distribution: $NAME"
        echo "  Version:      $VERSION"
        echo "  Codename:     $VERSION_CODENAME"
        
        # Check for known package changes by version
        case "$VERSION_CODENAME" in
            noble|oracular)
                log_info "Ubuntu 24.04+ detected"
                echo "  Package notes:"
                echo "    - Use 'i965-va-driver' (not libva-intel-driver)"
                echo "    - Python 3.12+ available"
                ;;
            jammy)
                log_info "Ubuntu 22.04 LTS detected"
                echo "  Package notes:"
                echo "    - Use 'libva-intel-driver' or 'i965-va-driver'"
                echo "    - Python 3.10 default"
                ;;
            focal)
                log_info "Ubuntu 20.04 LTS detected"
                log_warning "Consider upgrading to 22.04 or 24.04"
                ;;
            *)
                log_warning "Unknown Ubuntu version: $VERSION_CODENAME"
                ;;
        esac
    else
        log_error "/etc/os-release not found"
    fi
}

###############################################################################
# System Form Factor
###############################################################################

detect_form_factor() {
    echo ""
    log_info "=== System Form Factor ==="
    
    local chassis_type="Unknown"
    
    if command -v dmidecode &>/dev/null && [[ $EUID -eq 0 || -n "${SUDO_USER:-}" ]]; then
        chassis_type=$(sudo dmidecode -s chassis-type 2>/dev/null || echo "Unknown")
    elif [[ -r /sys/devices/virtual/dmi/id/chassis_type ]]; then
        local chassis_code
        chassis_code=$(cat /sys/devices/virtual/dmi/id/chassis_type 2>/dev/null || echo "0")
        case "$chassis_code" in
            3) chassis_type="Desktop" ;;
            8|9|10|11|14) chassis_type="Laptop" ;;
            *) chassis_type="Unknown (code: $chassis_code)" ;;
        esac
    fi
    
    echo "  Chassis type: $chassis_type"
    
    case "$chassis_type" in
        *Laptop*|*Notebook*|*Portable*)
            log_success "Laptop detected"
            echo "  Recommended optimizations:"
            echo "    - TLP for battery life"
            echo "    - CPU frequency scaling"
            echo "    - Suspend/hibernate support"
            ;;
        *Desktop*|*Tower*)
            log_success "Desktop detected"
            echo "  Desktop-specific optimizations:"
            echo "    - Performance CPU governor"
            echo "    - No battery management needed"
            ;;
        *)
            log_warning "Unknown form factor"
            ;;
    esac
}

###############################################################################
# Peripheral Detection
###############################################################################

detect_peripherals() {
    echo ""
    log_info "=== Peripherals ==="
    
    if command -v lsusb &>/dev/null; then
        # Fingerprint reader
        if lsusb | grep -qi "fingerprint"; then
            log_success "Fingerprint reader detected"
            echo "  Recommended: fprintd, libpam-fprintd"
        fi
        
        # Webcam
        if lsusb | grep -qi "camera\|webcam"; then
            log_success "Webcam detected"
            echo "  Test with: cheese or guvcview"
        fi
        
        # Card reader
        if lsusb | grep -qi "card reader"; then
            log_success "Card reader detected"
        fi
    fi
}

###############################################################################
# Package Availability Check
###############################################################################

check_package_availability() {
    local package="$1"
    apt-cache show "$package" &>/dev/null
}

verify_recommended_packages() {
    echo ""
    log_info "=== Package Availability Check ==="
    
    local packages=(
        "i965-va-driver"
        "intel-media-va-driver-non-free"
        "mesa-vulkan-drivers"
        "tlp"
        "bluez"
        "linux-firmware"
    )
    
    log_info "Checking if recommended packages are available..."
    for pkg in "${packages[@]}"; do
        if check_package_availability "$pkg"; then
            echo "  ✓ $pkg - Available"
        else
            echo "  ✗ $pkg - NOT FOUND (may need additional repos)"
        fi
    done
}

###############################################################################
# Main
###############################################################################

generate_report() {
    echo ""
    echo "========================================================================"
    echo "           UBUNTU BOOTSTRAP - SYSTEM DETECTION REPORT"
    echo "========================================================================"
    
    detect_ubuntu_version
    detect_form_factor
    detect_cpu
    detect_gpu
    detect_wireless
    detect_battery
    detect_peripherals
    verify_recommended_packages
    
    echo ""
    echo "========================================================================"
    echo "                         REPORT COMPLETE"
    echo "========================================================================"
    echo ""
    log_info "Tip: Run this script with sudo for more detailed hardware detection"
    log_info "Usage: sudo bash scripts/detect_system.sh"
    echo ""
}

main() {
    if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
        echo "Usage: $0 [--help]"
        echo ""
        echo "Detects system hardware and recommends appropriate packages."
        echo "Run with sudo for more detailed information."
        exit 0
    fi
    
    generate_report
}

main "$@"
