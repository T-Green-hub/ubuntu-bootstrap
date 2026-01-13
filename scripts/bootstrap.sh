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
INTERACTIVE="${INTERACTIVE:-0}"
PRINT_PLAN="${PRINT_PLAN:-0}"
EXPLAIN="${EXPLAIN:-0}"
DEBUG="${DEBUG:-0}"
TRACE="${TRACE:-0}"
DOCTOR="${DOCTOR:-0}"
BUNDLE="${BUNDLE:-0}"
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
            --interactive)
                INTERACTIVE=1
                shift
                ;;
            --print-plan)
                PRINT_PLAN=1
                DRY_RUN=1
                shift
                ;;
            --explain)
                EXPLAIN=1
                shift
                ;;
            --debug)
                DEBUG=1
                shift
                ;;
            --trace)
                TRACE=1
                shift
                ;;
            --doctor)
                DOCTOR=1
                shift
                ;;
            --bundle)
                BUNDLE=1
                shift
                ;;
            --self-test)
                bash "$SCRIPT_DIR/tests/self_test.sh" "$@"
                exit $?
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
    --interactive       Interactive menu for profile selection
    --print-plan        Show execution plan without running (implies --dry-run)
    --explain           Explain each step in detail
    --debug             Enable debug output and create extended diagnostic files
    --trace             Enable bash tracing (xtrace) to OUTPUT_DIR/trace.log
    --doctor            Run preflight checks and print fix commands (read-only)
    --bundle            Create tar.gz archive of output directory
    --self-test         Run full self-test suite and exit
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
    $0 --interactive
    $0 --profile dev --print-plan
    $0 --doctor --output-dir /tmp/doctor
    $0 --profile minimal --dry-run --debug --trace
    $0 --self-test

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

    # Setup trace if requested
    if (( TRACE == 1 )); then
        TRACE_LOG="$LOG_DIR/trace.log"
        exec {BASH_XTRACEFD}>"$TRACE_LOG"
        export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
        set -x
        log_info "Trace enabled: $TRACE_LOG"
    fi

    log_info "Bootstrap started"
    log_info "Profile: $PROFILE"
    if (( DRY_RUN == 1 )); then
        log_info "DRY-RUN MODE: No system changes will be made."
    fi
    if (( DEBUG == 1 )); then
        log_info "DEBUG MODE: Extended diagnostics enabled"
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

# Interactive mode
interactive_mode() {
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "  Interactive Bootstrap Setup"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    echo "Select a profile:"
    echo "  1) minimal - Safe baseline (updates, firmware, drivers, security)"
    echo "  2) dev     - Minimal + development tools"
    echo "  3) secure  - Minimal + security hardening"
    echo "  4) Cancel"
    echo ""
    read -p "Enter choice [1-4]: " -n 1 -r choice
    echo ""

    case "$choice" in
        1) PROFILE="minimal" ;;
        2) PROFILE="dev" ;;
        3) PROFILE="secure" ;;
        4) echo "Cancelled."; exit 0 ;;
        *) echo "Invalid choice."; exit 1 ;;
    esac

    echo ""
    echo "Profile selected: $PROFILE"
    echo ""
    read -p "Run in dry-run mode (preview only)? [Y/n] " -n 1 -r dry_choice
    echo ""
    if [[ $dry_choice =~ ^[Nn]$ ]]; then
        DRY_RUN=0
    else
        DRY_RUN=1
    fi

    echo ""
    if (( DRY_RUN == 1 )); then
        echo "Mode: DRY RUN (no system changes)"
    else
        echo "Mode: APPLY CHANGES"
    fi
    echo ""
}

# Print plan mode
print_plan() {
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "  Bootstrap Execution Plan (Profile: $PROFILE)"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    echo "The following steps will be executed:"
    echo ""
    echo "A. System Information Snapshot"
    echo "   - Capture OS, kernel, CPU, memory, disk, hardware details"
    echo "   - Save to: system-info.txt"
    echo ""
    echo "B. APT Hygiene"
    echo "   - apt update, upgrade, autoremove"
    echo "   - Configure unattended-upgrades for security updates"
    echo ""
    echo "C. Firmware Updates"
    echo "   - Install fwupd"
    echo "   - Check for firmware updates (manual review recommended)"
    echo ""
    echo "D. CPU Microcode"
    if [[ "$(detect_cpu_vendor)" == "AuthenticAMD" ]]; then
        echo "   - Install amd64-microcode (AMD CPU detected)"
    elif [[ "$(detect_cpu_vendor)" == "GenuineIntel" ]]; then
        echo "   - Install intel-microcode (Intel CPU detected)"
    else
        echo "   - Detect CPU vendor and install appropriate microcode"
    fi
    echo ""
    echo "E. Drivers"
    echo "   - Install linux-firmware"
    if has_nvidia_gpu; then
        echo "   - NVIDIA GPU detected - review available drivers"
    elif has_amd_gpu; then
        echo "   - AMD GPU detected (using built-in open-source drivers)"
    elif has_intel_gpu; then
        echo "   - Intel GPU detected (using built-in open-source drivers)"
    fi
    echo ""
    echo "F. Power Management"
    if is_laptop; then
        echo "   - Install power-profiles-daemon"
        echo "   - Document battery charge threshold (if supported)"
    else
        echo "   - Skip (not a laptop)"
    fi
    echo ""
    echo "G. Security Baseline"
    echo "   - Enable ufw firewall"
    echo "   - Verify unattended-upgrades"
    echo "   - Check AppArmor status"
    echo ""

    if [[ "$PROFILE" == "dev" ]]; then
        echo "H. Developer Tools (dev profile)"
        echo "   - build-essential, git, curl, wget"
        echo "   - Python: python3-pip, python3-venv, pipx"
        echo "   - Node.js: nodejs, npm"
        echo "   - Utilities: jq, vim, tmux, htop, tree"
        echo ""
    fi

    if [[ "$PROFILE" == "secure" ]]; then
        echo "I. Security Hardening (secure profile)"
        echo "   - Optionally install fail2ban"
        echo "   - Optionally install auditd"
        echo "   - Document backup solutions and sysctl hardening"
        echo ""
    fi

    echo "J. Verification Summary"
    echo "   - Check for pending updates"
    echo "   - Verify core services (ufw, unattended-upgrades)"
    echo "   - Generate reports (report.json, report.txt)"
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo ""
}

