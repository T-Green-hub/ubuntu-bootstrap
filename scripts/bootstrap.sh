#!/usr/bin/env bash
# Ubuntu LTS Bootstrap - Main Orchestrator
# ThinkPad E16 Gen2 (AMD Ryzen 7) optimized, but hardware-agnostic
# Idempotent, safe, evidence-based system setup

set -euo pipefail
IFS=$'\n\t'

# Determine repo and script directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

# Source library functions
source "$LIB_DIR/version.sh"
source "$LIB_DIR/logging.sh"
source "$LIB_DIR/detection.sh"
source "$LIB_DIR/package.sh"
source "$LIB_DIR/report.sh"

# Default configuration
PROFILE="${PROFILE:-minimal}"
DRY_RUN="${DRY_RUN:-0}"
AUTO_YES="${AUTO_YES:-0}"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
LOG_DIR="${LOG_DIR:-$HOME/bootstrap-logs/$TIMESTAMP}"

# Parse command-line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --profile)
                PROFILE="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=1
                shift
                ;;
            --yes|-y)
                AUTO_YES=1
                shift
                ;;
            --output-dir)
                LOG_DIR="$2"
                shift 2
                ;;
            --log-dir)
                log_warning "--log-dir is deprecated and will be removed in v5.0.0. Use --output-dir instead."
                LOG_DIR="$2"
                shift 2
                ;;
            --version|-v)
                echo "$BOOTSTRAP_FULL_VERSION" && exit 0
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # Validate profile
    case "$PROFILE" in
        minimal|dev|secure)
            ;;
        *)
            log_error "Invalid profile: $PROFILE (must be: minimal, dev, secure)"
            exit 1
            ;;
    esac
}

show_help() {
    cat <<EOF
$BOOTSTRAP_FULL_VERSION

USAGE:
    $0 [OPTIONS]

OPTIONS:
    --profile <name>    Profile to use: minimal, dev, secure (default: minimal)
    --dry-run           Show what would be done without making changes (NO system changes)
    --yes, -y           Skip confirmation prompts
    --output-dir <path> Output directory for logs/reports (default: \$HOME/bootstrap-logs/<timestamp>)
    --log-dir <path>    (deprecated: use --output-dir; will be removed in v5.0.0)
    --version, -v       Show version and exit
    --help, -h          Show this help

PROFILES:
    minimal   Safe baseline: updates, firmware, drivers, power, security
    dev       Minimal + developer tools (build-essential, git, nodejs, python)
    secure    Minimal + security hardening (ufw, fail2ban, auditd)

EXAMPLES:
    $0 --profile minimal --dry-run
    $0 --profile dev --yes
    $0 --profile secure --log-dir /tmp/bootstrap-logs

SAFETY:
    - Does NOT partition disks or modify bootloader
    - Does NOT require Secure Boot to be disabled
    - Idempotent: safe to re-run
    - Creates detailed logs in log directory

EOF
}

# Initialize logging
init_logging() {
    mkdir -p "$LOG_DIR"
    LOG_FILE="$LOG_DIR/bootstrap.log"
    export LOG_FILE

    log_info "Bootstrap started"
    log_info "Profile: $PROFILE"
    if (( DRY_RUN == 1 )); then
        log_info "DRY-RUN MODE: No system changes will be made."
    fi
    log_info "Output directory: $LOG_DIR"
}

# Trap handler for cleanup
cleanup_on_exit() {
    local exit_code=$?
    if ((exit_code != 0)); then
        log_error "Bootstrap failed with exit code $exit_code"
        log_info "Logs saved to: $LOG_DIR"
    fi
    return $exit_code
}
trap cleanup_on_exit EXIT

# Confirmation prompt
confirm() {
    if (( AUTO_YES == 1 )); then
        return 0
    fi

    local prompt="$1"
    read -p "$prompt [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        return 0
    fi
    return 1
}

