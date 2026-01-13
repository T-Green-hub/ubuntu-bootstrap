#!/usr/bin/env bash
# ThinkPad E16 Gen2 (AMD) Post-Install — APPLY Script (deterministic bundle)
# Creates isolated apply bundle with rollback, actions, and evidence artifacts.
# Part of ubuntu-bootstrap

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
LIB_DIR="$REPO_DIR/scripts/lib"

[[ -f "$LIB_DIR/logging.sh" ]] && source "$LIB_DIR/logging.sh"
[[ -f "$LIB_DIR/version.sh" ]] && source "$LIB_DIR/version.sh"
[[ -f "$LIB_DIR/report.sh" ]] && source "$LIB_DIR/report.sh"

if ! declare -f log_info >/dev/null 2>&1; then
    log_info() { echo "[INFO] $*"; }
    log_success() { echo "[OK] $*"; }
    log_warning() { echo "[WARN] $*"; }
    log_error() { echo "[ERROR] $*" >&2; }
    log_step() { echo ""; echo "> $*"; }
fi

if ! declare -f report_add >/dev/null 2>&1; then
    declare -a REPORT_ITEMS=()
    REPORT_PASS=0
    REPORT_WARN=0
    REPORT_FAIL=0
    report_add() {
        local status="$1" msg="$2"
        REPORT_ITEMS+=("$status|$msg")
        case "$status" in
            PASS) ((REPORT_PASS++)) || true ;;
            WARN) ((REPORT_WARN++)) || true ;;
            FAIL) ((REPORT_FAIL++)) || true ;;
        esac
    }
fi

UTC_TS="$(date -u +%Y%m%dT%H%M%SZ)"
BUNDLE_PATH_FILE="/tmp/post_install_e16g2_amd_bundle_path.txt"

ENABLE_ZRAM=0
ENABLE_DOCKER_OFFICIAL=0
ENABLE_NODESOURCE=0
ENABLE_VSCODE=0
ENABLE_PROTONVPN=0

declare -a ACTIONS_LOG=()
declare -a INSTALLED_PACKAGES=()

FSTRIM_ENABLED_BEFORE=""
UFW_ENABLED_BEFORE=""
UFW_DEFAULT_IN_BEFORE=""
UFW_DEFAULT_OUT_BEFORE=""
UNATTENDED_PRESENT_BEFORE=""
AMD_MICROCODE_BEFORE=""

FAIL_FLAG=0
FAIL_REASON=""
FINALIZED=0

escape_json() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    echo "$s"
}

run_capture() {
    local name="$1"
    shift
    local output_file="$LOGS_DIR/${name}.txt"

    {
        echo "=== NAME=$name"
        echo "=== UTC_TS=$(date -u +%Y%m%dT%H%M%SZ)"
        printf '=== ARGV='
        printf ' %q' "$@"
        echo
        echo "=== PWD=$(pwd)"
        echo ""
    } > "$output_file"

    set +e
    "$@" >> "$output_file" 2>&1
    local rc=$?
    set -e

    echo "" >> "$output_file"
    echo "=== RC=$rc" >> "$output_file"

    if (( rc == 0 )); then
        log_info "capture [$name]: ok"
    else
        log_info "capture [$name]: rc=$rc"
    fi

    return $rc
}

run_capture_shell() {
    local name="$1" script="$2"
    local output_file="$LOGS_DIR/${name}.txt"

    {
        echo "=== NAME=$name"
        echo "=== UTC_TS=$(date -u +%Y%m%dT%H%M%SZ)"
        echo "=== SHELL=bash -lc"
        echo "=== CMD=$script"
        echo "=== PWD=$(pwd)"
        echo ""
    } > "$output_file"

    set +e
    bash -lc "$script" >> "$output_file" 2>&1
    local rc=$?
    set -e

    echo "" >> "$output_file"
    echo "=== RC=$rc" >> "$output_file"

    if (( rc == 0 )); then
        log_info "capture [$name]: ok"
    else
        log_info "capture [$name]: rc=$rc"
    fi

    return $rc
}

