#!/usr/bin/env bash
# Module: User Feedback
# Collects user satisfaction ratings and comments

set -euo pipefail

# Determine directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(dirname "$SCRIPT_DIR")/lib"

# Source library functions
if [[ -f "$LIB_DIR/logging.sh" ]]; then
    source "$LIB_DIR/logging.sh"
else
    echo "Library files not found in $LIB_DIR"
    exit 1
fi

# Feedback file
FEEDBACK_FILE="${HOME}/bootstrap-logs/feedback.csv"

collect_feedback() {
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "  📝 User Feedback"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    echo "Help us improve Ubuntu Bootstrap! Rate your experience (1-5)."
    echo "1 = Poor, 5 = Excellent"
    echo ""

    local rating_overall
    local rating_ease
    local comments
    mkdir -p "$(dirname "$FEEDBACK_FILE")"

    # Input loop
    while true; do
        read -p "  Overall Experience [1-5]: " -n 1 -r rating_overall
        echo ""
        if [[ "$rating_overall" =~ ^[1-5]$ ]]; then
            break
        fi
        log_warning "Please enter a number between 1 and 5."
    done

    while true; do
        read -p "  Ease of Use [1-5]: " -n 1 -r rating_ease
        echo ""
        if [[ "$rating_ease" =~ ^[1-5]$ ]]; then
            break
        fi
        log_warning "Please enter a number between 1 and 5."
    done

    echo ""
    echo "  Any comments or suggestions? (Press Enter to skip)"
    read -r comments

    # Save to file
    local timestamp
    timestamp="$(date -Iseconds)"

    # Add header if new file
    if [[ ! -f "$FEEDBACK_FILE" ]]; then
        echo "Timestamp,Overall,Ease,Comments" > "$FEEDBACK_FILE"
    fi

    # Append data
    echo "${timestamp},${rating_overall},${rating_ease},\"${comments}\"" >> "$FEEDBACK_FILE"

    echo ""
    log_success "Thank you! Your feedback has been saved to $FEEDBACK_FILE"
    echo ""
}

main() {
    # Only run in interactive mode or if explicitly requested via arg
    local interactive=0
    for arg in "$@"; do
        if [[ "$arg" == "--interactive" ]]; then
            interactive=1
        fi
    done

    if (( interactive == 1 )); then
        collect_feedback
    else
        # If not interactive but script run, assume intent unless in a non-interactive shell?
        # Check if stdin is tty
        if [[ -t 0 ]]; then
            collect_feedback
        else
            echo "Non-interactive shell, skipping feedback."
        fi
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
