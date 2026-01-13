#!/usr/bin/env bash
# Bootstrap Health Checker - Read-only verification
# Checks system health and bootstrap status
# Safe to run repeatedly, requires minimal privileges

set -euo pipefail
IFS=$'\n\t'

# Determine directories
CHECK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_DIR="$(cd "$CHECK_DIR/.." && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

# Source library functions
source "$LIB_DIR/version.sh"
source "$LIB_DIR/logging.sh"
source "$LIB_DIR/privileged.sh"
source "$LIB_DIR/detection.sh"
source "$LIB_DIR/report.sh"

# Configuration
OUTPUT_DIR="${OUTPUT_DIR:-$HOME/bootstrap-checks}"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
JSON_ONLY=0
DEBUG=0
DOCTOR=0
BUNDLE=0

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --output-dir)
                OUTPUT_DIR="$2"
                shift 2
                ;;
            --json)
                JSON_ONLY=1
                shift
                ;;
            --debug)
                DEBUG=1
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
            --version|-v)
                echo "$BOOTSTRAP_FULL_VERSION (Health Checker)" && exit 0
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
}

show_help() {
    cat <<EOF
$BOOTSTRAP_FULL_VERSION (Health Checker)

USAGE:
    $0 [OPTIONS]

OPTIONS:
    --output-dir <path>   Output directory for reports (default: \$HOME/bootstrap-checks)
    --json                Only output JSON, suppress human-readable output
    --debug               Enable debug output with extended diagnostics
    --doctor              Run extended checks with fix commands (alias for extended mode)
    --bundle              Create tar.gz archive of output directory
    --version, -v         Show version and exit
    --help, -h            Show this help

DESCRIPTION:
    Performs read-only checks of system health and bootstrap status.
    Checks include:
    - Pending package updates
    - Firmware tooling and updates
    - Secure Boot state
    - TPM presence
    - Disk SMART health
    - Journal errors
    - Firewall posture (ufw)
    - Unattended-upgrades status
    - Power profiles
    - Battery charge-threshold support
    - Temperature sensors
    - Disk space and memory usage

    In --doctor mode, additional extended checks are performed and
    fix commands are printed (but not executed).

EXAMPLES:
    $0
    $0 --output-dir /tmp/health-checks
    $0 --doctor --bundle
    $0 --json > report.json

EOF
}

# Initialize
init_checker() {
    mkdir -p "$OUTPUT_DIR"
    log_info "Bootstrap health check started"
    log_info "Output directory: $OUTPUT_DIR"
}

# Check: Pending updates
check_pending_updates() {
    log_step "Checking for pending updates..."

    local updates
    updates=$(apt-get -s upgrade 2>/dev/null | grep -c "^Inst" || true)
    if [[ -z "$updates" || ! "$updates" =~ ^[0-9]+$ ]]; then
        updates=0
    fi

    if (( updates == 0 )); then
        log_success "No pending package updates"
        report_add "PASS" "No pending updates"
    elif (( updates < 10 )); then
        log_warning "$updates packages have pending updates"
        report_add "WARN" "$updates pending updates"
    else
        log_warning "$updates packages have pending updates (consider running: sudo apt upgrade)"
        report_add "WARN" "$updates pending updates"
    fi
}

# Check: Firmware updates
check_firmware_updates() {
    log_step "Checking for firmware updates..."

    if ! command -v fwupdmgr >/dev/null 2>&1; then
        log_warning "fwupd not installed"
        log_info "    To install: sudo apt install fwupd"
        report_add "WARN" "fwupd not installed"
        return 0
    fi

    # Summarize detected devices (read-only)
    local fw_devices
    fw_devices=$(fwupdmgr get-devices 2>/dev/null | grep -E "^Name|^Device ID" | head -6 || true)
    if [[ -n "$fw_devices" ]]; then
        log_info "Detected firmware-capable devices:"
        echo "$fw_devices" | while read -r line; do
            log_info "    $line"
        done
    else
        log_info "fwupdmgr get-devices requires elevated privileges (skipped)"
    fi

    # Try without sudo first
    local fw_output
    fw_output=$(fwupdmgr get-updates 2>&1 || true)

    if [[ "$fw_output" == *"requires authentication"* ]] || [[ "$fw_output" == *"Permission denied"* ]]; then
        log_info "Firmware check requires elevated privileges"
        log_info "    To check manually: sudo fwupdmgr get-updates"
        report_add "PASS" "Firmware check requires sudo (skipped)"
    elif echo "$fw_output" | grep -q "No updatable devices"; then
        log_success "No firmware updates available"
        report_add "PASS" "Firmware up to date"
    else
        local fw_count
        fw_count=$(echo "$fw_output" | grep -c "Update Version" || echo "0")
        if (( fw_count > 0 )); then
            log_warning "$fw_count firmware update(s) may be available"
            log_info "    To review: sudo fwupdmgr get-updates"
            report_add "WARN" "$fw_count firmware updates may be available"
        else
            log_success "No firmware updates available"
            report_add "PASS" "Firmware up to date"
        fi
    fi
}

