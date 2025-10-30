#!/usr/bin/env bash
# Brave Browser installation for Ubuntu 24.04
# Privacy-focused browser with built-in ad blocking

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../hardware/common.sh"

log() { printf '[%s] %s\n' "$(date -Iseconds)" "$*"; }

install_brave() {
    log "=== Brave Browser Installation ==="
    
    # Check if already installed
    if command -v brave-browser >/dev/null 2>&1; then
        log "Brave Browser already installed: $(brave-browser --version 2>&1 | head -1)"
        return 0
    fi
    
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        log "[DRY RUN] Would install Brave Browser repository and package"
        return 0
    fi
    
    log "Installing prerequisites..."
    apt_safe install -y curl
    
    log "Adding Brave Browser repository..."
    
    # Download and add Brave repository key
    if [[ ! -f /usr/share/keyrings/brave-browser-archive-keyring.gpg ]]; then
        $(need_sudo) curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
            https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
    else
        log "Brave keyring already exists."
    fi
    
    # Add repository if not already present
    local repo_file="/etc/apt/sources.list.d/brave-browser-release.list"
    if [[ ! -f "$repo_file" ]]; then
        echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | \
            $(need_sudo) tee "$repo_file" >/dev/null
        log "Brave repository added."
    else
        log "Brave repository already configured."
    fi
    
    # Update package list
    log "Updating package lists..."
    apt_safe update -qq
    
    # Install Brave Browser
    log "Installing Brave Browser..."
    apt_safe install -y brave-browser
    
    log "Brave Browser installed successfully."
    log ""
    log "Launch Brave from your application menu or run: brave-browser"
    log ""
    log "Privacy features:"
    log "  - Built-in ad blocker"
    log "  - HTTPS Everywhere"
    log "  - Fingerprinting protection"
    log "  - Tor private windows"
}

verify_brave() {
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        log "[DRY RUN] Would verify Brave Browser installation"
        return 0
    fi
    
    log "Verifying Brave Browser installation..."
    
    if command -v brave-browser >/dev/null 2>&1; then
        log "✓ Brave Browser: $(brave-browser --version 2>&1 | head -1)"
    else
        log "⚠ Brave Browser not found"
        return 1
    fi
    
    # Check if desktop file exists
    if [[ -f /usr/share/applications/brave-browser.desktop ]]; then
        log "✓ Brave Browser desktop entry available"
    fi
}

uninstall_brave() {
    log "[UNINSTALL] Removing Brave Browser..."
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        log "[DRY RUN] Would remove brave-browser and repository"
        return 0
    fi
    
    apt_safe remove -y brave-browser || true
    $(need_sudo) rm -f /etc/apt/sources.list.d/brave-browser-release.list
    $(need_sudo) rm -f /usr/share/keyrings/brave-browser-archive-keyring.gpg
    apt_safe update -qq
    log "Brave Browser uninstalled."
}

main() {
    install_brave
    verify_brave
    log "Brave Browser installation complete."
}

# Allow sourcing for functions or direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
