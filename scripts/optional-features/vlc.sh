#!/usr/bin/env bash
# VLC Media Player installation for Ubuntu 24.04
# Feature-rich multimedia player supporting most codecs out of the box

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../hardware/common.sh"

log() { printf '[%s] %s\n' "$(date -Iseconds)" "$*"; }

install_vlc() {
    log "=== VLC Media Player Installation ==="
    
    # Check if already installed
    if command -v vlc >/dev/null 2>&1; then
        log "VLC already installed: $(vlc --version 2>&1 | head -1)"
        return 0
    fi
    
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        log "[DRY RUN] Would install VLC media player"
        return 0
    fi
    
    log "Installing VLC Media Player..."
    apt_safe update -qq
    apt_safe install -y vlc vlc-plugin-access-extra
    
    log "VLC Media Player installed successfully."
    log ""
    log "Features:"
    log "  - Plays almost any video/audio format"
    log "  - Hardware acceleration support"
    log "  - Network streaming (HTTP, RTSP, etc.)"
    log "  - Audio/video conversion"
    log "  - Subtitle support"
    log ""
    log "Launch VLC from your application menu or run: vlc"
}

verify_vlc() {
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        log "[DRY RUN] Would verify VLC installation"
        return 0
    fi
    
    log "Verifying VLC installation..."
    
    if command -v vlc >/dev/null 2>&1; then
        log "✓ VLC: $(vlc --version 2>&1 | head -1)"
    else
        log "⚠ VLC not found"
        return 1
    fi
    
    # Check if desktop file exists
    if [[ -f /usr/share/applications/vlc.desktop ]]; then
        log "✓ VLC desktop entry available"
    fi
}

uninstall_vlc() {
    log "[UNINSTALL] Removing VLC Media Player..."
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        log "[DRY RUN] Would remove vlc and plugins"
        return 0
    fi
    
    apt_safe remove -y vlc vlc-plugin-access-extra || true
    apt_safe autoremove -y
    log "VLC Media Player uninstalled."
}

main() {
    install_vlc
    verify_vlc
    log "VLC Media Player installation complete."
}

# Allow sourcing for functions or direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
