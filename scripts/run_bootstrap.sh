#!/usr/bin/env bash
# Complete bootstrap runner (idempotent).
# Auto-discovers and runs all numbered scripts in order, then verification.
# Usage: ./run_bootstrap.sh [--dry-run] [--skip-script=NN]
# Version: 0.2.0

set -euo pipefail
IFS=$'\n\t'

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS_DIR="$REPO_DIR/scripts"
DRY_RUN="${DRY_RUN:-0}"  # Support environment variable
declare -a SKIP_SCRIPTS=()

log(){ printf '[%s] %s\n' "$(date -Iseconds)" "$*"; }

# Network connectivity preflight
check_network() {
  log "Checking network connectivity…"

  # Try multiple DNS servers
  local test_hosts=("1.1.1.1" "8.8.8.8" "github.com")
  local connected=0

  for host in "${test_hosts[@]}"; do
    if ping -c 1 -W 2 "$host" >/dev/null 2>&1; then
      log "✓ Network OK (reached $host)"
      connected=1
      break
    fi
  done

  if (( connected == 0 )); then
    log "ERROR: No network connectivity detected. Please check your connection."
    log "Tested: ${test_hosts[*]}"
    return 1
  fi

  return 0
}

# Optional per-run logging directory (defaults to repo logs/<timestamp>)
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
if [[ -z "${LOG_DIR:-}" ]]; then
  # default to repo logs dir; fall back to no logging if creation fails
  DEFAULT_LOG_DIR="$REPO_DIR/logs/$TIMESTAMP"
  if mkdir -p "$DEFAULT_LOG_DIR" 2>/dev/null; then
    LOG_DIR="$DEFAULT_LOG_DIR"
    log "Logging to: $LOG_DIR"
  else
    LOG_DIR=""
    log "WARNING: Could not create log directory, proceeding without logging"
  fi
else
  # Respect user-provided LOG_DIR; attempt to create if missing
  if mkdir -p "$LOG_DIR" 2>/dev/null; then
    log "Using custom log directory: $LOG_DIR"
  else
    log "WARNING: Cannot create LOG_DIR='$LOG_DIR', logging disabled"
    LOG_DIR=""
  fi
fi

log_file_for_script() {
  local script_name="$1"
  local script_num="${script_name:0:2}"
  local base="${script_name%.sh}"
  echo "$LOG_DIR/${script_num}_${base}.log"
}

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

# Temporarily stop services that commonly hold apt/dpkg locks
setup_apt_guard() {
  local units=(
    packagekit.service
    unattended-upgrades.service
    apt-daily.service
    apt-daily-upgrade.service
    apt-daily.timer
    apt-daily-upgrade.timer
  )
  log "Applying apt/dpkg lock guard: stopping PackageKit and unattended-upgrades timers/services temporarily"
  for u in "${units[@]}"; do
    if systemctl list-unit-files | awk '{print $1}' | grep -qx "$u"; then
      if [[ "$DRY_RUN" -eq 1 ]]; then
        log "  [DRY RUN] Would stop $u"
      else
        sudo systemctl stop "$u" >/dev/null 2>&1 || true
      fi
    fi
  done
}

restore_apt_guard() {
  local units=(
    apt-daily.timer
    apt-daily-upgrade.timer
    apt-daily.service
    apt-daily-upgrade.service
    unattended-upgrades.service
    packagekit.service
  )
  log "Restoring apt/dpkg services/timers (best effort)"
  for u in "${units[@]}"; do
    if systemctl list-unit-files | awk '{print $1}' | grep -qx "$u"; then
      if [[ "$DRY_RUN" -eq 1 ]]; then
        log "  [DRY RUN] Would start $u"
      else
        sudo systemctl start "$u" >/dev/null 2>&1 || true
      fi
    fi
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
      skip_value="${1#*=}"
      # Validate that skip value is a 2-digit number
      if [[ ! "$skip_value" =~ ^[0-9][0-9]$ ]]; then
        log "ERROR: --skip-script requires a 2-digit number (e.g., --skip-script=40)"
        log "Invalid value: '$skip_value'"
        exit 1
      fi
      SKIP_SCRIPTS+=("$skip_value")
      shift
      ;;
    --help)
      echo "ubuntu-bootstrap runner v0.2.0"
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --dry-run           Show what would be done without making changes"
      echo "  --skip-script=NN    Skip a specific script (e.g., --skip-script=40)"
      echo "  --help              Show this help message"
      echo ""
      echo "Environment Variables:"
      echo "  DRY_RUN=1           Enable dry-run mode"
      echo "  LOG_DIR=/path       Override log directory (default: logs/<timestamp>)"
      echo "  STRICT=1            Fail on non-critical warnings (default: exit 0)"
      echo ""
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

# Network preflight (skip in dry-run)
if [[ $DRY_RUN -eq 0 ]]; then
  if ! check_network; then
    log "Network check failed. Bootstrap requires internet connectivity."
    exit 1
  fi
fi

# Guard against apt/dpkg locks from background services for the duration of the run
setup_apt_guard
trap restore_apt_guard EXIT

for i in "${!scripts[@]}"; do
  script="${scripts[$i]}"
  script_name=$(basename "$script")
  script_num="${script_name:0:2}"  # Extract NN from NN_name.sh
  step=$((i + 1))
  total=${#scripts[@]}

  # Check if this script should be skipped
  # Check if this script number is in the SKIP_SCRIPTS array
  skip_this=0
  for s in "${SKIP_SCRIPTS[@]}"; do
    if [[ "$s" == "$script_num" ]]; then
      skip_this=1
      break
    fi
  done
  if [[ $skip_this -eq 1 ]]; then
    log "[$step/$total] Skipping $script_name (--skip-script=$script_num)"
    SKIPPED_SCRIPTS+=("$script_name")
    echo ""
    continue
  fi

  log "[$step/$total] Running $script_name…"
  # Best-effort wait to avoid apt/dpkg lock contention between scripts
  wait_for_dpkg_lock 180

  success_label="$script_name"
  if [[ $DRY_RUN -eq 1 ]]; then
    log "  [DRY RUN] Would execute: bash $script"
    # Optionally record dry-run in logfile
    if [[ -n "$LOG_DIR" ]]; then
      printf '[%s] [DRY RUN] Would execute: %s\n' "$(date -Iseconds)" "$script" >> "$(log_file_for_script "$script_name")" || true
    fi
    success_label="$script_name (dry-run)"
    exit_code=0
  else
    # Execute with optional tee logging
    if [[ -n "$LOG_DIR" ]]; then
      logfile="$(log_file_for_script "$script_name")"
      log "  Logging to: $logfile"
      set +e
      bash "$script" 2>&1 | tee -a "$logfile"
      exit_code=${PIPESTATUS[0]}
      set -e
    else
      if bash "$script"; then exit_code=0; else exit_code=$?; fi
    fi
  fi

  if (( exit_code == 0 )); then
    SUCCESS_SCRIPTS+=("$success_label")
  else
    log "ERROR: $script_name failed with exit code $exit_code"
    log "  Script path: $script"
    log "  Step: $step/$total"
    if [[ -n "$LOG_DIR" ]]; then
      log "  Check log: $(log_file_for_script "$script_name")"
    fi
    FAILED_SCRIPTS+=("$script_name")

    # Exit on critical failures (exit codes 1-10 are critical)
    if (( exit_code <= 10 )); then
      log "CRITICAL FAILURE - stopping bootstrap."
      log "  You can retry with: --skip-script=$script_num"
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
