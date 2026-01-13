#!/usr/bin/env bash
# Privileged command wrapper for ubuntu-bootstrap
# Centralizes sudo/root gating for dry-run and CI safety.

# Determine whether privileged operations are allowed.
# Rules:
# - DRY_RUN=1: never attempt privilege escalation
# - CI_MODE=1 or CI env: forbid sudo unless ALLOW_SUDO=1
privileged_allowed() {
    if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
        return 1
    fi

    local ci_mode=0
    if [[ "${CI_MODE:-0}" -eq 1 ]] || [[ -n "${CI:-}" ]] || [[ -n "${GITHUB_ACTIONS:-}" ]] || [[ -n "${GITLAB_CI:-}" ]]; then
        ci_mode=1
    fi

    if (( ci_mode == 1 )) && [[ "${ALLOW_SUDO:-0}" -ne 1 ]]; then
        return 1
    fi

    return 0
}

# Check whether sudo credentials are cached (non-interactive).
# In dry-run/CI-forbid, this MUST NOT attempt sudo.
privileged_has_cached_sudo() {
    if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
        return 1
    fi

    if ! privileged_allowed; then
        return 1
    fi

    if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
        return 0
    fi

    sudo -n true >/dev/null 2>&1
}

# Run a command that requires privileges.
# In dry-run: records what would run.
# In CI-forbid: skips and records warning.
run_privileged() {
    if [[ $# -lt 1 ]]; then
        echo "run_privileged: missing command" >&2
        return 2
    fi

    if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
        echo "[DRY RUN] Would run privileged: $*" >&2
        if declare -F log_msg >/dev/null 2>&1; then
            log_msg "INFO" "[DRY RUN] Would run privileged: $*"
        fi
        return 0
    fi

    if ! privileged_allowed; then
        echo "[WARN] Skipping privileged command (CI forbids sudo unless ALLOW_SUDO=1): $*" >&2
        if declare -F log_warning >/dev/null 2>&1; then
            log_warning "Skipping privileged command (CI forbids sudo unless ALLOW_SUDO=1): $*"
        elif declare -F log_msg >/dev/null 2>&1; then
            log_msg "WARNING" "Skipping privileged command (CI forbids sudo unless ALLOW_SUDO=1): $*"
        fi
        return 0
    fi

    if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
        "$@"
        return $?
    fi

    sudo "$@"
}
