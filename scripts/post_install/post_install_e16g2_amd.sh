#!/usr/bin/env bash
# ThinkPad E16 Gen2 (AMD) Post-Install — AUDIT Script
# Read-only baseline evidence capture
# Part of ubuntu-bootstrap

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
LIB_DIR="$REPO_DIR/scripts/lib"

# Source libraries
[[ -f "$LIB_DIR/logging.sh" ]] && source "$LIB_DIR/logging.sh"
[[ -f "$LIB_DIR/version.sh" ]] && source "$LIB_DIR/version.sh"
[[ -f "$LIB_DIR/report.sh" ]] && source "$LIB_DIR/report.sh"

# Fallback logging
if ! declare -f log_info >/dev/null 2>&1; then
    log_info() { echo "[INFO] $*"; }
    log_success() { echo "[OK] $*"; }
    log_warning() { echo "[WARN] $*"; }
    log_error() { echo "[ERROR] $*" >&2; }
    log_step() { echo ""; echo "▶ $*"; }
fi

# Fallback report functions
if ! declare -f report_add >/dev/null 2>&1; then
    declare -a REPORT_ITEMS=()
    report_add() {
        local status="$1" msg="$2"
        REPORT_ITEMS+=("$status|$msg")
    }
fi

# Constants
UTC_TS="$(date -u +%Y%m%dT%H%M%SZ)"
PROOF_DIR="$REPO_DIR/proof/post_install_e16g2_amd_$UTC_TS"
LOGS_DIR="$PROOF_DIR/logs"
BUNDLE_PATH_FILE="/tmp/post_install_e16g2_amd_bundle_path.txt"

# Check sudo -n availability (non-interactive)
check_sudo() {
    if ! sudo -n true 2>/dev/null; then
        log_error "sudo credentials not cached. Run: sudo -v"
        log_error "Then re-run this script."
        exit 1
    fi
}

# Initialize proof bundle
init_bundle() {
    log_step "Initializing proof bundle..."
    mkdir -p "$LOGS_DIR"
    echo "$PROOF_DIR" > "$BUNDLE_PATH_FILE"
    log_info "Bundle path: $PROOF_DIR"
}

# Run command and capture output with metadata header
run_capture() {
    local name="$1"
    local cmd="$2"
    local output_file="$LOGS_DIR/${name}.txt"
    local rc=0

    {
        echo "# NAME: $name"
        echo "# UTC_TS: $(date -u +%Y%m%dT%H%M%SZ)"
        echo "# CMD: $cmd"
        echo "# PWD: $(pwd)"
        echo "# ---"
        echo ""
    } > "$output_file"

    # Execute and capture
    set +e
    eval "$cmd" >> "$output_file" 2>&1
    rc=$?
    set -e

    echo "" >> "$output_file"
    echo "# RC: $rc" >> "$output_file"

    if (( rc == 0 )); then
        log_info "  ✓ $name"
    else
        log_info "  ○ $name (rc=$rc)"
    fi

    return 0  # Don't fail the script on individual command failures
}

# Section A: System/Kernel
capture_system_kernel() {
    log_step "A) System/Kernel"

    run_capture "system_date" "date -u +%Y%m%dT%H%M%SZ"
    run_capture "system_uname" "uname -a"
    run_capture "system_lsb_release" "lsb_release -a 2>/dev/null || cat /etc/os-release"
    run_capture "system_bootctl" "bootctl status 2>/dev/null || true"
    run_capture "system_secureboot" "mokutil --sb-state 2>/dev/null || true"
    run_capture "system_analyze_time" "systemd-analyze time 2>/dev/null || true"
    run_capture "system_analyze_blame" "systemd-analyze blame 2>/dev/null | head -40"
    run_capture "system_journal_warnings" "journalctl -b -p warning --no-pager 2>/dev/null | tail -200"
}

