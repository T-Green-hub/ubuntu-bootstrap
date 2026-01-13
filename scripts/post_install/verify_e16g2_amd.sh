#!/usr/bin/env bash
# ThinkPad E16 Gen2 (AMD) Post-Install — VERIFY Script (deterministic)
# Read-only checks; WARN when sudo -n unavailable; logs RC to bundle

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
LIB_DIR="$REPO_DIR/scripts/lib"

[[ -f "$LIB_DIR/logging.sh" ]] && source "$LIB_DIR/logging.sh"
[[ -f "$LIB_DIR/version.sh" ]] && source "$LIB_DIR/version.sh"

if ! declare -f log_info >/dev/null 2>&1; then
    log_info() { echo "[INFO] $*"; }
    log_success() { echo "[OK] $*"; }
    log_warning() { echo "[WARN] $*"; }
    log_error() { echo "[ERROR] $*" >&2; }
    log_step() { echo ""; echo "> $*"; }
fi

BUNDLE_PATH_FILE="/tmp/post_install_e16g2_amd_bundle_path.txt"
UTC_TS="$(date -u +%Y%m%dT%H%M%SZ)"

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0
VERIFY_RC=0

get_or_create_bundle() {
    if [[ -f "$BUNDLE_PATH_FILE" ]]; then
        local bundle
        bundle="$(cat "$BUNDLE_PATH_FILE")"
        if [[ -d "$bundle" ]]; then
            echo "$bundle"
            return 0
        fi
    fi
    local verify_bundle="$REPO_DIR/proof/post_install_e16g2_amd_verify_$UTC_TS"
    mkdir -p "$verify_bundle/logs"
    echo "$verify_bundle" > "$BUNDLE_PATH_FILE"
    echo "$verify_bundle"
}

test_pass() { echo "  PASS: $1"; ((PASS_COUNT++)) || true; }
test_warn() { echo "  WARN: $1"; ((WARN_COUNT++)) || true; }
test_fail() { echo "  FAIL: $1"; ((FAIL_COUNT++)) || true; }

check_amdgpu() {
    log_step "GPU: amdgpu module"
    if lsmod | grep -q '^amdgpu'; then
        test_pass "amdgpu module loaded"
    else
        test_fail "amdgpu module NOT loaded"
    fi
}

check_fstrim() {
    log_step "Storage: fstrim.timer"
    if systemctl is-enabled fstrim.timer >/dev/null 2>&1; then
        test_pass "fstrim.timer enabled"
    else
        test_fail "fstrim.timer NOT enabled"
    fi
    if systemctl is-active fstrim.timer >/dev/null 2>&1; then
        test_pass "fstrim.timer active"
    else
        test_warn "fstrim.timer not active (may run on schedule)"
    fi
}

check_microcode() {
    log_step "CPU: amd64-microcode"
    if dpkg -s amd64-microcode >/dev/null 2>&1; then
        local version
        version="$(dpkg -s amd64-microcode 2>/dev/null | awk -F': ' '/^Version/ {print $2}')"
        test_pass "amd64-microcode installed (${version:-unknown})"
    else
        test_fail "amd64-microcode NOT installed"
    fi
}

check_ufw() {
    log_step "Security: UFW"
    if ! command -v ufw >/dev/null 2>&1; then
        test_fail "ufw not installed"
        return
    fi
    if ! sudo -n true 2>/dev/null; then
        test_warn "ufw status unavailable (sudo -n failed; run sudo -v)"
        return
    fi
    local ufw_status
    ufw_status="$(sudo -n ufw status 2>/dev/null || echo 'unavailable')"
    if echo "$ufw_status" | grep -q "Status: active"; then
        test_pass "ufw active"
        if echo "$ufw_status" | grep -q "deny (incoming)"; then
            test_pass "ufw default deny incoming"
        else
            test_warn "ufw default incoming not deny"
        fi
        if echo "$ufw_status" | grep -q "allow (outgoing)"; then
            test_pass "ufw default allow outgoing"
        else
            test_warn "ufw default outgoing not allow"
        fi
    elif echo "$ufw_status" | grep -q "Status: inactive"; then
        test_warn "ufw installed but inactive"
    else
        test_warn "ufw status unavailable"
    fi
}

check_apparmor() {
    log_step "Security: AppArmor"
    if systemctl is-active apparmor >/dev/null 2>&1; then
        test_pass "AppArmor active"
    else
        test_warn "AppArmor not active"
    fi
}