# System info snapshot
snapshot_system_info() {
    log_step "A. System Information Snapshot"

    local snapshot_file="$LOG_DIR/system-info.txt"

    {
        echo "=== System Snapshot ==="
        echo "Date: $(date)"
        echo "Hostname: $(hostname)"
        echo ""

        echo "=== OS Release ==="
        cat /etc/os-release 2>/dev/null || echo "N/A"
        echo ""

        echo "=== Kernel ==="
        uname -a
        echo ""

        echo "=== CPU ==="
        echo "Vendor: $(detect_cpu_vendor)"
        echo "Model: $(detect_cpu_model)"
        echo "Cores: $(detect_cpu_cores)"
        echo ""

        echo "=== Memory ==="
        echo "Total: $(get_total_memory_gb) GB"
        free -h
        echo ""

        echo "=== Disk ==="
        echo "Root size: $(get_root_disk_size)"
        df -h /
        echo ""
        lsblk
        echo ""

        echo "=== Hardware ==="
        echo "Manufacturer: $(detect_manufacturer)"
        echo "Product: $(detect_product_name)"
        echo "Laptop: $(is_laptop && echo "Yes" || echo "No")"
        echo "Virtual Machine: $(is_virtual_machine && echo "Yes" || echo "No")"
        echo ""

        echo "=== Secure Boot ==="
        echo "State: $(detect_secure_boot)"
        echo ""

        echo "=== TPM ==="
        if has_tpm; then
            echo "Present: Yes"
            if command -v tpm2_getcap >/dev/null 2>&1; then
                echo "Version:"
                sudo tpm2_getcap properties-fixed 2>/dev/null | grep -E "TPM2_PT_FAMILY|TPM2_PT_VENDOR" || true
            fi
        else
            echo "Present: No"
        fi
        echo ""

        echo "=== Network ==="
        ip -br addr
        echo ""

        echo "=== GPU ==="
        if command -v lspci >/dev/null 2>&1; then
            lspci | grep -i "vga\|3d\|display" || echo "None detected"
        else
            echo "lspci not available"
        fi
        echo ""

    } > "$snapshot_file"

    log_success "System snapshot saved: $snapshot_file"
    report_add "PASS" "System snapshot created"
}

# Apt hygiene
apt_hygiene() {
    log_step "B. APT Hygiene"

    if (( DRY_RUN == 1 )); then
        log_info "[DRY RUN] Would: apt update, upgrade, autoremove"
        report_add "PASS" "APT hygiene (dry-run)"
        return 0
    fi

    apt_update
    apt_upgrade
    apt_autoremove

    # Enable Ubuntu security updates
    if [[ -f /etc/apt/apt.conf.d/50unattended-upgrades ]]; then
        log_info "Unattended-upgrades already configured"
    else
        apt_install unattended-upgrades
        sudo dpkg-reconfigure -plow unattended-upgrades
    fi

    log_success "APT hygiene complete"
    report_add "PASS" "APT updated and cleaned"
}

# Firmware updates
firmware_updates() {
    log_step "C. Firmware Updates"

    if (( DRY_RUN == 1 )); then
        log_info "[DRY RUN] Would: install fwupd, run fwupdmgr refresh/get-updates/update"
        report_add "PASS" "Firmware updates (dry-run)"
        return 0
    fi

    apt_install fwupd

    log_info "Refreshing firmware metadata..."
    if sudo fwupdmgr refresh --force 2>/dev/null; then
        log_success "Firmware metadata refreshed"
    else
        log_warning "Firmware refresh failed (may not be supported)"
    fi

    log_info "Checking for firmware updates..."
    if sudo fwupdmgr get-updates 2>/dev/null; then
        log_warning "Firmware updates available - review and apply manually with: sudo fwupdmgr update"
        report_add "WARN" "Firmware updates available (manual review recommended)"
    else
        log_success "No firmware updates available"
        report_add "PASS" "Firmware up to date"
    fi
}

# Microcode
install_microcode() {
    log_step "D. CPU Microcode"

    local vendor
    vendor="$(detect_cpu_vendor)"

    case "$vendor" in
        AuthenticAMD)
            log_info "AMD CPU detected, installing amd64-microcode"
            if (( DRY_RUN == 1 )); then
                log_info "[DRY RUN] Would install: amd64-microcode"
            else
                apt_install amd64-microcode
            fi
            report_add "PASS" "AMD microcode installed"
            ;;
        GenuineIntel)
            log_info "Intel CPU detected, installing intel-microcode"
            if (( DRY_RUN == 1 )); then
                log_info "[DRY RUN] Would install: intel-microcode"
            else
                apt_install intel-microcode
            fi
            report_add "PASS" "Intel microcode installed"
            ;;
        *)
            log_warning "Unknown CPU vendor: $vendor (skipping microcode)"
            report_add "WARN" "Unknown CPU vendor, microcode not installed"
            ;;
    esac
}