# Doctor mode - preflight checks
run_doctor_checks() {
    log_step "Running Doctor Checks (Read-Only)"
    echo ""

    # Check sudo access
    if sudo -n true 2>/dev/null; then
        log_success "Sudo access: available (cached)"
    else
        log_info "Sudo access: will be required (not cached)"
    fi

    # Check internet connectivity
    if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
        log_success "Internet: connected"
    else
        log_warning "Internet: not connected or restricted"
        log_info "    Fix: Check network connection"
    fi

    # Check disk space
    local avail_gb
    avail_gb=$(df -BG / | awk 'NR==2 {print $4}' | tr -d 'G')
    if (( avail_gb >= 20 )); then
        log_success "Disk space: ${avail_gb}G available"
    else
        log_warning "Disk space: ${avail_gb}G available (recommend 20G+)"
        log_info "    Fix: Free up disk space with: sudo apt autoremove && sudo apt clean"
    fi

    # Check APT sources
    if apt-get update -qq 2>&1 | grep -qi "error\\|failed"; then
        log_warning "APT sources: errors detected"
        log_info "    Fix: Review with: sudo apt-get update"
    else
        log_success "APT sources: OK"
    fi

    # Check for broken packages
    local broken
    broken=$(dpkg -l | grep -c "^iU\\|^iF" || true)
    if (( broken > 0 )); then
        log_warning "Broken packages: $broken found"
        log_info "    Fix: sudo dpkg --configure -a && sudo apt --fix-broken install"
    else
        log_success "Package integrity: OK"
    fi

    # Save debug artifacts if requested
    if (( DEBUG == 1 )); then
        log_info "Saving debug artifacts..."
        apt-cache policy > "$LOG_DIR/apt-policy.txt" 2>&1 || true
        dpkg -l > "$LOG_DIR/dpkg-audit.txt" 2>&1 || true
        sudo ufw status verbose > "$LOG_DIR/ufw-status.txt" 2>&1 || true
        systemctl status unattended-upgrades > "$LOG_DIR/unattended-status.txt" 2>&1 || true
        fwupdmgr get-devices > "$LOG_DIR/fwupd-devices.txt" 2>&1 || true
        sudo journalctl -b --priority=3 --no-pager | head -100 > "$LOG_DIR/journal-errors-top.txt" 2>&1 || true
        log_success "Debug artifacts saved to $LOG_DIR"
    fi

    echo ""
    log_info "Doctor check complete. System is ready for bootstrap."
}

# Create bundle
create_bundle() {
    if (( BUNDLE == 0 )); then
        return 0
    fi

    log_step "Creating Bundle"
    local bundle_name="bootstrap-$(basename "$LOG_DIR").tar.gz"
    local bundle_path="${LOG_DIR}.tar.gz"

    if tar -czf "$bundle_path" -C "$(dirname "$LOG_DIR")" "$(basename "$LOG_DIR")" 2>/dev/null; then
        log_success "Bundle created: $bundle_path"
        log_info "    Size: $(du -h "$bundle_path" | cut -f1)"
    else
        log_warning "Failed to create bundle"
    fi
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

    # Write reports (always generate these)
    report_write_json "$LOG_DIR/report.json"
    report_write_text "$LOG_DIR/report.txt"

    # Debug artifacts already saved if --debug enabled

    log_info ""
    log_info "Bootstrap complete!"
    log_info "Logs saved to: $LOG_DIR"

    # Create bundle if requested
    create_bundle

    log_info ""
    log_info "Next steps:"
    log_info "  1. Review logs: cat $LOG_DIR/bootstrap.log"
    log_info "  2. Run health check: scripts/checks/bootstrap_check.sh"
    log_info "  3. Reboot if kernel/firmware was updated: sudo reboot"
}

# Main execution
main() {
    parse_args "$@"

    # Handle interactive mode first
    if (( INTERACTIVE == 1 )); then
        interactive_mode
    fi

    # Handle doctor mode
    if (( DOCTOR == 1 )); then
        init_logging
        run_doctor_checks
        exit 0
    fi

    # Handle print-plan mode
    if (( PRINT_PLAN == 1 )); then
        print_plan
        exit 0
    fi

    init_logging

    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "  $BOOTSTRAP_FULL_VERSION"
    echo "  Profile: $PROFILE"
    if (( DRY_RUN == 1 )); then
        echo "  Mode: DRY RUN (no system changes)"
    fi
    if (( DEBUG == 1 )); then
        echo "  Debug: enabled"
    fi
    if (( TRACE == 1 )); then
        echo "  Trace: enabled"
    fi
    echo "═══════════════════════════════════════════════════════════"
    echo ""

    if (( DRY_RUN == 1 )); then
        log_info "DRY-RUN MODE: No system changes will be made."
    fi

    if (( EXPLAIN == 1 )); then
        log_info "EXPLAIN MODE: Detailed explanations will be provided."
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
