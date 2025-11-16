#!/usr/bin/env bash
# Pre-flight checks for ubuntu-bootstrap
# Verifies system requirements and potential issues before running bootstrap
# Particularly important for Tiger Lake (11th gen Intel) systems

set -euo pipefail

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ${NC} $*"; }
log_success() { echo -e "${GREEN}✓${NC} $*"; }
log_warning() { echo -e "${YELLOW}⚠${NC} $*"; }
log_error() { echo -e "${RED}✗${NC} $*"; }

WARNINGS=0
ERRORS=0
CHECKS=0

check() {
    local check_name="$1"
    CHECKS=$((CHECKS + 1))
    echo ""
    log_info "Checking: $check_name"
}

warn() {
    WARNINGS=$((WARNINGS + 1))
    log_warning "$*"
}

error() {
    ERRORS=$((ERRORS + 1))
    log_error "$*"
}

success() {
    log_success "$*"
}

# Check 1: Network connectivity
check_network() {
    check "Network connectivity"
    
    local hosts=("1.1.1.1" "8.8.8.8" "github.com")
    local reachable=0
    
    for host in "${hosts[@]}"; do
        if ping -c 1 -W 2 "$host" >/dev/null 2>&1; then
            success "Can reach $host"
            reachable=$((reachable + 1))
        fi
    done
    
    if ((reachable == 0)); then
        error "No network connectivity. Bootstrap requires internet access."
        echo "  Try: Check WiFi/Ethernet connection"
    elif ((reachable < 3)); then
        warn "Limited connectivity (${reachable}/${#hosts[@]} hosts reachable)"
    else
        success "Network connectivity OK"
    fi
}

# Check 2: Ubuntu version
check_ubuntu_version() {
    check "Ubuntu version"
    
    if [[ ! -f /etc/os-release ]]; then
        error "/etc/os-release not found"
        return
    fi
    
    source /etc/os-release
    
    if [[ "$ID" != "ubuntu" ]]; then
        error "Not Ubuntu (detected: $ID). This bootstrap is designed for Ubuntu."
        return
    fi
    
    local version_id="${VERSION_ID:-unknown}"
    echo "  Version: $PRETTY_NAME"
    
    case "$version_id" in
        24.04)
            success "Ubuntu 24.04 LTS (Noble) - Fully supported"
            ;;
        22.04)
            success "Ubuntu 22.04 LTS (Jammy) - Supported"
            warn "Consider upgrading to 24.04 for better Tiger Lake support"
            ;;
        20.04)
            warn "Ubuntu 20.04 LTS (Focal) - Older version"
            warn "Tiger Lake requires kernel 5.11+, check your kernel version"
            ;;
        *)
            warn "Ubuntu $version_id - Not specifically tested"
            ;;
    esac
}

# Check 3: Kernel version
check_kernel_version() {
    check "Kernel version"
    
    local kernel_version
    kernel_version=$(uname -r)
    local kernel_major
    kernel_major=$(echo "$kernel_version" | cut -d. -f1)
    local kernel_minor
    kernel_minor=$(echo "$kernel_version" | cut -d. -f2)
    
    echo "  Kernel: $kernel_version"
    
    # Check if Tiger Lake CPU
    local cpu_model
    cpu_model=$(grep -m1 'model name' /proc/cpuinfo | sed 's/.*: //' || echo "Unknown")
    local is_tiger_lake=0
    
    if echo "$cpu_model" | grep -qE '11th Gen|i[357]-11[0-9]{2}'; then
        is_tiger_lake=1
        echo "  CPU: $cpu_model (Tiger Lake)"
    fi
    
    if (( kernel_major >= 6 )); then
        success "Kernel 6.x - Excellent for modern hardware"
    elif (( kernel_major == 5 )); then
        if (( kernel_minor >= 14 )); then
            success "Kernel 5.14+ - Good for Tiger Lake"
        elif (( kernel_minor >= 11 )); then
            if (( is_tiger_lake )); then
                warn "Kernel 5.11-5.13 - Basic Tiger Lake support"
                warn "Recommend upgrading to 5.14+ or 6.x for better Iris Xe support"
            else
                success "Kernel 5.11+ - OK"
            fi
        else
            if (( is_tiger_lake )); then
                error "Kernel < 5.11 - Insufficient for Tiger Lake"
                echo "  Install HWE kernel: sudo apt install linux-generic-hwe-$(lsb_release -rs)"
            else
                warn "Kernel < 5.11 - Consider updating"
            fi
        fi
    else
        error "Kernel < 5.0 - Too old"
        echo "  Update kernel: sudo apt update && sudo apt upgrade"
    fi
}