check_unattended_upgrades() {
    log_step "Security: unattended-upgrades"
    if dpkg -s unattended-upgrades >/dev/null 2>&1; then
        test_pass "unattended-upgrades installed"
        if systemctl is-enabled unattended-upgrades >/dev/null 2>&1; then
            test_pass "unattended-upgrades enabled"
        else
            test_warn "unattended-upgrades not enabled"
        fi
    else
        test_warn "unattended-upgrades NOT installed"
    fi
}

check_power_profile() {
    log_step "Power: powerprofilesctl"
    if command -v powerprofilesctl >/dev/null 2>&1; then
        local profile
        profile="$(powerprofilesctl get 2>/dev/null || echo 'unknown')"
        if [[ "$profile" != "unknown" ]]; then
            test_pass "Power profile: $profile"
        else
            test_warn "Power profile unavailable"
        fi
    else
        test_warn "powerprofilesctl not installed"
    fi
}

check_scaling_driver() {
    log_step "CPU: scaling driver"
    local driver_file="/sys/devices/system/cpu/cpu0/cpufreq/scaling_driver"
    if [[ -f "$driver_file" ]]; then
        local driver
        driver="$(cat "$driver_file" 2>/dev/null || echo 'unknown')"
        if [[ "$driver" == "amd-pstate-epp" || "$driver" == "amd_pstate" ]]; then
            test_pass "Scaling driver: $driver"
        elif [[ "$driver" == "acpi-cpufreq" ]]; then
            test_warn "Scaling driver: $driver (consider amd-pstate)"
        else
            test_warn "Scaling driver: $driver"
        fi
    else
        test_warn "Scaling driver not available"
    fi
}

check_dev_tools() {
    log_step "Development tools"
    local tools=(git docker python3 pipx)
    local missing=()
    for tool in "${tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            test_pass "$tool present"
        else
            missing+=("$tool")
            test_warn "$tool missing"
        fi
    done
    if (( ${#missing[@]} == 0 )); then
        test_pass "All dev tools present"
    fi
}

check_kernel() {
    log_step "Kernel"
    local running
    running="$(uname -r)"
    test_pass "Running kernel: $running"
    local installed
    installed="$(dpkg -l 2>/dev/null | grep '^ii.*linux-image-[0-9]' | awk '{print $2}' | sort -V | tail -1 | sed 's/linux-image-//' || echo 'unknown')"
    if [[ "$installed" == "unknown" ]]; then
        test_warn "Installed kernel unknown"
    elif [[ "$installed" == "$running" ]]; then
        test_pass "Kernel matches latest installed"
    else
        test_warn "Kernel mismatch: running $running, latest $installed"
    fi
}

write_verify_log() {
    local bundle
    bundle="$(get_or_create_bundle)"
    local log_file="$bundle/logs/verify_$(date -u +%Y%m%dT%H%M%SZ).txt"
    {
        echo "=== NAME=verify_run"
        echo "=== UTC_TS=$(date -u +%Y%m%dT%H%M%SZ)"
        echo "=== CMD=verify_e16g2_amd.sh"
        echo "=== PWD=$(pwd)"
        echo ""
        echo "PASS: $PASS_COUNT"
        echo "WARN: $WARN_COUNT"
        echo "FAIL: $FAIL_COUNT"
        echo ""
        echo "=== RC=$VERIFY_RC"
    } > "$log_file"
    log_info "Verify log: $log_file"
}

generate_summary() {
    echo ""
    echo "==========================================================="
    echo "Verification Summary"
    echo "==========================================================="
    echo "PASS: $PASS_COUNT"
    echo "WARN: $WARN_COUNT"
    echo "FAIL: $FAIL_COUNT"
    echo ""

    if (( FAIL_COUNT > 0 )); then
        VERIFY_RC=1
        echo "STATUS: FAIL"
    elif (( WARN_COUNT > 0 )); then
        VERIFY_RC=0
        echo "STATUS: WARN"
    else
        VERIFY_RC=0
        echo "STATUS: PASS"
    fi

    write_verify_log
    exit $VERIFY_RC
}

main() {
    echo ""
    echo "==========================================================="
    echo "ThinkPad E16 Gen2 (AMD) — Verify"
    echo "==========================================================="
    echo ""

    check_kernel
    check_amdgpu
    check_fstrim
    check_microcode
    check_ufw
    check_apparmor
    check_unattended_upgrades
    check_power_profile
    check_scaling_driver
    check_dev_tools

    generate_summary
}

main "$@"
