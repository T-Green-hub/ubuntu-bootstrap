#!/usr/bin/env bash
# LibreOffice installation for Ubuntu 24.04
# Full-featured office suite (Writer, Calc, Impress, Draw)

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../hardware/common.sh"

log() { printf '[%s] %s\n' "$(date -Iseconds)" "$*"; }

install_libreoffice() {
    log "=== LibreOffice Installation ==="
    
    # Check if already installed
    if command -v libreoffice >/dev/null 2>&1; then
        log "LibreOffice already installed: $(libreoffice --version 2>&1)"
        return 0
    fi
    
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        log "[DRY RUN] Would install LibreOffice suite"
        return 0
    fi
    
    log "Installing LibreOffice..."
    apt_safe update -qq
    
    # Install core LibreOffice suite
    apt_safe install -y \
        libreoffice \
        libreoffice-gtk3 \
        libreoffice-style-breeze
    
    # Optional: Install help files and language support
    # Uncomment if needed:
    # apt_safe install -y libreoffice-help-en-us libreoffice-l10n-en-us
    
    log "LibreOffice installed successfully."
    log ""
    log "Applications installed:"
    log "  - Writer (word processor)"
    log "  - Calc (spreadsheets)"
    log "  - Impress (presentations)"
    log "  - Draw (vector graphics)"
    log "  - Base (database)"
    log "  - Math (formula editor)"
    log ""
    log "Launch from application menu or run: libreoffice"
}

verify_libreoffice() {
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        log "[DRY RUN] Would verify LibreOffice installation"
        return 0
    fi
    
    log "Verifying LibreOffice installation..."
    
    if command -v libreoffice >/dev/null 2>&1; then
        log "✓ LibreOffice: $(libreoffice --version 2>&1)"
    else
        log "⚠ LibreOffice not found"
        return 1
    fi
    
    # Check for individual components
    local components=(writer calc impress draw base math)
    local found=0
    
    for comp in "${components[@]}"; do
        if command -v "lo${comp}" >/dev/null 2>&1 || \
           [[ -f "/usr/share/applications/libreoffice-${comp}.desktop" ]]; then
            # Use pre-increment to ensure a zero exit status under 'set -e'
            ((++found))
        fi
    done
    
    log "✓ Found ${found}/${#components[@]} LibreOffice components"
}

uninstall_libreoffice() {
    log "[UNINSTALL] Removing LibreOffice..."
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        log "[DRY RUN] Would remove libreoffice and related packages"
        return 0
    fi
    
    apt_safe remove -y 'libreoffice*' || true
    apt_safe autoremove -y
    log "LibreOffice uninstalled."
}

main() {
    install_libreoffice
    verify_libreoffice
    log "LibreOffice installation complete."
}

# Allow sourcing for functions or direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