# Check 4: System architecture
check_architecture() {
    check "System architecture"
    
    local arch
    arch=$(uname -m)
    
    if [[ "$arch" == "x86_64" ]]; then
        success "x86_64 (64-bit) - OK"
    else
        error "Architecture $arch not supported. Bootstrap requires x86_64."
    fi
}

# Check 5: Boot mode (UEFI vs Legacy)
check_boot_mode() {
    check "Boot mode"
    
    if [[ -d /sys/firmware/efi ]]; then
        success "UEFI boot mode - OK"
        
        # Check if Secure Boot is enabled
        if command -v mokutil >/dev/null 2>&1; then
            if mokutil --sb-state 2>/dev/null | grep -q "SecureBoot enabled"; then
                echo "  Secure Boot: Enabled (Ubuntu 24.04 supports this)"
            else
                echo "  Secure Boot: Disabled"
            fi
        fi
    else
        warn "Legacy BIOS mode detected"
        warn "Modern systems (like T14s Gen 2) should use UEFI"
        echo "  Check BIOS settings and reinstall in UEFI mode if possible"
    fi
}

# Check 6: Hardware detection
check_hardware() {
    check "Hardware detection"
    
    # System info
    if command -v dmidecode >/dev/null 2>&1; then
        local manufacturer product
        manufacturer=$(sudo dmidecode -s system-manufacturer 2>/dev/null || echo "Unknown")
        product=$(sudo dmidecode -s system-product-name 2>/dev/null || echo "Unknown")
        
        if [[ "$manufacturer" != "Unknown" && "$product" != "Unknown" ]]; then
            echo "  System: $manufacturer $product"
            
            # Check for known laptop models
            if echo "$product" | grep -qiE "ThinkPad T14s.*Gen 2"; then
                success "ThinkPad T14s Gen 2 detected - Specific optimizations available"
            elif echo "$product" | grep -qi "ThinkPad"; then
                success "ThinkPad detected - Laptop optimizations will be applied"
            elif echo "$product" | grep -qiE "HP.*15"; then
                success "HP Laptop 15 detected - Specific optimizations available"
            else
                echo "  Generic laptop profile will be used"
            fi
        else
            echo "  System detection requires sudo, skipping details"
        fi
    fi
    
    # GPU detection
    if command -v lspci >/dev/null 2>&1; then
        local gpu_info
        gpu_info=$(lspci | grep -i vga || echo "No GPU detected")
        echo "  GPU: $gpu_info"
        
        if echo "$gpu_info" | grep -qE "TigerLake.*Iris.*Xe"; then
            success "Intel Iris Xe (Tiger Lake) detected"
            echo "  Will install: intel-media-va-driver-non-free for hardware acceleration"
        elif echo "$gpu_info" | grep -qi "Intel"; then
            success "Intel GPU detected"
        fi
    fi
    
    # WiFi detection
    if command -v lspci >/dev/null 2>&1; then
        local wifi_info
        wifi_info=$(lspci | grep -iE "network|wireless" || echo "No WiFi detected")
        echo "  WiFi: $wifi_info"
        
        if echo "$wifi_info" | grep -qi "AX201"; then
            success "Intel AX201 (WiFi 6) detected"
            echo "  Will apply stability optimizations (power_save=0)"
        elif echo "$wifi_info" | grep -qi "Intel"; then
            success "Intel WiFi detected"
        fi
    fi
}

