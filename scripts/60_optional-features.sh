#!/usr/bin/env bash
# Optional Features Installation Orchestrator
# Install privacy and productivity tools: ProtonVPN, Brave Browser, etc.
#
# Usage: ./60_optional-features.sh [feature ...]
#   If no arguments, shows available features and prompts for selection.
#   Otherwise, installs only specified features.
#
# Examples:
#   ./60_optional-features.sh protonvpn brave    # Install both
#   ./60_optional-features.sh protonvpn          # Install ProtonVPN only
#   DRY_RUN=1 ./60_optional-features.sh brave    # Preview Brave install

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FEATURES_DIR="${SCRIPT_DIR}/optional-features"
source "${SCRIPT_DIR}/../hardware/common.sh"

log() { printf '[%s] %s\n' "$(date -Iseconds)" "$*"; }

# List of available optional features
declare -A OPTIONAL_FEATURES=(
    ["protonvpn"]="ProtonVPN - Official GUI app (daemon + GTK)"
    ["brave"]="Brave Browser - Privacy-focused browser with ad blocking"
    ["vlc"]="VLC Media Player - Feature-rich multimedia player"
    ["libreoffice"]="LibreOffice - Full office suite (Writer, Calc, Impress, Draw, Base, Math)"
    ["timeshift"]="TimeShift - System snapshots and restore (rsync/GUI)"
)

show_available_features() {
    echo ""
    echo "========================================================================"
    echo "                   Available Optional Features"
    echo "========================================================================"
    echo ""
    for feature in "${!OPTIONAL_FEATURES[@]}"; do
        echo "  ${feature}"
        echo "    ${OPTIONAL_FEATURES[$feature]}"
        echo ""
    done
    echo "========================================================================"
    echo ""
    echo "Usage:"
    echo "  $0 [feature1] [feature2] ..."
    echo ""
    echo "Examples:"
    echo "  $0 protonvpn brave    # Install ProtonVPN and Brave"
    echo "  $0 protonvpn          # Install ProtonVPN only"
    echo "  $0 vlc libreoffice    # Install VLC and LibreOffice"
    echo "  DRY_RUN=1 $0 brave    # Preview Brave installation"
    echo ""
}

install_feature() {
    local feature="$1"
    local script="${FEATURES_DIR}/${feature}.sh"
    
    if [[ ! -f "$script" ]]; then
        log "ERROR: Feature script not found: $script"
        return 1
    fi
    
    log "Installing feature: ${feature}"
    log "---"
    
    # Source and run the feature script
    if bash "$script"; then
        log "✓ ${feature} installation succeeded"
        return 0
    else
        log "✗ ${feature} installation failed"
        return 1
    fi
}

main() {
    log "=== Optional Features Installation ==="
    
    local failed_features=()
    local to_install=()
    
    # If no arguments, show available features and exit
    if [[ $# -eq 0 ]]; then
        show_available_features
        log "Please specify which features to install."
        return 0
    fi
    
    # Validate requested features
    for arg in "$@"; do
        if [[ -n "${OPTIONAL_FEATURES[$arg]:-}" ]]; then
            to_install+=("$arg")
        else
            log "WARNING: Unknown feature: $arg"
            log "Available features: ${!OPTIONAL_FEATURES[*]}"
        fi
    done
    
    if [[ ${#to_install[@]} -eq 0 ]]; then
        log "ERROR: No valid features specified"
        show_available_features
        return 1
    fi
    
    log "Features to install: ${to_install[*]}"
    log ""
    
    # Install each feature
    for feature in "${to_install[@]}"; do
        if ! install_feature "$feature"; then
            failed_features+=("$feature")
        fi
        log ""
    done
    
    # Report results
    log "========================================================================"
    if [[ ${#failed_features[@]} -gt 0 ]]; then
        log "WARNING: Some features failed to install: ${failed_features[*]}"
        log "Optional features installation completed with errors."
        return 1
    else
        log "✓ All optional features installed successfully!"
        log "Optional features installation complete."
    fi
    log "========================================================================"
}

main "$@"
