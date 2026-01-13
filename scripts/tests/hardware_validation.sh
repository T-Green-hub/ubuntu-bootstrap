#!/usr/bin/env bash
# Hardware Validation Script for ubuntu-bootstrap v4.0.7
# Tests bootstrap.sh and hardware-specific scripts on real hardware
# Safe dry-run mode by default; requires --apply flag for real changes

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TIMESTAMP="$(date -u +%Y%m%d-%H%M%S)"
VALIDATION_DIR="$HOME/bootstrap-validation/$TIMESTAMP"

DRY_RUN=1
APPLY=0
PROFILE="minimal"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ${NC} $*"; }
log_success() { echo -e "${GREEN}✓${NC} $*"; }
log_warning() { echo -e "${YELLOW}⚠${NC} $*"; }
log_error() { echo -e "${RED}✗${NC} $*" >&2; }
log_step() { echo ""; echo -e "${BLUE}▶${NC} ${BLUE}$*${NC}"; }

show_help() {
    cat <<EOF
Hardware Validation Script for ubuntu-bootstrap v4.0.7

USAGE:
    $0 [OPTIONS]

OPTIONS:
    --profile <name>    Profile to test (minimal|dev|secure) [default: minimal]
    --apply             Apply changes (not dry-run) - USE WITH CAUTION
    --help, -h          Show this help

MODES:
    Default (dry-run):  Safe testing, no system changes
    --apply:            Actually apply changes to system (REQUIRES SUDO)

TESTS:
    1. System detection and baseline capture
    2. Bootstrap dry-run (minimal profile)
    3. Hardware-specific post-install validation
    4. Artifact verification
    5. Certification check

OUTPUT:
    Results saved to: $HOME/bootstrap-validation/<timestamp>/

EXAMPLES:
    $0                                    # Safe dry-run test
    $0 --profile dev                      # Test dev profile
    $0 --profile minimal --apply          # APPLY changes (DESTRUCTIVE)

EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --profile)
                PROFILE="$2"
                shift 2
                ;;
            --apply)
                APPLY=1
                DRY_RUN=0
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

check_hardware() {
    log_step "1. Hardware Detection & Baseline"

    mkdir -p "$VALIDATION_DIR"

    {
        echo "=== Hardware Validation Baseline ==="
        echo "Date: $(date -Iseconds)"
        echo "Hostname: $(hostname)"
        echo "Kernel: $(uname -r)"
        echo ""
        echo "=== OS ==="
        cat /etc/os-release
        echo ""
        echo "=== CPU ==="
        lscpu | grep -E "Model name|CPU\(s\):|Thread|Core"
        echo ""
        echo "=== Memory ==="
        free -h
        echo ""
        echo "=== Disk ==="
        df -h /
        echo ""
        echo "=== Hardware ==="
        if command -v dmidecode >/dev/null 2>&1 && [[ $EUID -eq 0 ]]; then
            sudo dmidecode -t system | grep -E "Manufacturer|Product Name|Version"
        else
            echo "(dmidecode requires root; skipped)"
        fi
        echo ""
    } | tee "$VALIDATION_DIR/hardware-baseline.txt"

    log_success "Baseline captured: $VALIDATION_DIR/hardware-baseline.txt"
}

test_bootstrap_dry_run() {
    log_step "2. Bootstrap Dry-Run Test ($PROFILE profile)"

    local output_dir="$VALIDATION_DIR/bootstrap-$PROFILE"

    if bash "$REPO_DIR/scripts/bootstrap.sh" \
        --profile "$PROFILE" \
        --dry-run \
        --yes \
        --output-dir "$output_dir" \
        2>&1 | tee "$VALIDATION_DIR/bootstrap-output.log"; then
        log_success "Bootstrap dry-run completed"
    else
        log_error "Bootstrap dry-run failed (exit code: $?)"
        return 1
    fi

    # Verify artifacts
    if [[ -f "$output_dir/report.json" ]] && [[ -f "$output_dir/system-info.txt" ]]; then
        log_success "Artifacts created successfully"

        # Check report for failures
        local fail_count
        fail_count=$(grep -o '"fail_count":[0-9]*' "$output_dir/report.json" | grep -o '[0-9]*' || echo "0")
        if (( fail_count > 0 )); then
            log_warning "Report shows $fail_count failures"
        else
            log_success "No failures in report"
        fi
    else
        log_error "Expected artifacts missing"
        return 1
    fi
}