# Check 7: Disk space
check_disk_space() {
    check "Disk space"
    
    local root_avail
    root_avail=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    
    echo "  Available on /: ${root_avail}GB"
    
    if ((root_avail >= 20)); then
        success "Sufficient disk space"
    elif ((root_avail >= 10)); then
        warn "Low disk space (${root_avail}GB). Recommended: 20GB+"
    else
        error "Insufficient disk space (${root_avail}GB). Bootstrap needs at least 10GB free"
    fi
}

# Check 8: APT locks
check_apt_locks() {
    check "APT/dpkg status"
    
    if [[ $EUID -ne 0 ]]; then
        echo "  (Run with sudo for detailed lock detection)"
        return
    fi
    
    local locks=(
        "/var/lib/dpkg/lock-frontend"
        "/var/lib/dpkg/lock"
        "/var/cache/apt/archives/lock"
    )
    
    local locked=0
    for lock in "${locks[@]}"; do
        if [[ -f "$lock" ]] && fuser "$lock" >/dev/null 2>&1; then
            warn "Lock detected: $lock"
            locked=$((locked + 1))
        fi
    done
    
    if ((locked > 0)); then
        warn "APT/dpkg locks detected (${locked})"
        echo "  Bootstrap will wait for locks to clear automatically"
        echo "  Or manually: sudo killall apt apt-get && sudo rm /var/lib/dpkg/lock*"
    else
        success "No APT/dpkg locks"
    fi
    
    # Check for running package managers
    if pgrep -x "apt-get|apt|dpkg|unattended-upgrade" >/dev/null 2>&1; then
        warn "Package manager is currently running"
        echo "  Wait for current updates to complete"
    fi
}

# Check 9: sudo access
check_sudo() {
    check "Sudo access"
    
    if [[ $EUID -eq 0 ]]; then
        success "Running as root"
        return
    fi
    
    # Quick non-interactive check
    if sudo -n true 2>/dev/null; then
        success "Passwordless sudo available"
        return
    fi
    
    # Don't try interactive sudo in automated scripts
    warn "Cannot verify sudo (run with sudo for full system checks)"
    echo "  Bootstrap will request sudo when needed"
}

# Check 10: Required tools
check_required_tools() {
    check "Required tools"
    
    local required_tools=("bash" "git" "apt-get" "systemctl")
    local missing=()
    
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing+=("$tool")
        fi
    done
    
    if ((${#missing[@]} > 0)); then
        error "Missing required tools: ${missing[*]}"
        echo "  Install: sudo apt install ${missing[*]}"
    else
        success "All required tools present"
    fi
}

# Main execution
main() {
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║          Ubuntu Bootstrap Pre-Flight Check                    ║"
    echo "║          Verifying system requirements                        ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo ""
    
    check_sudo
    check_ubuntu_version
    check_architecture
    check_kernel_version
    check_boot_mode
    check_network
    check_disk_space
    check_apt_locks
    check_hardware
    check_required_tools
    
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "Pre-flight check complete"
    echo "═══════════════════════════════════════════════════════════════"
    echo "Total checks: $CHECKS"
    
    if ((ERRORS > 0)); then
        echo -e "${RED}✗ Errors: $ERRORS${NC}"
        echo ""
        echo "CRITICAL ISSUES DETECTED. Fix errors before running bootstrap."
        echo "See above for specific error messages and solutions."
        echo ""
        exit 1
    fi
    
    if ((WARNINGS > 0)); then
        echo -e "${YELLOW}⚠ Warnings: $WARNINGS${NC}"
        echo ""
        echo "Bootstrap can proceed, but warnings should be reviewed."
        echo "Some features may not work optimally."
        echo ""
        echo "Continue with bootstrap? (y/N)"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            echo "Bootstrap cancelled. Fix warnings and run again."
            exit 1
        fi
    else
        echo -e "${GREEN}✓ All checks passed!${NC}"
        echo ""
        echo "System is ready for bootstrap."
        echo ""
        echo "Run bootstrap with:"
        echo "  cd ~/ubuntu-bootstrap"
        echo "  ./scripts/run_bootstrap.sh"
        echo ""
    fi
    
    exit 0
}

main "$@"