# Drivers
install_drivers() {
    log_step "E. Drivers"

    if (( DRY_RUN == 1 )); then
        log_info "[DRY RUN] Would install: linux-firmware"
        if has_nvidia_gpu; then
            log_info "[DRY RUN] NVIDIA GPU detected, would check ubuntu-drivers"
        fi
        report_add "PASS" "Drivers (dry-run)"
        return 0
    fi

    # Always install linux-firmware
    apt_install linux-firmware

    # Only handle NVIDIA explicitly (AMD iGPU uses open-source drivers)
    if has_nvidia_gpu; then
        log_info "NVIDIA GPU detected"
        log_info "Checking available drivers..."

        if ! command -v ubuntu-drivers >/dev/null 2>&1; then
            apt_install ubuntu-drivers-common
        fi

        sudo ubuntu-drivers devices || true
        log_warning "NVIDIA GPU detected - review drivers above and install manually if needed"
        report_add "WARN" "NVIDIA GPU present (manual driver installation recommended)"
    elif has_amd_gpu; then
        log_success "AMD GPU detected (using open-source drivers)"
        report_add "PASS" "AMD GPU drivers (built-in)"
    elif has_intel_gpu; then
        log_success "Intel GPU detected (using open-source drivers)"
        report_add "PASS" "Intel GPU drivers (built-in)"
    else
        log_info "No discrete GPU detected"
        report_add "PASS" "GPU drivers (built-in)"
    fi
}

# Power management
setup_power_management() {
    log_step "F. Power Management"

    if ! is_laptop; then
        log_info "Not a laptop, skipping power management"
        report_add "PASS" "Power management (not a laptop)"
        return 0
    fi

    log_info "Laptop detected"

    # Use Ubuntu's default power-profiles-daemon
    if systemctl is-active --quiet power-profiles-daemon 2>/dev/null; then
        log_success "power-profiles-daemon is active"
        report_add "PASS" "Power profiles daemon active"
    else
        log_info "power-profiles-daemon not running (may not be installed)"
        if (( DRY_RUN == 0 )); then
            apt_install power-profiles-daemon || log_warning "Could not install power-profiles-daemon"
        fi
    fi

    # Document TLP as optional alternative (disabled by default)
    log_info "NOTE: TLP is available as an alternative (conflicts with power-profiles-daemon)"
    log_info "To use TLP: sudo apt install tlp tlp-rdw && sudo systemctl mask power-profiles-daemon"

    # Battery charge threshold helper (ThinkPad)
    local manufacturer
    manufacturer="$(detect_manufacturer)"
    if [[ "$manufacturer" == *"LENOVO"* ]] || [[ "$manufacturer" == *"Lenovo"* ]]; then
        if [[ -f /sys/class/power_supply/BAT*/charge_control_end_threshold ]]; then
            log_info "Battery charge threshold supported"
            log_info "To set 80% threshold: echo 80 | sudo tee /sys/class/power_supply/BAT*/charge_control_end_threshold"
            report_add "PASS" "Battery charge threshold available"
        fi
    fi
}

# Security baseline
security_baseline() {
    log_step "G. Security Baseline"

    if (( DRY_RUN == 1 )); then
        log_info "[DRY RUN] Would: enable ufw, configure unattended-upgrades, check apparmor"
        report_add "PASS" "Security baseline (dry-run)"
        return 0
    fi

    # UFW firewall
    apt_install ufw

    # Check if SSH is installed and running
    local allow_ssh=0
    if systemctl is-active --quiet sshd 2>/dev/null || systemctl is-active --quiet ssh 2>/dev/null; then
        if confirm "SSH is active. Allow SSH through firewall?"; then
            allow_ssh=1
        fi
    fi

    if (( allow_ssh == 1 )); then
        sudo ufw allow OpenSSH
        log_success "UFW: OpenSSH allowed"
    fi

    sudo ufw --force enable
    log_success "UFW enabled"
    report_add "PASS" "UFW firewall enabled"

    # Unattended upgrades (already done in apt_hygiene, just verify)
    if systemctl is-enabled --quiet unattended-upgrades 2>/dev/null; then
        log_success "Unattended-upgrades enabled"
        report_add "PASS" "Unattended upgrades configured"
    fi

    # AppArmor check
    if command -v aa-status >/dev/null 2>&1; then
        log_info "AppArmor status:"
        sudo aa-status --enabled && log_success "AppArmor is enabled" || log_warning "AppArmor is not enabled"
        report_add "PASS" "AppArmor checked"
    fi
}