# Section B: CPU/GPU/Power (AMD specifics)
capture_cpu_gpu_power() {
    log_step "B) CPU/GPU/Power (AMD)"

    run_capture "cpu_lscpu" "lscpu"
    run_capture "cpu_amd_pstate_status" "grep . /sys/devices/system/cpu/amd_pstate/status 2>/dev/null || echo 'amd_pstate status not available'"
    run_capture "cpu_scaling_driver" "cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver 2>/dev/null || echo 'scaling_driver not available'"
    run_capture "cpu_cpupower" "cpupower frequency-info 2>/dev/null || echo 'cpupower not available'"
    run_capture "power_profile_current" "powerprofilesctl get 2>/dev/null || echo 'powerprofilesctl not available'"
    run_capture "power_profiles_daemon" "systemctl status power-profiles-daemon --no-pager 2>/dev/null || echo 'power-profiles-daemon not active'"
    run_capture "kernel_cmdline" "cat /proc/cmdline"
    run_capture "modules_amd" "lsmod | grep -E -i 'amdgpu|kvm_amd|amd_pstate|thinkpad_acpi' || echo 'No AMD-specific modules found'"
    run_capture "dmesg_amd_pstate" "dmesg -T 2>/dev/null | grep -E -i 'amd_pstate|cppc|cpufreq' | tail -200 || echo 'No amd_pstate/cppc/cpufreq messages'"
}

# Section C: Firmware
capture_firmware() {
    log_step "C) Firmware"

    run_capture "fwupd_version" "fwupdmgr --version 2>/dev/null || echo 'fwupdmgr not available'"
    run_capture "fwupd_devices" "fwupdmgr get-devices 2>/dev/null || echo 'fwupdmgr get-devices failed'"
    run_capture "fwupd_updates" "fwupdmgr get-updates 2>/dev/null || echo 'No firmware updates available or fwupdmgr failed'"
    run_capture "fwupd_history" "fwupdmgr get-history 2>/dev/null || echo 'No firmware history'"
}

# Section D: Storage/Trim
capture_storage() {
    log_step "D) Storage/Trim"

    run_capture "storage_lsblk" "lsblk -o NAME,MODEL,SIZE,FSTYPE,FSVER,FSUSE%,MOUNTPOINTS"
    run_capture "storage_findmnt" "findmnt -no OPTIONS /"
    run_capture "storage_fstrim_timer" "sudo -n systemctl status fstrim.timer --no-pager 2>/dev/null || echo 'fstrim.timer status unavailable'"
    run_capture "storage_timers" "sudo -n systemctl list-timers --all 2>/dev/null | grep -E 'fstrim|apt-daily|unattended' || echo 'No matching timers'"
    run_capture "storage_fstrim_unit" "systemctl cat fstrim.timer fstrim.service 2>/dev/null || echo 'fstrim units not found'"
}

# Section E: Memory/Swap/ZRAM/OOM
capture_memory() {
    log_step "E) Memory/Swap/ZRAM/OOM"

    run_capture "memory_free" "free -h"
    run_capture "memory_swap" "swapon --show || echo 'No swap configured'"
    run_capture "memory_zram" "systemctl status 'systemd-zram-setup@*' --no-pager 2>/dev/null || echo 'ZRAM not configured'"
    run_capture "memory_zram_conf" "cat /etc/systemd/zram-generator.conf 2>/dev/null || echo 'No zram-generator.conf'"
    run_capture "memory_oomd" "systemctl status systemd-oomd --no-pager 2>/dev/null || echo 'systemd-oomd not active'"
    run_capture "memory_oomctl" "oomctl 2>/dev/null || echo 'oomctl not available'"
}

# Section F: Networking
capture_networking() {
    log_step "F) Networking"

    run_capture "net_ip" "ip a"
    run_capture "net_nmcli" "nmcli dev status 2>/dev/null || echo 'NetworkManager not available'"
    run_capture "net_resolvectl" "resolvectl status 2>/dev/null | head -80 || echo 'resolvectl not available'"
}

# Section G: Security posture
capture_security() {
    log_step "G) Security Posture"

    run_capture "security_ufw" "sudo -n ufw status verbose 2>/dev/null || echo 'UFW status unavailable'"
    run_capture "security_apparmor_service" "systemctl status apparmor --no-pager 2>/dev/null || echo 'AppArmor service not found'"
    run_capture "security_apparmor_status" "sudo -n aa-status 2>/dev/null | head -60 || echo 'aa-status unavailable'"
    run_capture "security_unattended" "systemctl status unattended-upgrades --no-pager 2>/dev/null || echo 'unattended-upgrades not active'"
    run_capture "security_apt_timers" "sudo -n systemctl list-timers --all 2>/dev/null | grep -E 'apt-daily|unattended' || echo 'No apt/unattended timers'"
}