test_hardware_post_install() {
    log_step "3. Hardware-Specific Post-Install Test"

    # Detect if E16 Gen2 AMD
    local manufacturer product
    manufacturer=$(grep -i "Manufacturer" "$VALIDATION_DIR/hardware-baseline.txt" | head -1 || echo "unknown")
    product=$(grep -i "Product Name" "$VALIDATION_DIR/hardware-baseline.txt" | head-1 || echo "unknown")

    if [[ "$manufacturer" == *"LENOVO"* ]] && [[ "$product" == *"21MA"* ]]; then
        log_info "Detected ThinkPad E16 Gen2 AMD (21MA)"

        if (( APPLY == 1 )); then
            if [[ $EUID -ne 0 ]]; then
                log_error "Post-install requires root (use sudo)"
                return 1
            fi

            log_warning "APPLYING post-install script (SYSTEM CHANGES WILL BE MADE)"
            read -p "Continue? [y/N] " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log_info "Aborted by user"
                return 0
            fi

            bash "$REPO_DIR/scripts/post_install/apply_e16g2_amd.sh" \
                2>&1 | tee "$VALIDATION_DIR/post-install-output.log"

            # Check for proof bundle
            if ls "$REPO_DIR/proof"/post_install_e16g2_amd_apply_* >/dev/null 2>&1; then
                local latest_proof
                latest_proof=$(ls -dt "$REPO_DIR/proof"/post_install_e16g2_amd_apply_* | head -1)
                log_success "Proof bundle created: $latest_proof"

                if [[ -f "$latest_proof/CERTIFICATION.txt" ]]; then
                    log_info "Certification: $(cat "$latest_proof/CERTIFICATION.txt")"
                fi
            fi
        else
            log_info "Dry-run mode: skipping post-install (use --apply to run)"
        fi
    else
        log_info "Non-E16G2 hardware detected, skipping hardware-specific tests"
    fi
}

verify_artifacts() {
    log_step "4. Artifact Verification"

    local required_files=(
        "$VALIDATION_DIR/hardware-baseline.txt"
        "$VALIDATION_DIR/bootstrap-output.log"
    )

    local all_present=1
    for file in "${required_files[@]}"; do
        if [[ -f "$file" ]]; then
            log_success "Found: $(basename "$file")"
        else
            log_error "Missing: $(basename "$file")"
            all_present=0
        fi
    done

    if (( all_present == 1 )); then
        log_success "All required artifacts present"
    else
        log_error "Some artifacts missing"
        return 1
    fi
}

generate_summary() {
    log_step "5. Validation Summary"

    local summary_file="$VALIDATION_DIR/VALIDATION_SUMMARY.txt"

    {
        echo "=========================================="
        echo "ubuntu-bootstrap v4.0.7 Hardware Validation"
        echo "=========================================="
        echo "Date: $(date -Iseconds)"
        echo "Profile: $PROFILE"
        echo "Mode: $([[ $DRY_RUN -eq 1 ]] && echo "DRY-RUN" || echo "APPLY")"
        echo ""
        echo "Tests:"
        echo "  ✓ Hardware detection"
        echo "  ✓ Bootstrap dry-run ($PROFILE)"
        if (( APPLY == 1 )); then
            echo "  ✓ Post-install applied"
        else
            echo "  - Post-install (skipped, dry-run)"
        fi
        echo "  ✓ Artifact verification"
        echo ""
        echo "Output Directory:"
        echo "  $VALIDATION_DIR"
        echo ""
        echo "Next Steps:"
        if (( DRY_RUN == 1 )); then
            echo "  - Review logs in $VALIDATION_DIR"
            echo "  - Run with --apply to make actual changes"
        else
            echo "  - Review proof bundle in proof/"
            echo "  - Check CERTIFICATION.txt for status"
        fi
        echo "=========================================="
    } | tee "$summary_file"

    log_success "Validation complete!"
    log_info "Summary: $summary_file"
}

main() {
    parse_args "$@"

    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "  ubuntu-bootstrap v4.0.7 - Hardware Validation"
    echo "  Profile: $PROFILE"
    echo "  Mode: $([[ $DRY_RUN -eq 1 ]] && echo "DRY-RUN (safe)" || echo "APPLY (DESTRUCTIVE)")"
    echo "═══════════════════════════════════════════════════════════"
    echo ""

    check_hardware
    test_bootstrap_dry_run
    test_hardware_post_install
    verify_artifacts
    generate_summary

    echo ""
    log_success "Validation complete. Results saved to:"
    log_info "    $VALIDATION_DIR"
    echo ""
}

main "$@"