# Check: Secure Boot
check_secure_boot() {
    log_step "Checking Secure Boot status..."

    local sb_state
    sb_state="$(detect_secure_boot)"

    case "$sb_state" in
        enabled)
            log_success "Secure Boot: enabled"
            report_add "PASS" "Secure Boot enabled"
            ;;
        disabled)
            log_info "Secure Boot: disabled"
            report_add "PASS" "Secure Boot disabled"
            ;;
        *)
            log_info "Secure Boot: unknown (mokutil not available)"
            report_add "PASS" "Secure Boot status unknown"
            ;;
    esac
}

# Check: TPM
check_tpm() {
    log_step "Checking TPM..."

    if has_tpm; then
        log_success "TPM detected"

        if command -v tpm2_getcap >/dev/null 2>&1; then
            log_info "TPM version:"
            if privileged_allowed; then
                run_privileged tpm2_getcap properties-fixed 2>/dev/null | grep -E "TPM2_PT_FAMILY|TPM2_PT_VENDOR" || true
            else
                log_info "TPM details require sudo (skipped)"
                report_add "PASS" "TPM check requires sudo (skipped)"
            fi
        fi

        report_add "PASS" "TPM present"
    else
        log_info "No TPM detected"
        report_add "PASS" "No TPM"
    fi
}

# Check: Disk SMART health
check_smart_health() {
    log_step "Checking disk SMART health..."

    if ! command -v smartctl >/dev/null 2>&1; then
        log_warning "smartmontools not installed"
        log_info "    To install: sudo apt install smartmontools"
        report_add "WARN" "smartmontools not installed"
        return 0
    fi

    # Find root disk
    local root_disk
    root_disk=$(lsblk -no PKNAME $(findmnt -no SOURCE /) 2>/dev/null | head -n1 || echo "")

    if [[ -z "$root_disk" ]]; then
        # Fallback
        root_disk=$(lsblk -no NAME,TYPE | awk '$2=="disk" {print $1; exit}')
    fi

    if [[ -z "$root_disk" ]]; then
        log_warning "Could not determine root disk"
        report_add "WARN" "Root disk not determined"
        return 0
    fi

    local disk_path="/dev/$root_disk"
    log_info "Checking: $disk_path"
    log_info "    Manual check: sudo smartctl -H $disk_path"

    # Note: SMART queries typically require sudo, so we skip automatic check
    log_info "SMART health check requires elevated privileges (skipped)"
    report_add "PASS" "SMART check requires sudo (skipped)"
}

# Check: Journal errors
check_journal_errors() {
    log_step "Checking system journal for errors..."

    if ! command -v journalctl >/dev/null 2>&1; then
        log_warning "journalctl not available"
        report_add "WARN" "journalctl not available"
        return 0
    fi

    # Try without sudo first (works for user's own logs)
    local error_output
    error_output=$(journalctl -b --priority=3 --no-pager 2>&1 || true)

    if [[ "$error_output" == *"requires authentication"* ]] || [[ "$error_output" == *"Permission denied"* ]]; then
        log_info "Full journal requires elevated privileges"
        log_info "    To check manually: sudo journalctl -b --priority=3"
        report_add "PASS" "Journal check requires sudo (skipped)"
        return 0
    fi

    # Dedupe and get top 10 unique error messages
    local unique_errors
    unique_errors=$(echo "$error_output" | grep -E "^[A-Z]" | sort | uniq -c | sort -rn | head -10)

    local error_count
    error_count=$(echo "$error_output" | grep -cE "^[A-Z]" || echo "0")

    if (( error_count == 0 )); then
        log_success "No errors in journal (current boot, priority ≤3)"
        report_add "PASS" "No journal errors"
    else
        log_warning "$error_count error/warning entries (priority ≤3, current boot)"
        log_info "Top 10 unique messages:"
        echo "$unique_errors" | head -3 | while read -r line; do
            log_info "    $line"
        done
        log_info "    To review all: journalctl -b --priority=3"
        report_add "WARN" "$error_count journal errors/warnings"
    fi
}