# Section H: Dev toolchain
capture_devtools() {
    log_step "H) Dev Toolchain Presence"

    run_capture "dev_git" "git --version 2>/dev/null || echo 'git not installed'"
    run_capture "dev_python" "python3 --version 2>/dev/null || echo 'python3 not installed'"
    run_capture "dev_pipx" "pipx --version 2>/dev/null || echo 'pipx not installed'"
    run_capture "dev_node" "node --version 2>/dev/null || echo 'node not installed'"
    run_capture "dev_docker" "docker --version 2>/dev/null || echo 'docker not installed'"
    run_capture "dev_snap" "snap list 2>/dev/null || echo 'snap not available'"
    run_capture "dev_flatpak" "flatpak --version 2>/dev/null || echo 'flatpak not installed'"
}

# Generate analysis report
generate_report() {
    log_step "Generating Analysis Report"

    local report_json="$PROOF_DIR/report.json"
    local report_txt="$PROOF_DIR/report.txt"
    local cert_file="$PROOF_DIR/CERTIFICATION.txt"

    # Gather findings
    local kernel_version uname_output os_name
    kernel_version="$(uname -r)"
    uname_output="$(uname -a)"
    os_name="$(lsb_release -d 2>/dev/null | cut -f2 || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"

    # CPU info
    local cpu_model scaling_driver amd_pstate_status
    cpu_model="$(grep 'model name' /proc/cpuinfo 2>/dev/null | head -1 | cut -d: -f2 | xargs || echo 'unknown')"
    scaling_driver="$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver 2>/dev/null || echo 'unknown')"
    amd_pstate_status="$(cat /sys/devices/system/cpu/amd_pstate/status 2>/dev/null || echo 'not available')"

    # Power profile
    local power_profile ppd_active
    power_profile="$(powerprofilesctl get 2>/dev/null || echo 'unknown')"
    ppd_active="$(systemctl is-active power-profiles-daemon 2>/dev/null || echo 'inactive')"

    # AMDGPU check
    local amdgpu_loaded="false"
    local amdgpu_count
    amdgpu_count="$(lsmod | grep -c '^amdgpu' || true)"
    if (( amdgpu_count > 0 )); then
        amdgpu_loaded="true"
    fi

    # fstrim check
    local fstrim_enabled="false"
    if systemctl is-enabled fstrim.timer 2>/dev/null | grep -q enabled; then
        fstrim_enabled="true"
    fi

    # Microcode check
    local microcode_installed="false"
    if dpkg -s amd64-microcode >/dev/null 2>&1; then
        microcode_installed="true"
    fi

    # UFW check
    local ufw_status
    ufw_status="$(sudo -n ufw status 2>/dev/null | head -1 || echo 'unknown')"

    # AppArmor check
    local apparmor_active="false"
    if systemctl is-active apparmor >/dev/null 2>&1; then
        apparmor_active="true"
    fi

    # Unattended-upgrades check
    local unattended_active="false"
    if systemctl is-active unattended-upgrades >/dev/null 2>&1; then
        unattended_active="true"
    fi

    # Memory info
    local mem_total mem_available
    mem_total="$(free -h | awk '/^Mem:/ {print $2}')"
    mem_available="$(free -h | awk '/^Mem:/ {print $7}')"

    # Dev tools
    local git_ver python_ver docker_ver
    git_ver="$(git --version 2>/dev/null | awk '{print $3}' || echo 'not installed')"
    python_ver="$(python3 --version 2>/dev/null | awk '{print $2}' || echo 'not installed')"
    docker_ver="$(docker --version 2>/dev/null | awk '{print $3}' | tr -d ',' || echo 'not installed')"

    # Determine certification status
    local cert_status="PASS"
    local cert_issues=()

    if [[ "$amdgpu_loaded" != "true" ]]; then
        cert_status="WARN"
        cert_issues+=("amdgpu module not loaded")
    fi

    if [[ "$fstrim_enabled" != "true" ]]; then
        cert_issues+=("fstrim.timer not enabled")
    fi

    if [[ "$microcode_installed" != "true" ]]; then
        cert_issues+=("amd64-microcode not installed")
    fi

    if [[ "$ufw_status" != *"active"* ]]; then
        cert_issues+=("UFW not active")
    fi

    # Write JSON report
    cat > "$report_json" <<EOF
{
  "audit_timestamp": "$UTC_TS",
  "system": {
    "hostname": "$(hostname)",
    "os": "$os_name",
    "kernel": "$kernel_version",
    "uname": "$uname_output"
  },
  "cpu": {
    "model": "$cpu_model",
    "scaling_driver": "$scaling_driver",
    "amd_pstate_status": "$amd_pstate_status"
  },
  "power": {
    "profile": "$power_profile",
    "power_profiles_daemon": "$ppd_active"
  },
  "gpu": {
    "amdgpu_loaded": $amdgpu_loaded
  },
  "storage": {
    "fstrim_enabled": $fstrim_enabled
  },
  "security": {
    "microcode_installed": $microcode_installed,
    "ufw_status": "$ufw_status",
    "apparmor_active": $apparmor_active,
    "unattended_upgrades_active": $unattended_active
  },
  "memory": {
    "total": "$mem_total",
    "available": "$mem_available"
  },
  "dev_tools": {
    "git": "$git_ver",
    "python3": "$python_ver",
    "docker": "$docker_ver"
  },
  "certification": {
    "status": "$cert_status",
    "issues": [$(printf '"%s",' "${cert_issues[@]}" | sed 's/,$//' || echo '')]
  }
}
EOF

    # Write text report
    cat > "$report_txt" <<EOF
═══════════════════════════════════════════════════════════
  ThinkPad E16 Gen2 (AMD) — Audit Report
  Generated: $UTC_TS
═══════════════════════════════════════════════════════════

SYSTEM
  Hostname:     $(hostname)
  OS:           $os_name
  Kernel:       $kernel_version

CPU/POWER
  Model:        $cpu_model
  Scaling:      $scaling_driver
  AMD P-State:  $amd_pstate_status
  Power Profile: $power_profile (daemon: $ppd_active)

GPU
  AMDGPU loaded: $amdgpu_loaded

STORAGE
  TRIM enabled: $fstrim_enabled

SECURITY
  Microcode:    $microcode_installed
  UFW:          $ufw_status
  AppArmor:     $apparmor_active
  Unattended:   $unattended_active

MEMORY
  Total:        $mem_total
  Available:    $mem_available

DEV TOOLS
  Git:          $git_ver
  Python3:      $python_ver
  Docker:       $docker_ver

CERTIFICATION: $cert_status
$(if (( ${#cert_issues[@]} > 0 )); then
    echo "Issues:"
    for issue in "${cert_issues[@]}"; do
        echo "  - $issue"
    done
fi)

Log files: $LOGS_DIR/
═══════════════════════════════════════════════════════════
EOF

    # Write certification
    echo "$cert_status | kernel=$kernel_version | amdgpu=$amdgpu_loaded | fstrim=$fstrim_enabled | ufw=$ufw_status | microcode=$microcode_installed" > "$cert_file"

    log_success "Report generated: $report_txt"
}

# Generate evidence index with SHA256
generate_evidence_index() {
    log_step "Generating Evidence Index"

    local index_file="$PROOF_DIR/evidence_index.txt"

    {
        echo "# Evidence Index — ThinkPad E16 Gen2 (AMD) Audit"
        echo "# Generated: $UTC_TS"
        echo "# Bundle: $PROOF_DIR"
        echo ""
        echo "# SHA256 checksums:"

        find "$PROOF_DIR" -type f ! -name "evidence_index.txt" -exec sha256sum {} \; | \
            sed "s|$PROOF_DIR/||g"
    } > "$index_file"

    log_success "Evidence index: $index_file"
}

# Main
main() {
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "  ThinkPad E16 Gen2 (AMD) — AUDIT (Read-Only)"
    echo "  Ubuntu 24.04 LTS — Evidence Capture"
    echo "═══════════════════════════════════════════════════════════"
    echo ""

    check_sudo
    init_bundle

    capture_system_kernel
    capture_cpu_gpu_power
    capture_firmware
    capture_storage
    capture_memory
    capture_networking
    capture_security
    capture_devtools

    generate_report
    generate_evidence_index

    echo ""
    log_success "Audit complete!"
    log_info "Proof bundle: $PROOF_DIR"
    log_info "Bundle path saved to: $BUNDLE_PATH_FILE"
    echo ""
}

main "$@"
