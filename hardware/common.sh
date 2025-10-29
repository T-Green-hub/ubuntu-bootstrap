#!/usr/bin/env bash
# Common functions for laptop hardware optimization

set -euo pipefail

log() {
    printf '[%s] %s\n' "$(date -Iseconds)" "$*"
}

run() {
    # Log and run a command; respects DRY_RUN=1
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        log "[DRY RUN] $*"
        return 0
    fi
    log "$*"
    "$@"
}

need_sudo() {
    if [[ $EUID -ne 0 ]]; then
        echo sudo
    fi
}

is_installed() {
    dpkg -s "$1" >/dev/null 2>&1
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

###############################################################################
# APT/dpkg lock handling + safe wrappers
###############################################################################

# Wait for dpkg/apt locks to be released (with timeout)
wait_for_dpkg_lock() {
    local timeout="${1:-180}" # seconds
    local waited=0
    local lock_frontend="/var/lib/dpkg/lock-frontend"
    local lock_db="/var/lib/dpkg/lock"

    local has_fuser=0
    local has_lsof=0
    command -v fuser >/dev/null 2>&1 && has_fuser=1
    command -v lsof >/dev/null 2>&1 && has_lsof=1

    while true; do
        local busy=0
        if (( has_fuser )); then
            if $(need_sudo) fuser "$lock_frontend" "$lock_db" >/dev/null 2>&1; then busy=1; fi
        elif (( has_lsof )); then
            if $(need_sudo) lsof "$lock_frontend" "$lock_db" >/dev/null 2>&1; then busy=1; fi
        else
            # Fallback: check for known package managers running
            if pgrep -x apt-get >/dev/null 2>&1 || \
               pgrep -x apt >/dev/null 2>&1 || \
               pgrep -x dpkg >/dev/null 2>&1 || \
               pgrep -x unattended-upgrade >/dev/null 2>&1; then
               busy=1
            fi
        fi

        if (( busy == 0 )); then
            break
        fi
        if (( waited == 0 )); then
            log "Waiting for dpkg/apt lock to be released…"
        fi
        sleep 2
        waited=$((waited+2))
        if (( waited >= timeout )); then
            log "Timeout waiting for dpkg lock after ${timeout}s; proceeding anyway."
            break
        fi
    done
}

apt_safe() {
    # Usage: apt_safe install -y pkg1 pkg2 … | apt_safe remove -y pkg | apt_safe update -qq
    local attempts=0
    local max_attempts=6
    local delay=5
    while (( attempts < max_attempts )); do
        wait_for_dpkg_lock 180
        if [[ "${DRY_RUN:-0}" == "1" ]]; then
            log "[DRY RUN] apt-get $*"
            return 0
        fi
        if $(need_sudo) apt-get "$@"; then
            return 0
        fi
        attempts=$((attempts+1))
        if (( attempts < max_attempts )); then
            log "apt-get '$*' failed (lock or transient). Retry #${attempts}/${max_attempts} in ${delay}s…"
            sleep "$delay"
        else
            log "apt-get '$*' failed after ${attempts} attempts."
            return 1
        fi
    done
}

###############################################################################
# Battery thresholds and power management
###############################################################################

# Check if battery charge thresholds are supported
supports_charge_thresholds() {
    local bat_path="/sys/class/power_supply/BAT0"
    [[ -f "${bat_path}/charge_control_start_threshold" ]] || \
    [[ -f "${bat_path}/charge_start_threshold" ]]
}

# Install TLP with optional battery threshold configuration
install_tlp() {
    local start_threshold="${1:-20}"
    local stop_threshold="${2:-80}"

    # Check if laptop-mode-tools is installed (conflicts with TLP)
    if is_installed laptop-mode-tools; then
        log "Removing laptop-mode-tools (conflicts with TLP)…"
        apt_safe remove -y laptop-mode-tools || true
    fi

    if is_installed tlp; then
        log "TLP already installed"
    else
        log "Installing TLP (Advanced Power Management)..."
        apt_safe update -qq
        apt_safe install -y tlp tlp-rdw
    fi

    # Enable TLP service
    if ! $(need_sudo) systemctl is-enabled tlp.service &>/dev/null; then
        log "Enabling TLP service..."
        run $(need_sudo) systemctl enable tlp.service || true
        run $(need_sudo) systemctl start tlp.service || true
    fi

    # Configure battery thresholds if supported
    if supports_charge_thresholds; then
        log "Battery thresholds supported, configuring ${start_threshold}-${stop_threshold}%..."

        local conf_file="/etc/tlp.d/01-battery-thresholds.conf"
        $(need_sudo) mkdir -p /etc/tlp.d
        $(need_sudo) tee "$conf_file" >/dev/null <<EOF
# Battery charge thresholds (extends battery lifespan)
START_CHARGE_THRESH_BAT0=${start_threshold}
STOP_CHARGE_THRESH_BAT0=${stop_threshold}
START_CHARGE_THRESH_BAT1=${start_threshold}
STOP_CHARGE_THRESH_BAT1=${stop_threshold}
EOF

        if $(need_sudo) systemctl is-active tlp.service &>/dev/null; then
            run $(need_sudo) systemctl restart tlp.service >/dev/null 2>&1 || true
        fi
        log "Battery thresholds configured: ${start_threshold}-${stop_threshold}%"
    else
        log "Battery thresholds not supported on this hardware (skipping)"
    fi
}

# Check if fingerprint reader exists
has_fingerprint_reader() {
    lsusb 2>/dev/null | grep -iq "fingerprint"
}

# Install fingerprint reader support
install_fingerprint_support() {
    if ! has_fingerprint_reader; then
        log "No fingerprint reader detected, skipping..."
        return 0
    fi

    log "Fingerprint reader detected, installing support..."

    if is_installed fprintd; then
        log "Fingerprint support already installed"
        return 0
    fi

    apt_safe install -y fprintd libpam-fprintd || true
    log "Fingerprint reader installed. Enroll with: fprintd-enroll"
}

# Get CPU vendor
get_cpu_vendor() {
    grep -m1 "vendor_id" /proc/cpuinfo | awk '{print $3}' | tr '[:upper:]' '[:lower:]'
}

# Verify hardware sensors are working
verify_sensors() {
    if ! command_exists sensors; then
        log "WARNING: lm-sensors not installed"
        return 1
    fi

    log "Hardware sensors check:"
    sensors | grep -E "(°C|RPM|V):" | head -5 || log "No sensor data available"
}
