# Post‑Install Guide: Best Order and Practices

This guide helps you finalize your setup after running the bootstrap. It focuses on the right order to apply changes, what to verify, and small tweaks that prevent headaches later.

Applies to Ubuntu 24.04 desktop/laptop with this repository. Adjust where noted for headless/servers.

## TL;DR: Recommended Order

1) Reboot or re-login (if prompted)
- Reboot if the bootstrap upgraded the kernel, NVIDIA drivers, or firmware
- Log out/in to refresh groups (Docker) and environment vars (nvm, pyenv)

2) Create a baseline snapshot (TimeShift)
- Create your first snapshot before heavy changes
- Schedule weekly (rsync), exclude large transient dirs (node_modules, .venv)

3) Privacy and network
- ProtonVPN: sign in, enable Kill Switch, set Auto-Connect, configure Split Tunneling
- Confirm daemon status and public IP change when connected

4) Developer environments
- Node.js: source nvm, install LTS, test npm
- Python: source pyenv setup, create a venv, test pip
- Docker: verify group access (no sudo), run hello-world
- Rust/Go: source envs, build a hello binary

5) System updates & health
- apt update/upgrade, enable unattended-upgrades
- Verify TRIM, sensors, SMART, fstrim.timer

6) Backup settings & dotfiles
- Save VS Code settings, shell configs, and secrets appropriately

## Desktop Profiles: Two Good Orders

- Performance-first (faster overall):
  1. Base + Drivers → Dev Tools → Optional Features → Verify → Post‑install steps

- Privacy-first (security earlier):
  1. Base + Drivers → Optional Features (ProtonVPN, Brave, TimeShift) → Dev Tools → Verify → Post‑install steps

Note: Both orders are supported here. Use `make privacy-first` if you prefer privacy-first.

## Detailed Checklist

### 1) Reboot / Re-login
- Reboot if prompted after GPU/Kernel updates:
  ```bash
  sudo reboot
  ```
- Always log out/in to activate new group memberships (Docker) and environment updates.

### 2) TimeShift Snapshot
- Create a first snapshot:
  ```bash
  sudo timeshift --create --comments "Baseline" --tags D
  ```
- Recommended excludes (GUI → Settings → Filters):
  - node_modules, .venv, .cache, .cargo/registry, .npm, .gradle, target, build
- Schedule: weekly rsync; optionally daily if you iterate a lot.

### 3) ProtonVPN Configuration
- Launch the GUI and sign in:
  ```bash
  protonvpn-app
  ```
- Settings to enable:
  - Kill Switch: ON
  - Auto-Connect: Your preferred profile (e.g., Fastest)
  - Split Tunneling: Add heavy downloaders or LAN tools if needed
- Verify daemon and service state:
  ```bash
  systemctl is-active me.proton.vpn.split_tunneling.service
  systemctl is-enabled me.proton.vpn.split_tunneling.service
  ```
- Verify your public IP when connected:
  ```bash
  curl https://api.ipify.org && echo
  ```

### 4) Developer Tooling Smoke Tests

Node.js (nvm):
```bash
source ~/.nvm/nvm.sh
node -v && npm -v
npm init -y >/dev/null 2>&1 && npm test || true
```

Python (pyenv):
```bash
source ~/.bashrc
pyenv --version
python3 -V && python3 -m venv /tmp/p && /tmp/p/bin/python -V
```

Docker:
```bash
groups $USER | grep -q docker || echo "Add yourself to docker group and re-login: sudo usermod -aG docker $USER"
docker run --rm hello-world || echo "If this requires sudo, re-login first"
```

Rust:
```bash
source "$HOME/.cargo/env"
rustc --version && cargo --version
```

Go:
```bash
source ~/.bashrc
go version
```

### 5) Updates & Health
- Keep packages fresh:
  ```bash
  sudo apt update && sudo apt upgrade -y
  ```
- Enable unattended upgrades (if not already):
  ```bash
  sudo apt install -y unattended-upgrades
  sudo dpkg-reconfigure -plow unattended-upgrades
  ```
- Re-run verification:
  ```bash
  make verify
  ```

### 6) Backup and Dotfiles
- Back up:
  - ~/.config/Code/User/settings.json
  - ~/.bashrc, ~/.profile, ~/.gitconfig
  - SSH keys in ~/.ssh (never commit to public repos)
- Consider a private dotfiles repo or a secure backup solution (e.g., encrypted archive).

## Headless/Server Notes
- The ProtonVPN GUI app targets desktops. For headless use, prefer:
  - Manual WireGuard configs from Proton account
  - Or a community CLI (not included here)
- TimeShift is workstation-centric; for servers, use filesystem snapshots (ZFS/Btrfs) or restic/borg.

## Troubleshooting Quickies
- Docker still needs sudo: re-login to pick up docker group membership
- Node/Python/Rust/Go not found: source envs (nvm, .bashrc, .cargo/env)
- ProtonVPN not connecting: restart daemon and check logs
  ```bash
  sudo systemctl restart me.proton.vpn.split_tunneling.service
  journalctl -u me.proton.vpn.split_tunneling.service -n 100 --no-pager
  ```

## Links
- Quick Start: docs/QUICK_START.md
- ProtonVPN: docs/PROTONVPN.md, docs/PROTONVPN_QUICK_REF.md
- Troubleshooting: docs/TROUBLESHOOTING.md
