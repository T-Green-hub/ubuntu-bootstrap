# Security Policy

## Supported Versions

| Version | Supported |
| ------- | --------- |
| 4.0.x   | Yes       |
| < 4.0   | No        |

## Reporting a Vulnerability

Preferred: Use GitHub Security Advisories.

- Go to the repository on GitHub → **Security** → **Advisories** → **Report a vulnerability**
- Include:
  - What you found and why it’s a security issue
  - Reproduction steps (commands, environment, expected/actual results)
  - Impact (what an attacker gains)
  - Any proposed fix or mitigation

If you cannot use Security Advisories, open a GitHub issue with **only non-sensitive details** and clearly mark it as security-related. Do not publish secrets, tokens, private keys, or exploit code.

## Response Targets

- Initial acknowledgement: within 48 hours
- Status update: within 7 days

## Security Notes

Ubuntu Bootstrap runs privileged operations.

- In CI / dry-run modes, privileged operations must be gated (no sudo prompts, no system changes).
- Avoid `eval` for command execution; prefer argv-safe execution.
