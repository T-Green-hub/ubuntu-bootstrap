#!/usr/bin/env bash
# VLC Media Player installation for Ubuntu 24.04
# Feature-rich multimedia player supporting most codecs out of the box

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../hardware/common.sh"

log() { printf '[%s] %s\n' "$(date -Iseconds)" "$*"; }

install_dvd_support() {
    log "Installing DVD codec support for encrypted DVDs..."
    
    # libdvd-pkg downloads and builds libdvdcss2 (legal in most jurisdictions)
    # This is required for playing commercial/encrypted DVDs
    apt_safe install -y libdvd-pkg
    
    # Configure and build libdvdcss2
    log "Building DVD CSS decryption library (libdvdcss2)..."
    log "This may take a minute..."
    
    # Run dpkg-reconfigure non-interactively to build libdvdcss2
    DEBIAN_FRONTEND=noninteractive $(need_sudo) dpkg-reconfigure libdvd-pkg
    
    log "✓ DVD codec support installed"
    log "  Your optical drive can now play encrypted DVDs"
}

install_vlc() {
    log "=== VLC Media Player Installation ==="
    
    # Check if already installed
    if command -v vlc >/dev/null 2>&1; then
        log "VLC already installed: $(vlc --version 2>&1 | head -1)"
        # Still install DVD support if missing
        if ! dpkg -s libdvd-pkg >/dev/null 2>&1; then
            log "Installing DVD codec support..."
            install_dvd_support
        fi
        return 0
    fi
    
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        log "[DRY RUN] Would install VLC media player with DVD/CD support"
        return 0
    fi
    
    log "Installing VLC Media Player..."
    apt_safe update -qq
    apt_safe install -y vlc vlc-plugin-access-extra
    
    # Install DVD codec support
    install_dvd_support
    
    log "VLC Media Player installed successfully."
    log ""
    log "Features:"
    log "  - Plays almost any video/audio format"
    log "  - DVD/CD playback with encrypted DVD support (CSS decryption)"
    log "  - Hardware acceleration support"
    log "  - Network streaming (HTTP, RTSP, etc.)"
    log "  - Audio/video conversion"
    log "  - Subtitle support"
    log ""
    log "Launch VLC from your application menu or run: vlc"
    log ""
    log "DVD Playback:"
    log "  - Insert DVD and open VLC"
    log "  - Media → Open Disc → Select DVD"
    log "  - Commercial DVDs will work with CSS decryption"
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
    
    # Check DVD codec support
    if dpkg -s libdvd-pkg >/dev/null 2>&1; then
        log "✓ DVD codec support (libdvdcss2) installed"
    else
        log "⚠ DVD codec support not installed (encrypted DVDs won't play)"
    fi
    
    # Check if optical drive is detected
    if ls /dev/sr0 >/dev/null 2>&1; then
        log "✓ Optical drive detected: /dev/sr0"
    elif ls /dev/cdrom >/dev/null 2>&1; then
        log "✓ Optical drive detected: /dev/cdrom"
    else
        log "ℹ No optical drive detected (normal for systems without CD/DVD drive)"
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
