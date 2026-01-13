#!/usr/bin/env bash
# Bootstrap Health Checker - Read-only verification
# Checks system health and bootstrap status
# Safe to run repeatedly, requires minimal privileges
# Version: 4.0.0

set -euo pipefail
IFS=$'\n\t'

# Determine directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

# Source library functions
source "$LIB_DIR/logging.sh"
source "$LIB_DIR/detection.sh"
source "$LIB_DIR/report.sh"

# Configuration
OUTPUT_DIR="${OUTPUT_DIR:-$HOME/bootstrap-checks}"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

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
Bootstrap Health Checker v4.0.0

USAGE:
    $0 [OPTIONS]

OPTIONS:
    --output-dir <path>   Output directory for reports (default: \$HOME/bootstrap-checks)
    --json                Only output JSON, suppress human-readable output
    --help, -h            Show this help

DESCRIPTION:
    Performs read-only checks of system health and bootstrap status.
    Checks include:
    - Pending package updates
    - Firmware update availability
    - Secure Boot state
    - TPM presence
    - Disk SMART health
    - Journal errors
    - Service status (ufw, unattended-upgrades)
    - Temperature sensors

EXAMPLES:
    $0
    $0 --output-dir /tmp/health-checks
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
        log_warning "fwupd not installed (install with: sudo apt install fwupd)"
        report_add "WARN" "fwupd not installed"
        return 0
    fi
    
    if sudo fwupdmgr get-updates 2>/dev/null | grep -q "No updatable devices"; then
        log_success "No firmware updates available"
        report_add "PASS" "Firmware up to date"
    else
        local fw_count
        fw_count=$(sudo fwupdmgr get-updates 2>/dev/null | grep -c "Update Version" || echo "0")
        if (( fw_count > 0 )); then
            log_warning "$fw_count firmware update(s) available (review with: sudo fwupdmgr get-updates)"
            report_add "WARN" "$fw_count firmware updates available"
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
            sudo tpm2_getcap properties-fixed 2>/dev/null | grep -E "TPM2_PT_FAMILY|TPM2_PT_VENDOR" || true
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
        log_warning "smartmontools not installed (install with: sudo apt install smartmontools)"
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
    
    if sudo smartctl -H "$disk_path" 2>/dev/null | grep -q "PASSED"; then
        log_success "SMART health: PASSED"
        report_add "PASS" "Disk SMART health OK"
    elif sudo smartctl -H -d nvme "$disk_path" 2>/dev/null | grep -q "PASSED"; then
        log_success "SMART health: PASSED (NVMe)"
        report_add "PASS" "Disk SMART health OK"
    else
        log_warning "SMART health check failed or unsupported"
        report_add "WARN" "SMART check failed/unsupported"
    fi
}

# Check: Journal errors
check_journal_errors() {
    log_step "Checking system journal for errors..."
    
    if ! command -v journalctl >/dev/null 2>&1; then
        log_warning "journalctl not available"
        report_add "WARN" "journalctl not available"
        return 0
    fi
    
    local error_count
    error_count=$(sudo journalctl -b -p err --no-pager 2>/dev/null | grep -c "^[A-Z]" || echo "0")
    
    if (( error_count == 0 )); then
        log_success "No errors in journal (current boot)"
        report_add "PASS" "No journal errors"
    elif (( error_count < 5 )); then
        log_warning "$error_count error(s) in journal (review with: sudo journalctl -b -p err)"
        report_add "WARN" "$error_count journal errors"
    else
        log_warning "$error_count error(s) in journal (review with: sudo journalctl -b -p err)"
        report_add "WARN" "$error_count journal errors"
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
    
    local usage
    usage=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')
    
    if (( usage < 70 )); then
        log_success "Disk usage: ${usage}%"
        report_add "PASS" "Disk space OK (${usage}%)"
    elif (( usage < 85 )); then
        log_warning "Disk usage: ${usage}% (consider cleanup)"
        report_add "WARN" "Disk usage ${usage}%"
    else
        log_warning "Disk usage: ${usage}% (cleanup recommended)"
        report_add "WARN" "High disk usage ${usage}%"
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

# Main execution
main() {
    parse_args "$@"
    init_checker
    
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "  Bootstrap Health Check v4.0.0"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    
    check_pending_updates
    check_firmware_updates
    check_secure_boot
    check_tpm
    check_smart_health
    check_journal_errors
    check_core_services
    check_temperature
    check_disk_space
    check_memory
    
    # Summary
    report_summary "HEALTH CHECK RESULT"
    
    # Write reports
    local json_file="$OUTPUT_DIR/health-check-$TIMESTAMP.json"
    local text_file="$OUTPUT_DIR/health-check-$TIMESTAMP.txt"
    
    report_write_json "$json_file"
    report_write_text "$text_file"
    
    log_info ""
    log_info "Health check complete"
    log_info "Reports saved to: $OUTPUT_DIR"
    
    # Return appropriate exit code
    if (( REPORT_FAIL > 0 )); then
        exit 1
    elif (( REPORT_WARN > 0 )); then
        exit 0
    else
        exit 0
    fi
}

main "$@"
