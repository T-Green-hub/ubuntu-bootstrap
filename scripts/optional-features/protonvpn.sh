#!/usr/bin/env bash
# ProtonVPN installation for Ubuntu 24.04
# Installs ProtonVPN CLI and optional GUI client

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../hardware/common.sh"

log() { printf '[%s] %s\n' "$(date -Iseconds)" "$*"; }

install_protonvpn() {
    log "=== ProtonVPN Installation ==="
    
    # Check if already installed
    if command -v protonvpn-cli >/dev/null 2>&1; then
        log "ProtonVPN CLI already installed: $(protonvpn-cli --version 2>&1 | head -1)"
        return 0
    fi
    
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        log "[DRY RUN] Would install ProtonVPN repository and CLI"
        log "[DRY RUN] Would optionally install protonvpn-gui"
        return 0
    fi
    
    log "Adding ProtonVPN repository..."
    
    # Download and add ProtonVPN repository key
    if [[ ! -f /usr/share/keyrings/proton-vpn-stable-archive-keyring.gpg ]]; then
        wget -q https://repo.protonvpn.com/debian/dists/stable/public_key.asc -O- | \
            $(need_sudo) gpg --dearmor -o /usr/share/keyrings/proton-vpn-stable-archive-keyring.gpg
    else
        log "ProtonVPN keyring already exists."
    fi
    
    # Add repository if not already present
    local repo_file="/etc/apt/sources.list.d/protonvpn-stable.list"
    if [[ ! -f "$repo_file" ]]; then
        echo "deb [signed-by=/usr/share/keyrings/proton-vpn-stable-archive-keyring.gpg] https://repo.protonvpn.com/debian stable main" | \
            $(need_sudo) tee "$repo_file" >/dev/null
        log "ProtonVPN repository added."
    else
        log "ProtonVPN repository already configured."
    fi
    
    # Update package list
    log "Updating package lists..."
    apt_safe update -qq
    
    # Install ProtonVPN CLI
    log "Installing ProtonVPN CLI..."
    apt_safe install -y proton-vpn-gnome-desktop
    
    log "ProtonVPN installed successfully."
    log ""
    log "To configure ProtonVPN:"
    log "  1. Run: protonvpn-cli login"
    log "  2. Enter your ProtonVPN credentials"
    log "  3. Connect: protonvpn-cli connect --fastest"
    log ""
    log "GUI available via: protonvpn-app (in application menu)"
}

verify_protonvpn() {
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        log "[DRY RUN] Would verify ProtonVPN installation"
        return 0
    fi
    
    log "Verifying ProtonVPN installation..."
    
    if command -v protonvpn-cli >/dev/null 2>&1; then
        log "✓ ProtonVPN CLI: $(protonvpn-cli --version 2>&1 | head -1)"
    else
        log "⚠ ProtonVPN CLI not found"
        return 1
    fi
    
    if command -v protonvpn-app >/dev/null 2>&1; then
        log "✓ ProtonVPN GUI available"
    else
        log "ℹ ProtonVPN GUI not installed (optional)"
    fi
}

uninstall_protonvpn() {
    log "[UNINSTALL] Removing ProtonVPN..."
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        log "[DRY RUN] Would remove proton-vpn-gnome-desktop and repository"
        return 0
    fi
    
    apt_safe remove -y proton-vpn-gnome-desktop || true
    $(need_sudo) rm -f /etc/apt/sources.list.d/protonvpn-stable.list
    $(need_sudo) rm -f /usr/share/keyrings/proton-vpn-stable-archive-keyring.gpg
    apt_safe update -qq
    log "ProtonVPN uninstalled."
}

main() {
    install_protonvpn
    verify_protonvpn
    log "ProtonVPN installation complete."
}

# Allow sourcing for functions or direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
