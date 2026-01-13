# Contributing to Ubuntu Bootstrap

Thanks for helping improve Ubuntu Bootstrap.

## Development Workflow

1. Fork the repo and create a feature branch: `git checkout -b feature/my-change`
2. Make your changes (keep them minimal and focused)
3. Run checks locally:
   - `make lint-light`
   - `make test`
   - `make test-quick`
4. Update documentation when behavior changes (README/docs + CHANGELOG.md)
5. Open a pull request against `main`

## Coding Standards (Bash)

- Use `set -euo pipefail` and quote variables (`"$VAR"`)
- Prefer `[[ ... ]]` for tests
- Keep scripts idempotent (safe to re-run)
- Do not bypass the privileged wrapper: use `run_privileged` for privileged ops
- In `--dry-run` and CI, do not call `sudo` or modify the system

## Tests

The self-test harness lives at `scripts/tests/self_test.sh` and is executed by `make test`.

- Add/extend tests when you add new scripts or change CLI flags
- Prefer timeouts and non-interactive execution (CI-safe)

## Commit Messages

Use clear, scoped messages:

- `fix: ...`
- `docs: ...`
- `ci: ...`
- `refactor: ...`

## Security

If you find a vulnerability, please follow SECURITY.md and use GitHub Security Advisories.