# Check: Core services
check_core_services() {
    log_step "Checking core services..."

    local services=("ufw" "unattended-upgrades")

    for svc in "${services[@]}"; do
        if systemctl is-active --quiet "$svc" 2>/dev/null; then
            log_success "Service $svc: active"
            report_add "PASS" "$svc active"
        else
            if systemctl is-enabled --quiet "$svc" 2>/dev/null; then
                log_warning "Service $svc: enabled but not active"
                report_add "WARN" "$svc enabled but not active"
            else
                log_warning "Service $svc: not active or not installed"
                report_add "WARN" "$svc not active"
            fi
        fi
    done
}

# Check: Firewall posture (ufw)
check_firewall_status() {
    log_step "Checking firewall status (ufw)..."

    if ! command -v ufw >/dev/null 2>&1; then
        log_warning "ufw not installed"
        report_add "WARN" "ufw not installed"
        return 0
    fi

    local ufw_output
    ufw_output=$(ufw status verbose 2>&1 || true)

    if echo "$ufw_output" | grep -qi "not run as root"; then
        log_info "ufw status requires elevated privileges"
        log_info "    To check manually: sudo ufw status verbose"
        report_add "PASS" "ufw status requires sudo (skipped)"
        return 0
    fi

    if echo "$ufw_output" | grep -q "Status: active"; then
        local defaults
        defaults=$(echo "$ufw_output" | grep -i "Default:" | head -1 | sed 's/Default:\s*//I')
        log_success "ufw active${defaults:+ ($defaults)}"
        report_add "PASS" "ufw active${defaults:+, $defaults}"
    elif echo "$ufw_output" | grep -q "Status: inactive"; then
        log_warning "ufw inactive"
        log_info "    To enable default deny incoming/allow outgoing: sudo ufw enable"
        report_add "WARN" "ufw inactive"
    else
        log_warning "ufw status unknown"
        log_info "    Output: $(echo "$ufw_output" | head -2 | tr '\n' ' ')"
        report_add "WARN" "ufw status unknown"
    fi
}

# Check: Unattended upgrades
check_unattended_upgrades_status() {
    log_step "Checking unattended-upgrades service..."

    if ! systemctl list-unit-files unattended-upgrades.service >/dev/null 2>&1; then
        log_warning "unattended-upgrades service not present"
        report_add "WARN" "unattended-upgrades service missing"
        return 0
    fi

    if systemctl is-active --quiet unattended-upgrades 2>/dev/null; then
        log_success "unattended-upgrades active (logs: /var/log/unattended-upgrades/)"
        report_add "PASS" "unattended-upgrades active"
    elif systemctl is-enabled --quiet unattended-upgrades 2>/dev/null; then
        log_warning "unattended-upgrades enabled but not active"
        report_add "WARN" "unattended-upgrades enabled but not active"
    else
        log_warning "unattended-upgrades not active"
        report_add "WARN" "unattended-upgrades inactive"
    fi

    log_info "    To review logs: sudo tail -n 50 /var/log/unattended-upgrades/unattended-upgrades.log"
}

# Check: Power profiles
check_power_profiles() {
    log_step "Checking power profiles..."

    if ! command -v powerprofilesctl >/dev/null 2>&1; then
        log_warning "powerprofilesctl not installed (power-profiles-daemon)"
        report_add "WARN" "powerprofilesctl missing"
        return 0
    fi

    local current_profile
    current_profile=$(powerprofilesctl get 2>/dev/null || true)

    if [[ -n "$current_profile" ]]; then
        log_success "Current power profile: $current_profile"
        report_add "PASS" "Power profile: $current_profile"
    else
        log_warning "Unable to read current power profile"
        report_add "WARN" "Power profile unreadable"
    fi

    local available_profiles
    available_profiles=$(powerprofilesctl list 2>/dev/null | grep -E "performance|balanced|power-saver" | sed 's/^\s*//')
    if [[ -n "$available_profiles" ]]; then
        log_info "Available profiles:"
        echo "$available_profiles" | while read -r line; do
            log_info "    $line"
        done
    fi
}

