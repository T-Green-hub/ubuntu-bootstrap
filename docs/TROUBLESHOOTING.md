# Common Issues & Solutions

## APT Lock Issues

If you encounter APT lock errors:

```bash
E: Could not get lock /var/lib/dpkg/lock
E: Unable to lock the administration directory (/var/lib/dpkg/)
```

**Solutions:**

1. Let the runner handle it automatically (recommended):
   - The bootstrap runner temporarily stops background services that hold locks
   - Retries up to 6 times with exponential backoff
   - Restores services automatically on completion

2. Manual fix if needed:

```bash
sudo systemctl stop packagekit.service unattended-upgrades.service
sudo rm -f /var/lib/dpkg/lock* /var/lib/apt/lists/lock /var/cache/apt/archives/lock
sudo dpkg --configure -a
```

## Docker Group Issues

If you can't run Docker without sudo after installation:

First, verify group membership:

```bash
groups $USER | grep docker
```

Then, if missing, add yourself and re-login:

```bash
sudo usermod -aG docker $USER
# Then log out and back in
```

## PATH Issues

### Node.js (nvm)

If `node` or `npm` commands aren't found:

```bash
# Immediate fix
source ~/.nvm/nvm.sh

# Permanent fix (check if already present)
echo 'export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.bashrc
```

### Python (pyenv)

If `pyenv` isn't working:

```bash
# Immediate fix
source ~/.bashrc

# Verify PATH setup
grep -q "pyenv init" ~/.bashrc || {
  echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
  echo '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
  echo 'eval "$(pyenv init -)"' >> ~/.bashrc
}
```

### Go

If Go tools aren't found:

```bash
# Immediate fix
source ~/.bashrc

# Verify PATH setup
grep -q "/usr/local/go/bin" ~/.bashrc || {
  echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
  echo 'export GOPATH=$HOME/go' >> ~/.bashrc
  echo 'export PATH=$PATH:$GOPATH/bin' >> ~/.bashrc
}
```

### Rust

If Rust tools aren't found:

```bash
# Immediate fix
source "$HOME/.cargo/env"

# Permanent fix
grep -q ".cargo/env" ~/.bashrc || {
  echo 'source "$HOME/.cargo/env"' >> ~/.bashrc
}
```

## Network Timeouts

If you see network timeouts during installation:

First, check connectivity:

```bash
ping -c 1 1.1.1.1
ping -c 1 8.8.8.8
ping -c 1 github.com
```

Also, note that the bootstrap has built-in retry logic:

- All curl/wget calls retry 3 times
- apt_safe retries 6 times with backoff
- You can try again safely (scripts are idempotent)

## Battery Thresholds

If battery thresholds aren't working:

First, check if your hardware supports them:

```bash
ls /sys/class/power_supply/BAT0/charge_*_threshold
```

Then verify TLP config:

```bash
cat /etc/tlp.d/01-battery-thresholds.conf
sudo tlp-stat -b
```

## Hardware Profiles

If wrong hardware profile is selected:

First, check current detection:

```bash
sudo dmidecode -s system-manufacturer
sudo dmidecode -s system-product-name
```

Then if needed, force a specific profile:

```bash
HARDWARE_PROFILE=thinkpad-t14 bash scripts/50_laptop.sh
# or: hp-laptop-15, generic
```

## Selective Installation

To skip problematic tools:

```bash
# Skip specific numbered scripts
./scripts/run_bootstrap.sh --skip-script=40

# Install only specific dev tools
./scripts/40_dev-tools.sh docker nodejs
# Instead of all tools: docker nodejs python rust go vscode utilities
```

## Still Having Issues?

- Check logs under `logs/<timestamp>/`
- Set `LOG_DIR=/tmp/bootstrap-logs` for custom log location
- Use `DRY_RUN=1` to preview actions
- Report issues on GitHub with log output
