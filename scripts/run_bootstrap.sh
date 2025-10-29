#!/usr/bin/env bash
# Complete bootstrap runner (idempotent).
# Auto-discovers and runs all numbered scripts in order, then verification.
# Usage: ./run_bootstrap.sh [--dry-run] [--skip-script=NN]

set -euo pipefail
IFS=$'\n\t'

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS_DIR="$REPO_DIR/scripts"
DRY_RUN="${DRY_RUN:-0}"  # Support environment variable
declare -a SKIP_SCRIPTS=()

log(){ printf '[%s] %s\n' "$(date -Iseconds)" "$*"; }

# Global dpkg/apt lock wait to avoid cross-script contention
wait_for_dpkg_lock() {
  local timeout="${1:-180}"
  local waited=0
  local lock_frontend="/var/lib/dpkg/lock-frontend"
  local lock_db="/var/lib/dpkg/lock"
  local has_fuser=0
  local has_lsof=0
  command -v fuser >/dev/null 2>&1 && has_fuser=1
  command -v lsof >/dev/null 2>&1 && has_lsof=1
  while true; do
    local busy=0
    if (( has_fuser )); then
      if sudo -n fuser "$lock_frontend" "$lock_db" >/dev/null 2>&1; then busy=1; fi
    elif (( has_lsof )); then
      if sudo -n lsof "$lock_frontend" "$lock_db" >/dev/null 2>&1; then busy=1; fi
    else
      if pgrep -x apt-get >/dev/null 2>&1 || pgrep -x apt >/dev/null 2>&1 || pgrep -x dpkg >/dev/null 2>&1 || pgrep -x unattended-upgrade >/dev/null 2>&1; then busy=1; fi
    fi
    if (( busy == 0 )); then break; fi
    if (( waited == 0 )); then log "Waiting for dpkg/apt lock to be released…"; fi
    sleep 2; waited=$((waited+2))
    if (( waited >= timeout )); then log "Timeout waiting for dpkg lock after ${timeout}s; proceeding anyway."; break; fi
  done
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      log "DRY RUN MODE - no changes will be made"
      shift
      ;;
    --skip-script=*)
      SKIP_SCRIPTS+=("${1#*=}")
      shift
      ;;
    --help)
      echo "Usage: $0 [OPTIONS]"
      echo "Options:"
      echo "  --dry-run           Show what would be done without making changes"
      echo "  --skip-script=NN    Skip a specific script (e.g., --skip-script=40)"
      echo "  --help              Show this help message"
      exit 0
      ;;
    *)
      log "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Track success/failure
declare -a FAILED_SCRIPTS=()
declare -a SUCCESS_SCRIPTS=()
declare -a SKIPPED_SCRIPTS=()

# Collect all numbered scripts (00-99) that are non-empty
mapfile -t scripts < <(
  find "$SCRIPTS_DIR" -maxdepth 1 -name '[0-9][0-9]_*.sh' -type f | 
  while read -r script; do
    if [[ -s "$script" ]]; then  # Only include non-empty files
      echo "$script"
    fi
  done | sort
)

if [[ ${#scripts[@]} -eq 0 ]]; then
  log "No scripts found to run."
  exit 1
fi

log "Bootstrap sequence: ${#scripts[@]} scripts"
echo ""

for i in "${!scripts[@]}"; do
  script="${scripts[$i]}"
  script_name=$(basename "$script")
  script_num="${script_name:0:2}"  # Extract NN from NN_name.sh
  step=$((i + 1))
  total=${#scripts[@]}
  
  # Check if this script should be skipped
  if [[ " ${SKIP_SCRIPTS[*]} " =~ " ${script_num} " ]]; then
    log "[$step/$total] Skipping $script_name (--skip-script=$script_num)"
    SKIPPED_SCRIPTS+=("$script_name")
    echo ""
    continue
  fi
  
  log "[$step/$total] Running $script_name…"
  # Best-effort wait to avoid apt/dpkg lock contention between scripts
  wait_for_dpkg_lock 180
  
  if [[ $DRY_RUN -eq 1 ]]; then
    log "  [DRY RUN] Would execute: bash $script"
    SUCCESS_SCRIPTS+=("$script_name (dry-run)")
  elif bash "$script"; then
    SUCCESS_SCRIPTS+=("$script_name")
  else
    exit_code=$?
    log "ERROR: $script_name failed with exit code $exit_code"
    FAILED_SCRIPTS+=("$script_name")
    
    # Exit on critical failures (exit codes 1-10 are critical)
    if (( exit_code <= 10 )); then
      log "CRITICAL FAILURE - stopping bootstrap."
      exit "$exit_code"
    else
      log "Non-critical failure - continuing with next script."
    fi
  fi
  echo ""
done

# Summary
log "=== Bootstrap Summary ==="
log "Successful: ${#SUCCESS_SCRIPTS[@]}/${#scripts[@]}"
for script in "${SUCCESS_SCRIPTS[@]}"; do
  log "  ✓ $script"
done

if [[ ${#SKIPPED_SCRIPTS[@]} -gt 0 ]]; then
  log "Skipped: ${#SKIPPED_SCRIPTS[@]}"
  for script in "${SKIPPED_SCRIPTS[@]}"; do
    log "  ⊘ $script"
  done
fi

if [[ ${#FAILED_SCRIPTS[@]} -gt 0 ]]; then
  log "Failed (non-critical): ${#FAILED_SCRIPTS[@]}"
  for script in "${FAILED_SCRIPTS[@]}"; do
    log "  ✗ $script"
  done
  log "bootstrap completed with warnings."
  # By default, treat warnings as success; set STRICT=1 to fail on warnings
  if [[ "${STRICT:-0}" -eq 1 ]]; then
    exit 1
  else
    exit 0
  fi
else
  if [[ $DRY_RUN -eq 1 ]]; then
    log "bootstrap dry-run complete!"
  else
    log "bootstrap run complete - all scripts succeeded!"
  fi
fi