# Check: Battery charge thresholds support
check_battery_threshold() {
    log_step "Checking battery charge threshold support..."

    local threshold_paths
    threshold_paths=$(ls /sys/class/power_supply/BAT*/charge_control_end_threshold 2>/dev/null || true)

    if [[ -z "$threshold_paths" ]]; then
        log_info "Charge-control thresholds not exposed (may be unsupported on this system)"
        report_add "PASS" "Charge thresholds not exposed"
        return 0
    fi

    while read -r path; do
        [[ -z "$path" ]] && continue
        local current
        current=$(cat "$path" 2>/dev/null || echo "unknown")
        log_success "Threshold supported at $path (current: $current%)"
        log_info "    To set safely (example 80%): echo 80 | sudo tee $path"
        report_add "PASS" "Battery threshold supported ($current%)"
    done <<< "$threshold_paths"
}

# Check: Temperature sensors
check_temperature() {
    log_step "Checking temperature sensors..."

    if ! command -v sensors >/dev/null 2>&1; then
        log_info "lm-sensors not installed (optional)"
        report_add "PASS" "Sensors not installed (optional)"
        return 0
    fi

    local temp_output
    temp_output=$(sensors 2>/dev/null || echo "")

    if [[ -z "$temp_output" ]]; then
        log_info "No sensors detected"
        report_add "PASS" "No sensors"
    else
        log_success "Temperature sensors available"
        # Check for high temps (>80°C warning, >90°C critical)
        if echo "$temp_output" | grep -qE "\+[0-9]{3}\.[0-9]°C"; then
            log_warning "High temperature detected (>100°C)"
            report_add "WARN" "High temperature detected"
        elif echo "$temp_output" | grep -qE "\+9[0-9]\.[0-9]°C"; then
            log_warning "Elevated temperature detected (>90°C)"
            report_add "WARN" "Elevated temperature"
        else
            report_add "PASS" "Temperature normal"
        fi
    fi
}

# Check: Disk space
check_disk_space() {
    log_step "Checking disk space..."

    # Get usage% and calculate free GB
    local df_output usage used_gb avail_gb
    df_output=$(df -BG / | awk 'NR==2 {print $3, $4, $5}')
    used_gb=$(echo "$df_output" | awk '{print $1}' | tr -d 'G')
    avail_gb=$(echo "$df_output" | awk '{print $2}' | tr -d 'G')
    usage=$(echo "$df_output" | awk '{print $3}' | tr -d '%')

    # Thresholds: PASS < 80%, WARN 80-90%, FAIL > 90%
    if (( usage < 80 )); then
        log_success "Disk usage: ${usage}% (${used_gb}G used, ${avail_gb}G free)"
        report_add "PASS" "Disk space OK (${usage}%, ${avail_gb}G free)"
    elif (( usage < 90 )); then
        log_warning "Disk usage: ${usage}% (${used_gb}G used, ${avail_gb}G free)"
        report_add "WARN" "Disk usage ${usage}% (${avail_gb}G free)"
    else
        log_error "Disk usage: ${usage}% (${used_gb}G used, ${avail_gb}G free - cleanup needed)"
        report_add "FAIL" "High disk usage ${usage}% (${avail_gb}G free)"
    fi
}

# Check: Memory
check_memory() {
    log_step "Checking memory..."

    if [[ -r /proc/meminfo ]]; then
        local mem_total mem_available mem_usage_pct
        mem_total=$(grep "MemTotal" /proc/meminfo | awk '{print $2}')
        mem_available=$(grep "MemAvailable" /proc/meminfo | awk '{print $2}')
        mem_usage_pct=$(( (mem_total - mem_available) * 100 / mem_total ))

        if (( mem_usage_pct < 80 )); then
            log_success "Memory usage: ${mem_usage_pct}%"
            report_add "PASS" "Memory OK (${mem_usage_pct}%)"
        else
            log_warning "Memory usage: ${mem_usage_pct}%"
            report_add "WARN" "High memory usage ${mem_usage_pct}%"
        fi
    else
        log_warning "Cannot read /proc/meminfo"
        report_add "WARN" "Cannot check memory"
    fi
}