run_must() {
    local name="$1"
    shift
    if run_capture "$name" "$@"; then
        return 0
    else
        local rc=$?
        FAIL_FLAG=1
        FAIL_REASON="$name failed (rc=$rc)"
        report_add "FAIL" "$FAIL_REASON"
        track_action "$name" "failed" "Exit code: $rc"
        exit "$rc"
    fi
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --enable-zram) ENABLE_ZRAM=1; shift ;;
            --enable-docker-official) ENABLE_DOCKER_OFFICIAL=1; shift ;;
            --enable-nodesource) ENABLE_NODESOURCE=1; shift ;;
            --enable-vscode) ENABLE_VSCODE=1; shift ;;
            --enable-protonvpn) ENABLE_PROTONVPN=1; shift ;;
            --help|-h)
                cat <<EOF
ThinkPad E16 Gen2 (AMD) — Apply Baseline

USAGE:
    $0 [OPTIONS]

OPTIONS (all optional, default OFF and currently not implemented):
    --enable-zram
    --enable-docker-official
    --enable-nodesource
    --enable-vscode
    --enable-protonvpn
    --help, -h

Default actions (always applied):
    - Enable fstrim.timer
    - Install amd64-microcode
    - Configure UFW deny-in/allow-out and enable
    - Ensure unattended-upgrades is installed
    - Install dev tools (build-essential, git, curl, wget, ca-certificates, python3-pip, python3-venv, pipx, docker.io, wireguard-tools)

Outputs:
    proof/post_install_e16g2_amd_apply_<UTC>/ with logs, decisions, apply report, rollback, prior_state, installed_packages, certification, evidence index.
EOF
                exit 0
                ;;
            *)
                log_warning "Unknown option: $1 (ignored)"
                shift
                ;;
        esac
    done
}

check_sudo() {
    if ! sudo -n true 2>/dev/null; then
        log_error "sudo credentials not cached. Run: sudo -v"
        FAIL_FLAG=1
        FAIL_REASON="sudo -n unavailable"
        exit 1
    fi
}

init_bundle() {
    PROOF_DIR="$REPO_DIR/proof/post_install_e16g2_amd_apply_$UTC_TS"
    LOGS_DIR="$PROOF_DIR/logs"
    mkdir -p "$LOGS_DIR"
    echo "$PROOF_DIR" > "$BUNDLE_PATH_FILE"
    log_info "Apply proof bundle: $PROOF_DIR"
}

