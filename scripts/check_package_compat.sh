#!/usr/bin/env bash
# Package compatibility checker for different Ubuntu versions
# Helps identify deprecated packages and suggests modern alternatives

set -euo pipefail

# Get Ubuntu version codename
get_ubuntu_codename() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        echo "${VERSION_CODENAME:-unknown}"
    else
        echo "unknown"
    fi
}

# Package mappings: deprecated -> current replacement
declare -A PACKAGE_MAPPINGS=(
    # Graphics drivers (Ubuntu 24.04+)
    ["libva-intel-driver"]="i965-va-driver"
    
    # Python packages
    ["python-pip"]="python3-pip"
    ["python"]="python3"
    
    # Network tools (deprecated in newer Ubuntu)
    ["net-tools"]="iproute2"
    ["ifupdown"]="netplan.io"
    
    # Old audio system
    ["pulseaudio"]="pipewire"
    
    # Display managers
    ["lightdm"]="gdm3"
)

# Version-specific notes
declare -A VERSION_NOTES=(
    ["noble"]="Ubuntu 24.04 LTS (Noble Numbat) - Latest LTS"
    ["jammy"]="Ubuntu 22.04 LTS (Jammy Jellyfish)"
    ["focal"]="Ubuntu 20.04 LTS (Focal Fossa) - Consider upgrading"
)

check_package() {
    local package="$1"
    local codename
    codename=$(get_ubuntu_codename)
    
    # Check if package is available
    if apt-cache show "$package" &>/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

suggest_alternative() {
    local package="$1"
    
    if [[ -n "${PACKAGE_MAPPINGS[$package]:-}" ]]; then
        echo "${PACKAGE_MAPPINGS[$package]}"
        return 0
    fi
    
    return 1
}

check_packages_in_file() {
    local file="$1"
    local issues=0
    
    echo "Checking packages in: $file"
    echo "----------------------------------------"
    
    # Extract package names from common patterns
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$line" ]] && continue
        
        # Extract package names from various patterns
        if [[ "$line" =~ apt.*install.*\"([^\"]+)\" ]] || \
           [[ "$line" =~ apt.*install[[:space:]]+([a-z0-9-]+) ]]; then
            local pkg="${BASH_REMATCH[1]}"
            
            if ! check_package "$pkg"; then
                echo "⚠ Package not found: $pkg"
                
                if alt=$(suggest_alternative "$pkg"); then
                    echo "  → Suggested alternative: $alt"
                    ((issues++))
                fi
            fi
        fi
    done < "$file"
    
    if ((issues == 0)); then
        echo "✓ No package compatibility issues found"
    else
        echo ""
        echo "Found $issues potential compatibility issue(s)"
    fi
    
    return "$issues"
}

scan_all_scripts() {
    local codename
    codename=$(get_ubuntu_codename)
    
    echo "========================================================================"
    echo "         Package Compatibility Check for Ubuntu $codename"
    echo "========================================================================"
    echo ""
    
    if [[ -n "${VERSION_NOTES[$codename]:-}" ]]; then
        echo "ℹ ${VERSION_NOTES[$codename]}"
        echo ""
    fi
    
    local total_issues=0
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Check all bootstrap scripts
    for script in "$script_dir"/*.sh; do
        [[ -f "$script" ]] || continue
        [[ "$(basename "$script")" == "check_package_compat.sh" ]] && continue
        
        local issues=0
        check_packages_in_file "$script" || issues=$?
        ((total_issues += issues))
        echo ""
    done
    
    echo "========================================================================"
    if ((total_issues == 0)); then
        echo "✓ All packages compatible with Ubuntu $codename"
    else
        echo "⚠ Total issues found: $total_issues"
        echo ""
        echo "Action required: Update package names in affected scripts"
    fi
    echo "========================================================================"
}

# Known problematic packages by Ubuntu version
check_known_issues() {
    local codename
    codename=$(get_ubuntu_codename)
    
    echo "Checking known compatibility issues for Ubuntu $codename..."
    echo ""
    
    case "$codename" in
        noble|oracular)  # Ubuntu 24.04+
            echo "Ubuntu 24.04+ specific checks:"
            echo ""
            
            # Check for deprecated package usage
            if check_package "libva-intel-driver"; then
                echo "✓ libva-intel-driver: Still available"
            else
                echo "⚠ libva-intel-driver: NOT available"
                echo "  → Use: i965-va-driver instead"
            fi
            
            if check_package "i965-va-driver"; then
                echo "✓ i965-va-driver: Available (correct for 24.04)"
            else
                echo "⚠ i965-va-driver: NOT available (unexpected)"
            fi
            ;;
            
        jammy)  # Ubuntu 22.04
            echo "Ubuntu 22.04 specific checks:"
            echo "  Most packages compatible, minimal changes needed"
            ;;
            
        focal)  # Ubuntu 20.04
            echo "Ubuntu 20.04 specific checks:"
            echo "  ⚠ Older package versions available"
            echo "  ⚠ Consider upgrading to 22.04 or 24.04"
            ;;
            
        *)
            echo "⚠ Unknown Ubuntu version: $codename"
            echo "  Cannot perform version-specific checks"
            ;;
    esac
}

main() {
    if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
        echo "Usage: $0 [--scan|--known|FILE]"
        echo ""
        echo "Options:"
        echo "  --scan       Scan all bootstrap scripts for compatibility"
        echo "  --known      Check for known version-specific issues"
        echo "  FILE         Check a specific file"
        echo "  --help       Show this help message"
        exit 0
    fi
    
    if [[ $# -eq 0 ]] || [[ "${1:-}" == "--scan" ]]; then
        scan_all_scripts
    elif [[ "${1:-}" == "--known" ]]; then
        check_known_issues
    elif [[ -f "${1:-}" ]]; then
        check_packages_in_file "$1"
    else
        echo "Error: Invalid option or file not found: ${1:-}"
        echo "Use --help for usage information"
        exit 1
    fi
}

main "$@"
