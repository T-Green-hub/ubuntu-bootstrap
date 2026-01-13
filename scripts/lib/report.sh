#!/usr/bin/env bash
# Report generation utilities for ubuntu-bootstrap
# Creates human-readable and JSON reports

# Source logging if not already loaded
if ! declare -F log_info >/dev/null 2>&1; then
    SCRIPT_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$SCRIPT_LIB_DIR/logging.sh"
fi

# Initialize report counters
REPORT_PASS=0
REPORT_WARN=0
REPORT_FAIL=0
declare -a REPORT_MESSAGES=()

# Add a report entry
report_add() {
    local status="$1"  # PASS, WARN, FAIL
    local message="$2"
    
    case "$status" in
        PASS)
            ((REPORT_PASS++)) || true
            ;;
        WARN)
            ((REPORT_WARN++)) || true
            ;;
        FAIL)
            ((REPORT_FAIL++)) || true
            ;;
        *)
            log_error "Invalid report status: $status"
            return 1
            ;;
    esac
    
    REPORT_MESSAGES+=("$status|$message")
}

# Print report summary
report_summary() {
    local title="${1:-BOOTSTRAP RESULT}"
    
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "  $title"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    printf "  ✓ PASS:  %3d\n" "$REPORT_PASS"
    printf "  ⚠ WARN:  %3d\n" "$REPORT_WARN"
    printf "  ✗ FAIL:  %3d\n" "$REPORT_FAIL"
    echo ""
    
    if (( ${#REPORT_MESSAGES[@]} > 0 )); then
        echo "Details:"
        echo "───────────────────────────────────────────────────────────"
        for msg in "${REPORT_MESSAGES[@]}"; do
            local status="${msg%%|*}"
            local text="${msg#*|}"
            case "$status" in
                PASS)
                    echo "  ✓ $text"
                    ;;
                WARN)
                    echo "  ⚠ $text"
                    ;;
                FAIL)
                    echo "  ✗ $text"
                    ;;
            esac
        done
        echo ""
    fi
    
    echo "═══════════════════════════════════════════════════════════"
    
    # Return exit code based on failures
    if (( REPORT_FAIL > 0 )); then
        return 1
    fi
    return 0
}

# Write JSON report
report_write_json() {
    local output_file="$1"
    local timestamp
    timestamp="$(date -Iseconds)"
    
    # Build JSON manually (avoiding jq dependency)
    {
        echo "{"
        echo "  \"timestamp\": \"$timestamp\","
        echo "  \"summary\": {"
        echo "    \"pass\": $REPORT_PASS,"
        echo "    \"warn\": $REPORT_WARN,"
        echo "    \"fail\": $REPORT_FAIL"
        echo "  },"
        echo "  \"details\": ["
        
        local first=1
        for msg in "${REPORT_MESSAGES[@]}"; do
            local status="${msg%%|*}"
            local text="${msg#*|}"
            
            # Escape quotes in text
            text="${text//\"/\\\"}"
            
            if (( first == 0 )); then
                echo ","
            fi
            first=0
            
            printf "    {\"status\": \"%s\", \"message\": \"%s\"}" "$status" "$text"
        done
        
        echo ""
        echo "  ]"
        echo "}"
    } > "$output_file"
    
    log_success "JSON report written: $output_file"
}

# Write text report
report_write_text() {
    local output_file="$1"
    local timestamp
    timestamp="$(date -Iseconds)"
    
    {
        echo "Bootstrap Report"
        echo "Generated: $timestamp"
        echo ""
        echo "Summary:"
        echo "  PASS: $REPORT_PASS"
        echo "  WARN: $REPORT_WARN"
        echo "  FAIL: $REPORT_FAIL"
        echo ""
        echo "Details:"
        for msg in "${REPORT_MESSAGES[@]}"; do
            local status="${msg%%|*}"
            local text="${msg#*|}"
            printf "  [%s] %s\n" "$status" "$text"
        done
    } > "$output_file"
    
    log_success "Text report written: $output_file"
}