init_rollback() {
    local rollback_file="$PROOF_DIR/rollback.sh"
    cat > "$rollback_file" <<'EOF'
#!/usr/bin/env bash
# ThinkPad E16 Gen2 (AMD) — ROLLBACK Script
# Generated by apply_e16g2_amd.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGS_DIR="$SCRIPT_DIR/logs"
PRIOR_STATE_FILE="$SCRIPT_DIR/prior_state.txt"

log_info() { echo "[INFO] $*"; }
log_success() { echo "[OK] $*"; }
log_warning() { echo "[WARN] $*"; }
log_error() { echo "[ERROR] $*" >&2; }

if ! sudo -n true 2>/dev/null; then
    echo "[ERROR] sudo credentials not cached. Run: sudo -v" >&2
    exit 1
fi

if [[ -f "$PRIOR_STATE_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$PRIOR_STATE_FILE"
else
    log_warning "prior_state.txt missing; rollback may be incomplete"
fi

ROLLBACK_LOG="$LOGS_DIR/rollback_$(date -u +%Y%m%dT%H%M%SZ).txt"
mkdir -p "$LOGS_DIR"
exec > >(tee -a "$ROLLBACK_LOG") 2>&1

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  ThinkPad E16 Gen2 (AMD) — ROLLBACK"
echo "═══════════════════════════════════════════════════════════"
echo ""
log_info "Starting rollback at $(date -u +%Y%m%dT%H%M%SZ)"

# ROLLBACK ACTIONS BELOW (appended by apply script)
# =================================================
EOF
    chmod +x "$rollback_file"
}

add_rollback() {
    echo "$1" >> "$PROOF_DIR/rollback.sh"
}

finalize_rollback() {
    cat >> "$PROOF_DIR/rollback.sh" <<'EOF'

# =================================================
# ROLLBACK COMPLETE
# =================================================

echo ""
log_success "Rollback complete"
log_info "Log saved to: $ROLLBACK_LOG"
echo ""
EOF
}

capture_prior_state() {
    log_step "Capture prior state"
    local prior_state_file="$PROOF_DIR/prior_state.txt"

    {
        echo "# Prior System State (before apply)"
        echo "# Generated: $(date -u +%Y%m%dT%H%M%SZ)"
    } > "$prior_state_file"

    if systemctl is-enabled fstrim.timer >/dev/null 2>&1; then
        FSTRIM_ENABLED_BEFORE="true"
    else
        FSTRIM_ENABLED_BEFORE="false"
    fi
    echo "FSTRIM_ENABLED_BEFORE=$FSTRIM_ENABLED_BEFORE" >> "$prior_state_file"

    local ufw_status
    ufw_status="$(sudo -n ufw status 2>/dev/null || echo 'unknown')"
    if [[ "$ufw_status" == *"Status: active"* ]]; then
        UFW_ENABLED_BEFORE="true"
    else
        UFW_ENABLED_BEFORE="false"
    fi
    echo "UFW_ENABLED_BEFORE=$UFW_ENABLED_BEFORE" >> "$prior_state_file"

    if [[ "$ufw_status" == *"deny (incoming)"* ]]; then
        UFW_DEFAULT_IN_BEFORE="deny"
    else
        UFW_DEFAULT_IN_BEFORE="allow"
    fi
    echo "UFW_DEFAULT_IN_BEFORE=$UFW_DEFAULT_IN_BEFORE" >> "$prior_state_file"

    if [[ "$ufw_status" == *"allow (outgoing)"* ]]; then
        UFW_DEFAULT_OUT_BEFORE="allow"
    else
        UFW_DEFAULT_OUT_BEFORE="deny"
    fi
    echo "UFW_DEFAULT_OUT_BEFORE=$UFW_DEFAULT_OUT_BEFORE" >> "$prior_state_file"

    if dpkg -s unattended-upgrades >/dev/null 2>&1; then
        UNATTENDED_PRESENT_BEFORE="true"
    else
        UNATTENDED_PRESENT_BEFORE="false"
    fi
    echo "UNATTENDED_PRESENT_BEFORE=$UNATTENDED_PRESENT_BEFORE" >> "$prior_state_file"

    if dpkg -s amd64-microcode >/dev/null 2>&1; then
        AMD_MICROCODE_BEFORE="true"
    else
        AMD_MICROCODE_BEFORE="false"
    fi
    echo "AMD_MICROCODE_BEFORE=$AMD_MICROCODE_BEFORE" >> "$prior_state_file"

    run_capture "prior_state" cat "$prior_state_file"
    log_success "Prior state captured"
}

track_action() {
    local action="$1" status="$2" detail="${3:-}"
    local ts="$(date -u +%Y%m%dT%H%M%SZ)"
    local action_s status_s detail_s
    action_s="$(escape_json "$action")"
    status_s="$(escape_json "$status")"
    detail_s="$(escape_json "$detail")"

    if [[ -n "$detail" ]]; then
        ACTIONS_LOG+=("{\"timestamp\":\"$ts\",\"action\":\"$action_s\",\"status\":\"$status_s\",\"detail\":\"$detail_s\"}")
    else
        ACTIONS_LOG+=("{\"timestamp\":\"$ts\",\"action\":\"$action_s\",\"status\":\"$status_s\"}")
    fi
}

apply_group1_performance() {
    log_step "Group 1: Performance"

    run_capture_shell "before_fstrim" "systemctl status fstrim.timer --no-pager 2>/dev/null || true"
    if systemctl is-enabled fstrim.timer >/dev/null 2>&1; then
        track_action "enable_fstrim" "already_enabled"
    else
        run_capture "enable_fstrim" sudo -n systemctl enable fstrim.timer
        run_capture "start_fstrim" sudo -n systemctl start fstrim.timer
        track_action "enable_fstrim" "enabled"
        report_add "PASS" "fstrim.timer enabled"
        if [[ "$FSTRIM_ENABLED_BEFORE" == "false" ]]; then
            add_rollback "log_info 'Disabling fstrim.timer (was disabled before)'"
            add_rollback "sudo -n systemctl stop fstrim.timer 2>/dev/null || true"
            add_rollback "sudo -n systemctl disable fstrim.timer 2>/dev/null || true"
        fi
    fi
    run_capture_shell "after_fstrim" "systemctl status fstrim.timer --no-pager 2>/dev/null || true"

    run_capture_shell "before_microcode" "dpkg -s amd64-microcode 2>/dev/null || echo 'Not installed'"
    if dpkg -s amd64-microcode >/dev/null 2>&1; then
        track_action "install_microcode" "already_installed"
    else
        run_must "apt_update_microcode" env DEBIAN_FRONTEND=noninteractive sudo -n apt-get update
        run_must "apt_install_microcode" env DEBIAN_FRONTEND=noninteractive sudo -n apt-get install -y amd64-microcode
        INSTALLED_PACKAGES+=("amd64-microcode")
        track_action "install_microcode" "installed"
        report_add "PASS" "amd64-microcode installed"
        if [[ "$AMD_MICROCODE_BEFORE" == "false" ]]; then
            add_rollback "log_info 'Removing amd64-microcode (was absent before)'"
            add_rollback "sudo -n apt-get purge -y amd64-microcode 2>/dev/null || true"
            add_rollback "sudo -n apt-get autoremove -y 2>/dev/null || true"
        fi
    fi
    run_capture_shell "after_microcode" "dpkg -s amd64-microcode 2>/dev/null || echo 'Not installed'"

    if (( ENABLE_ZRAM == 1 )); then
        track_action "enable_zram" "not_implemented" "Flag not implemented"
        report_add "WARN" "ZRAM flag not implemented"
    fi
}

apply_group2_security() {
    log_step "Group 2: Security"

    run_capture_shell "before_ufw" "sudo -n ufw status verbose 2>/dev/null || echo 'UFW unavailable'"
    if ! command -v ufw >/dev/null 2>&1; then
        run_must "apt_install_ufw" env DEBIAN_FRONTEND=noninteractive sudo -n apt-get update
        run_must "apt_install_ufw_pkg" env DEBIAN_FRONTEND=noninteractive sudo -n apt-get install -y ufw
        INSTALLED_PACKAGES+=("ufw")
        track_action "install_ufw" "installed"
    else
        track_action "install_ufw" "already_present"
    fi

    local ufw_status
    ufw_status="$(sudo -n ufw status 2>/dev/null || echo 'unknown')"
    if [[ "$ufw_status" == *"Status: active"* ]]; then
        track_action "configure_ufw" "already_active"
    else
        run_capture "ufw_default_deny" sudo -n ufw --force default deny incoming
        run_capture "ufw_default_allow" sudo -n ufw --force default allow outgoing
        run_capture "ufw_enable" sudo -n ufw --force enable
        track_action "configure_ufw" "configured"
        report_add "PASS" "UFW enabled (deny in / allow out)"
        if [[ "$UFW_ENABLED_BEFORE" == "false" ]]; then
            add_rollback "log_info 'Disabling UFW (was disabled before)'"
            add_rollback "sudo -n ufw --force disable 2>/dev/null || true"
        fi
        if [[ "$UFW_DEFAULT_IN_BEFORE" != "deny" ]]; then
            add_rollback "log_info 'Restoring UFW incoming default to $UFW_DEFAULT_IN_BEFORE'"
            if [[ "$UFW_DEFAULT_IN_BEFORE" == "allow" ]]; then
                add_rollback "sudo -n ufw --force default allow incoming 2>/dev/null || true"
            fi
        fi
        if [[ "$UFW_DEFAULT_OUT_BEFORE" != "allow" ]]; then
            add_rollback "log_info 'Restoring UFW outgoing default to $UFW_DEFAULT_OUT_BEFORE'"
            if [[ "$UFW_DEFAULT_OUT_BEFORE" == "deny" ]]; then
                add_rollback "sudo -n ufw --force default deny outgoing 2>/dev/null || true"
            fi
        fi
    fi
    run_capture_shell "after_ufw" "sudo -n ufw status verbose 2>/dev/null || echo 'UFW unavailable'"

    run_capture_shell "before_unattended" "dpkg -s unattended-upgrades 2>/dev/null || echo 'Not installed'"
    if dpkg -s unattended-upgrades >/dev/null 2>&1; then
        track_action "install_unattended" "already_installed"
    else
        run_must "apt_update_unattended" env DEBIAN_FRONTEND=noninteractive sudo -n apt-get update
        run_must "apt_install_unattended" env DEBIAN_FRONTEND=noninteractive sudo -n apt-get install -y unattended-upgrades
        INSTALLED_PACKAGES+=("unattended-upgrades")
        track_action "install_unattended" "installed"
        report_add "PASS" "unattended-upgrades installed"
        if [[ "$UNATTENDED_PRESENT_BEFORE" == "false" ]]; then
            add_rollback "log_info 'Removing unattended-upgrades (was absent before)'"
            add_rollback "sudo -n apt-get purge -y unattended-upgrades 2>/dev/null || true"
            add_rollback "sudo -n apt-get autoremove -y 2>/dev/null || true"
        fi
    fi
    run_capture_shell "after_unattended" "dpkg -s unattended-upgrades 2>/dev/null || echo 'Not installed'"
}

apply_group3_devtools() {
    log_step "Group 3: Development Tools"

    local packages=(
        build-essential
        git
        curl
        wget
        ca-certificates
        python3-pip
        python3-venv
        pipx
        docker.io
        wireguard-tools
    )

    run_capture_shell "before_packages" "dpkg -l | grep -E 'build-essential|git|docker|pipx' || true"

    local to_install=()
    for pkg in "${packages[@]}"; do
        if ! dpkg -s "$pkg" >/dev/null 2>&1; then
            to_install+=("$pkg")
        fi
    done

    if (( ${#to_install[@]} == 0 )); then
        track_action "install_devtools" "already_installed"
    else
        run_must "apt_update_devtools" env DEBIAN_FRONTEND=noninteractive sudo -n apt-get update
        run_must "apt_install_devtools" env DEBIAN_FRONTEND=noninteractive sudo -n apt-get install -y "${to_install[@]}"
        for pkg in "${to_install[@]}"; do
            INSTALLED_PACKAGES+=("$pkg")
        done
        track_action "install_devtools" "installed" "Packages: ${to_install[*]}"
        report_add "PASS" "Dev tools installed: ${to_install[*]}"
        add_rollback "log_info 'Removing dev packages installed by apply'"
        add_rollback "sudo -n apt-get purge -y ${to_install[@]} 2>/dev/null || true"
        add_rollback "sudo -n apt-get autoremove -y 2>/dev/null || true"
    fi

    run_capture_shell "after_packages" "dpkg -l | grep -E 'build-essential|git|docker|pipx' || true"

    if (( ENABLE_DOCKER_OFFICIAL == 1 )); then
        track_action "enable_docker_official" "not_implemented" "Flag not implemented"
        report_add "WARN" "Docker official flag not implemented"
    fi
    if (( ENABLE_NODESOURCE == 1 )); then
        track_action "enable_nodesource" "not_implemented" "Flag not implemented"
        report_add "WARN" "NodeSource flag not implemented"
    fi
    if (( ENABLE_VSCODE == 1 )); then
        track_action "enable_vscode" "not_implemented" "Flag not implemented"
        report_add "WARN" "VS Code flag not implemented"
    fi
    if (( ENABLE_PROTONVPN == 1 )); then
        track_action "enable_protonvpn" "not_implemented" "Flag not implemented"
        report_add "WARN" "ProtonVPN flag not implemented"
    fi
}

generate_apply_report() {
    local report_json="$PROOF_DIR/apply_report.json"
    local report_txt="$PROOF_DIR/apply_report.txt"

    {
        echo "{"
        echo "  \"apply_timestamp\": \"$UTC_TS\","
        echo "  \"hostname\": \"$(hostname)\","
        echo "  \"flags\": {"
        echo "    \"enable_zram\": $ENABLE_ZRAM,"
        echo "    \"enable_docker_official\": $ENABLE_DOCKER_OFFICIAL,"
        echo "    \"enable_nodesource\": $ENABLE_NODESOURCE,"
        echo "    \"enable_vscode\": $ENABLE_VSCODE,"
        echo "    \"enable_protonvpn\": $ENABLE_PROTONVPN"
        echo "  },"
        echo "  \"actions\": ["
        local first=1
        for action in "${ACTIONS_LOG[@]}"; do
            if (( first == 1 )); then first=0; else echo ","; fi
            echo "    $action"
        done
        echo "  ],"
        echo "  \"installed_packages\": ["
        first=1
        for pkg in "${INSTALLED_PACKAGES[@]}"; do
            if (( first == 1 )); then first=0; else echo ","; fi
            echo "    \"$pkg\""
        done
        echo "  ],"
        echo "  \"status\": {"
        echo "    \"pass_count\": $REPORT_PASS,"
        echo "    \"warn_count\": $REPORT_WARN,"
        echo "    \"fail_count\": $REPORT_FAIL"
        echo "  }"
        echo "}"
    } > "$report_json"

    {
        echo "==========================================================="
        echo "ThinkPad E16 Gen2 (AMD) — Apply Report"
        echo "==========================================================="
        echo "Applied at: $UTC_TS"
        echo "Hostname: $(hostname)"
        echo ""
        echo "Flags:"
        echo "  ZRAM: $ENABLE_ZRAM"
        echo "  Docker Official: $ENABLE_DOCKER_OFFICIAL"
        echo "  NodeSource: $ENABLE_NODESOURCE"
        echo "  VS Code: $ENABLE_VSCODE"
        echo "  ProtonVPN: $ENABLE_PROTONVPN"
        echo ""
        echo "Actions (${#ACTIONS_LOG[@]}):"
        for action in "${ACTIONS_LOG[@]}"; do
            echo "  - $action"
        done
        echo ""
        echo "Installed Packages (${#INSTALLED_PACKAGES[@]}):"
        for pkg in "${INSTALLED_PACKAGES[@]}"; do
            echo "  - $pkg"
        done
        echo ""
        echo "Result: PASS=$REPORT_PASS WARN=$REPORT_WARN FAIL=$REPORT_FAIL"
    } > "$report_txt"
}

generate_installed_packages_list() {
    local pkg_file="$PROOF_DIR/installed_packages.txt"
    {
        echo "# Packages installed by apply_e16g2_amd.sh"
        echo "# Generated: $(date -u +%Y%m%dT%H%M%SZ)"
        for pkg in "${INSTALLED_PACKAGES[@]}"; do
            echo "$pkg"
        done
    } > "$pkg_file"
}

generate_decisions_json() {
    local decisions_json="$PROOF_DIR/decisions.json"
    {
        echo "{"
        echo "  \"apply_timestamp\": \"$UTC_TS\","
        echo "  \"flags\": {"
        echo "    \"enable_zram\": $ENABLE_ZRAM,"
        echo "    \"enable_docker_official\": $ENABLE_DOCKER_OFFICIAL,"
        echo "    \"enable_nodesource\": $ENABLE_NODESOURCE,"
        echo "    \"enable_vscode\": $ENABLE_VSCODE,"
        echo "    \"enable_protonvpn\": $ENABLE_PROTONVPN"
        echo "  },"
        echo "  \"actions\": ["
        local first=1
        for action in "${ACTIONS_LOG[@]}"; do
            if (( first == 1 )); then first=0; else echo ","; fi
            echo "    $action"
        done
        echo "  ]"
        echo "}"
    } > "$decisions_json"
}

generate_baseline_report() {
    local report_json="$PROOF_DIR/report.json"
    local report_txt="$PROOF_DIR/report.txt"

    local kernel="$(uname -r)"
    local hostname="$(hostname)"
    local amdgpu_loaded="false"
    if lsmod | grep -q '^amdgpu'; then amdgpu_loaded="true"; fi
    local fstrim_enabled="false"
    if systemctl is-enabled fstrim.timer >/dev/null 2>&1; then fstrim_enabled="true"; fi
    local ufw_active="false"
    local ufw_status
    ufw_status="$(sudo -n ufw status 2>/dev/null || echo 'unknown')"
    if [[ "$ufw_status" == *"Status: active"* ]]; then ufw_active="true"; fi
    local microcode_installed="false"
    if dpkg -s amd64-microcode >/dev/null 2>&1; then microcode_installed="true"; fi

    {
        echo "{"
        echo "  \"snapshot_timestamp\": \"$(date -u +%Y%m%dT%H%M%SZ)\","
        echo "  \"hostname\": \"$hostname\","
        echo "  \"kernel\": \"$kernel\","
        echo "  \"amdgpu_loaded\": $amdgpu_loaded,"
        echo "  \"fstrim_enabled\": $fstrim_enabled,"
        echo "  \"ufw_active\": $ufw_active,"
        echo "  \"microcode_installed\": $microcode_installed"
        echo "}"
    } > "$report_json"

    {
        echo "==========================================================="
        echo "System Baseline Report (after apply)"
        echo "==========================================================="
        echo "Hostname: $hostname"
        echo "Kernel: $kernel"
        echo "AMDGPU loaded: $amdgpu_loaded"
        echo "fstrim enabled: $fstrim_enabled"
        echo "UFW active: $ufw_active"
        echo "Microcode installed: $microcode_installed"
    } > "$report_txt"
}

generate_certification() {
    local cert_file="$PROOF_DIR/CERTIFICATION.txt"
    local status="PASS"
    if (( REPORT_FAIL > 0 )) || (( FAIL_FLAG == 1 )); then
        status="FAIL"
    elif (( REPORT_WARN > 0 )); then
        status="WARN"
    fi

    local kernel="$(uname -r)"
    local amdgpu_loaded="false"
    if lsmod | grep -q '^amdgpu'; then amdgpu_loaded="true"; fi
    local fstrim_enabled="false"
    if systemctl is-enabled fstrim.timer >/dev/null 2>&1; then fstrim_enabled="true"; fi
    local ufw_status="inactive"
    local ufw_out
    ufw_out="$(sudo -n ufw status 2>/dev/null || echo 'unknown')"
    if [[ "$ufw_out" == *"Status: active"* ]]; then ufw_status="active"; fi
    local microcode_installed="false"
    if dpkg -s amd64-microcode >/dev/null 2>&1; then microcode_installed="true"; fi

    echo "$status | kernel=$kernel | amdgpu=$amdgpu_loaded | fstrim=$fstrim_enabled | ufw=$ufw_status | microcode=$microcode_installed | actions=${#ACTIONS_LOG[@]} | packages=${#INSTALLED_PACKAGES[@]}" > "$cert_file"
}

generate_evidence_index() {
    local index_file="$PROOF_DIR/evidence_index.txt"
    local -a files=()

    # Collect files excluding the index itself, NUL-safe and sorted for stability
    while IFS= read -r -d '' path; do
        files+=("$path")
    done < <(find "$PROOF_DIR" -type f -not -name "evidence_index.txt" -print0 | sort -z)

    {
        echo "# Evidence Index (SHA256)"
        echo "# Generated: $(date -u +%Y%m%dT%H%M%SZ)"
        echo "# Bundle: $PROOF_DIR"
        echo ""
    } > "$index_file"

    local file
    for file in "${files[@]}"; do
        local hash
        hash="$(sha256sum "$file" | awk '{print $1}')"
        local rel="./${file#$PROOF_DIR/}"
        printf '%s %s\n' "$hash" "$rel" >> "$index_file"
    done

    local malformed
    malformed=$(awk '!/^#/ && NF && !($1 ~ /^[0-9a-f]{64}$/ && $2 ~ /^\.\/.+/){print NR":"$0}' "$index_file" || true)
    if [[ -n "$malformed" ]]; then
        log_error "Malformed evidence index lines:"
        echo "$malformed"
        FAIL_FLAG=1
        return 1
    fi

    local hash_lines
    hash_lines=$(awk '($1 ~ /^[0-9a-f]{64}$/ && $2 ~ /^\.\/.+/){c++} END {print c+0}' "$index_file")
    local file_count="${#files[@]}"

    if (( hash_lines != file_count )); then
        log_error "Evidence index count mismatch: hashes=$hash_lines, files=$file_count"
        FAIL_FLAG=1
        return 1
    fi
}

finalize_artifacts() {
    (( FINALIZED == 1 )) && return 0
    FINALIZED=1
    if [[ -z "${PROOF_DIR:-}" ]]; then
        return 0
    fi

    generate_apply_report || true
    generate_installed_packages_list || true
    generate_decisions_json || true
    generate_baseline_report || true
    generate_certification || true
    generate_evidence_index || true
}

on_exit() {
    local exit_code=$?
    finalize_artifacts
    exit $exit_code
}
trap on_exit EXIT

main() {
    echo ""
    echo "==========================================================="
    echo "ThinkPad E16 Gen2 (AMD) — Apply Baseline"
    echo "==========================================================="
    echo ""

    parse_args "$@"
    init_bundle
    check_sudo
    init_rollback
    capture_prior_state

    apply_group1_performance
    apply_group2_security
    apply_group3_devtools

    finalize_rollback

    log_success "Apply complete"
    log_info "Proof bundle: $PROOF_DIR"
    log_info "Rollback script: $PROOF_DIR/rollback.sh"
}

main "$@"
