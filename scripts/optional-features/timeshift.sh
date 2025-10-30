#!/usr/bin/env bash
# TimeShift installation for Ubuntu 24.04
# Installs TimeShift (rsync snapshot tool) with optional GUI.

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../hardware/common.sh"

log() { printf '[%s] %s\n' "$(date -Iseconds)" "$*"; }

install_timeshift() {
    log "=== TimeShift Installation ==="

    if is_installed timeshift; then
        log "TimeShift already installed"
        return 0
    fi

    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        log "[DRY RUN] Would apt-get update and install: timeshift"
        return 0
    fi

    log "Updating package lists..."
    apt_safe update -qq

    log "Installing TimeShift (CLI + GTK GUI)..."
    # Note: timeshift package includes both CLI and GTK in Ubuntu 24.04
    # timeshift-gtk is a legacy package name; just install timeshift
    apt_safe install -y timeshift || true

    log "TimeShift installation complete."
    log "Launch GUI with: timeshift-gtk"
}

verify_timeshift() {
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        log "[DRY RUN] Would verify TimeShift installation"
        return 0
    fi

    log "Verifying TimeShift installation..."
    local ok=0
    if command -v timeshift >/dev/null 2>&1; then
        log "✓ TimeShift CLI available (timeshift)"
        ok=1
    fi
    if command -v timeshift-gtk >/dev/null 2>&1; then
        log "✓ TimeShift GUI available (timeshift-gtk)"
        ok=1
    fi
    if (( ok == 0 )); then
        log "⚠ TimeShift not found"
        return 1
    fi
}

uninstall_timeshift() {
    log "[UNINSTALL] Removing TimeShift..."
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        log "[DRY RUN] Would remove timeshift"
        return 0
    fi
    apt_safe remove -y timeshift || true
    log "TimeShift uninstalled."
}

main() {
    install_timeshift
    verify_timeshift
    log "TimeShift installation complete."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