# Dev profile extras
dev_profile_extras() {
    log_step "H. Developer Tools (dev profile)"

    if [[ "$PROFILE" != "dev" ]]; then
        log_info "Skipping (profile: $PROFILE)"
        return 0
    fi

    if (( DRY_RUN == 1 )); then
        log_info "[DRY RUN] Would install: build-essential, git, curl, python3-venv, nodejs, npm"
        report_add "PASS" "Dev tools (dry-run)"
        return 0
    fi

    # Core development packages
    apt_install build-essential git curl ca-certificates wget

    # Python development
    apt_install python3-pip python3-venv python3-dev pipx

    # Node.js (Ubuntu default version)
    apt_install nodejs npm

    # Additional useful tools
    apt_install jq vim-nox tmux htop tree

    log_success "Developer tools installed"
    report_add "PASS" "Developer tools installed"

    # Document Docker as optional
    log_info ""
    log_info "OPTIONAL: Docker installation"
    log_info "To install Docker (official repository):"
    log_info "  See: https://docs.docker.com/engine/install/ubuntu/"
    log_info "  Or use: scripts/dev-modules/docker.sh"
}

# Secure profile extras
secure_profile_extras() {
    log_step "I. Security Hardening (secure profile)"

    if [[ "$PROFILE" != "secure" ]]; then
        log_info "Skipping (profile: $PROFILE)"
        return 0
    fi

    if (( DRY_RUN == 1 )); then
        log_info "[DRY RUN] Would install: fail2ban, auditd"
        report_add "PASS" "Security hardening (dry-run)"
        return 0
    fi

    # fail2ban
    if confirm "Install fail2ban (bruteforce protection)?"; then
        apt_install fail2ban
        sudo systemctl enable fail2ban
        sudo systemctl start fail2ban
        log_success "fail2ban installed and enabled"
        report_add "PASS" "fail2ban enabled"
    fi

    # auditd
    if confirm "Install auditd (system auditing)?"; then
        apt_install auditd audispd-plugins
        sudo systemctl enable auditd
        sudo systemctl start auditd
        log_success "auditd installed and enabled"
        report_add "PASS" "auditd enabled"
    fi

    # Backup solution (optional)
    log_info ""
    log_info "OPTIONAL: Backup solution"
    log_info "Consider installing Timeshift (GUI) or restic (CLI)"
    log_info "  Timeshift: scripts/optional-features/timeshift.sh"
    log_info "  restic: https://restic.net/"

    # Document sysctl hardening
    log_info ""
    log_info "OPTIONAL: sysctl hardening"
    log_info "Sysctl hardening can be applied via /etc/sysctl.d/ drop-in files"
    log_info "Review carefully to avoid breaking development workflows"
}

# Verification summary
verification_summary() {
    log_step "J. Verification Summary"

    # Check pending updates
    local updates
    updates=$(apt-get -s upgrade 2>/dev/null | grep -c "^Inst" || true)
    if [[ -z "$updates" || ! "$updates" =~ ^[0-9]+$ ]]; then
        updates=0
    fi
    if (( updates > 0 )); then
        report_add "WARN" "$updates packages have pending updates"
    else
        report_add "PASS" "No pending package updates"
    fi

    # Check services
    local services=("ufw" "unattended-upgrades")
    for svc in "${services[@]}"; do
        if systemctl is-active --quiet "$svc" 2>/dev/null; then
            report_add "PASS" "Service $svc is active"
        else
            report_add "WARN" "Service $svc is not active"
        fi
    done

    # Print summary
    report_summary "BOOTSTRAP RESULT"

    # Write reports
    report_write_json "$LOG_DIR/report.json"
    report_write_text "$LOG_DIR/report.txt"

    log_info ""
    log_info "Bootstrap complete!"
    log_info "Logs saved to: $LOG_DIR"
    log_info ""
    log_info "Next steps:"
    log_info "  1. Review logs: cat $LOG_DIR/bootstrap.log"
    log_info "  2. Run health check: scripts/checks/bootstrap_check.sh"
    log_info "  3. Reboot if kernel/firmware was updated: sudo reboot"
}

# Main execution
main() {
    parse_args "$@"
    init_logging

    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "  $BOOTSTRAP_FULL_VERSION"
    echo "  Profile: $PROFILE"
    if (( DRY_RUN == 1 )); then
        echo "  Mode: DRY RUN (no system changes)"
    fi
    echo "═══════════════════════════════════════════════════════════"
    echo ""

    if (( DRY_RUN == 1 )); then
        log_info "DRY-RUN MODE: No system changes will be made."
    fi

    if (( DRY_RUN == 0 )) && ! confirm "Continue with bootstrap?"; then
        log_info "Aborted by user"
        exit 0
    fi

    snapshot_system_info
    apt_hygiene
    firmware_updates
    install_microcode
    install_drivers
    setup_power_management
    security_baseline
    dev_profile_extras
    secure_profile_extras
    verification_summary
}

main "$@"