# Doctor mode extended checks
run_doctor_checks() {
    if (( DOCTOR == 0 )); then
        return 0
    fi

    log_step "Running doctor extended checks..."

    # Check for held packages
    local held
    held=$(dpkg -l | grep -c "^hi" || true)
    if (( held > 0 )); then
        log_warning "$held packages are on hold"
        log_info "    Fix: Review with: dpkg -l | grep '^hi'"
        report_add "WARN" "$held packages on hold"
    else
        log_success "No held packages"
        report_add "PASS" "No held packages"
    fi

    # Check for broken dependencies
    local broken_deps
    broken_deps=$(apt-get check 2>&1 | grep -c "broken" || true)
    if (( broken_deps > 0 )); then
        log_warning "Broken dependencies detected"
        log_info "    Fix: sudo apt --fix-broken install"
        report_add "WARN" "Broken dependencies"
    else
        log_success "No broken dependencies"
        report_add "PASS" "No broken dependencies"
    fi

    # Check kernel version vs running
    local installed_kernel running_kernel
    installed_kernel=$(dpkg -l | grep "^ii.*linux-image-[0-9]" | awk '{print $2}' | sort -V | tail -1 | sed 's/linux-image-//')
    running_kernel=$(uname -r)
    if [[ "$installed_kernel" != "$running_kernel" ]]; then
        log_warning "Kernel mismatch: running $running_kernel, installed $installed_kernel"
        log_info "    Fix: Reboot to activate new kernel"
        report_add "WARN" "Kernel reboot needed"
    else
        log_success "Kernel up to date: $running_kernel"
        report_add "PASS" "Kernel current"
    fi

    # Check systemd failed units
    local failed_units
    failed_units=$(systemctl list-units --failed --no-pager --no-legend | wc -l)
    if (( failed_units > 0 )); then
        log_warning "$failed_units failed systemd units"
        log_info "    Fix: Review with: systemctl list-units --failed"
        report_add "WARN" "$failed_units failed systemd units"
    else
        log_success "No failed systemd units"
        report_add "PASS" "No failed units"
    fi
}

# Create bundle
create_bundle() {
    if (( BUNDLE == 0 )); then
        return 0
    fi

    log_step "Creating bundle..."
    local bundle_path="${OUTPUT_DIR}.tar.gz"

    if tar -czf "$bundle_path" -C "$(dirname "$OUTPUT_DIR")" "$(basename "$OUTPUT_DIR")" 2>/dev/null; then
        log_success "Bundle created: $bundle_path"
        log_info "    Size: $(du -h "$bundle_path" | cut -f1)"
    else
        log_warning "Failed to create bundle"
    fi
}

# Main execution
main() {
    parse_args "$@"
    init_checker

    if (( DOCTOR == 1 )); then
        echo ""
        echo "═══════════════════════════════════════════════════════════"
        echo "  $BOOTSTRAP_FULL_VERSION (Health Checker - Doctor Mode)"
        echo "═══════════════════════════════════════════════════════════"
        echo ""
    else
        echo ""
        echo "═══════════════════════════════════════════════════════════"
        echo "  $BOOTSTRAP_FULL_VERSION (Health Checker)"
        echo "═══════════════════════════════════════════════════════════"
        echo ""
    fi

    check_pending_updates
    check_firmware_updates
    check_secure_boot
    check_tpm
    check_smart_health
    check_journal_errors
    check_firewall_status
    check_unattended_upgrades_status
    check_power_profiles
    check_battery_threshold
    check_temperature
    check_disk_space
    check_memory

    # Doctor mode extended checks
    run_doctor_checks

    # Summary
    report_summary "HEALTH CHECK RESULT"

    # Write reports
    local json_file="$OUTPUT_DIR/health-check-$TIMESTAMP.json"
    local text_file="$OUTPUT_DIR/health-check-$TIMESTAMP.txt"

    report_write_json "$json_file"
    report_write_text "$text_file"

    if (( JSON_ONLY == 0 )); then
        echo ""
        log_info "Reports saved:"
        log_info "  JSON: $json_file"
        log_info "  Text: $text_file"
    fi

    # Create bundle if requested
    create_bundle
}

main "$@"
