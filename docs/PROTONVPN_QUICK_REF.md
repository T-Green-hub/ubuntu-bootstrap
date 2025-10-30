# ProtonVPN Quick Reference

## Installation

```bash
# Install ProtonVPN
sudo bash scripts/optional-features/protonvpn.sh

# Test installation (dry run)
DRY_RUN=1 bash scripts/optional-features/protonvpn.sh

# Verify installation
bash -c 'source scripts/optional-features/protonvpn.sh && verify_protonvpn'
```

## Common Commands

### Launch GUI
```bash
protonvpn-app
```

### Service Management
```bash
# Check service status
systemctl status me.proton.vpn.split_tunneling.service

# View logs
journalctl -u me.proton.vpn.split_tunneling.service -f

# Restart service
sudo systemctl restart me.proton.vpn.split_tunneling.service

# Stop service
sudo systemctl stop me.proton.vpn.split_tunneling.service
```

### Verification
```bash
# Check if GUI is installed
command -v protonvpn-app && echo "✓ GUI installed"

# Check service status
systemctl is-active me.proton.vpn.split_tunneling.service

# Check your IP (when connected)
curl https://api.ipify.org && echo
```

## Uninstallation

```bash
# Complete removal
cd /home/tg/ubuntu-bootstrap
source scripts/optional-features/protonvpn.sh
uninstall_protonvpn
```

## Troubleshooting

### GUI Won't Launch
```bash
sudo systemctl restart me.proton.vpn.split_tunneling.service
protonvpn-app
```

### Connection Issues
```bash
# Check logs for errors
journalctl -u me.proton.vpn.split_tunneling.service -n 50 --no-pager

# Try different server
# Restart daemon
sudo systemctl restart me.proton.vpn.split_tunneling.service
```

### Repository Key Errors
```bash
# Manually refresh key
wget -qO- https://repo.protonvpn.com/debian/public_key.asc | \
  sudo gpg --batch --yes --dearmor -o \
  /usr/share/keyrings/proton-vpn-stable-archive-keyring.gpg

sudo apt update
```

Offline/restricted networks:
```
# Put one of these files in the repo root and rerun installer
protonvpn_public_key.asc
protonvpn_stable_public_key.asc
```

## Files & Locations

```
Script:       scripts/optional-features/protonvpn.sh
Docs:         docs/PROTONVPN.md
Service:      me.proton.vpn.split_tunneling.service
Repository:   /etc/apt/sources.list.d/protonvpn-stable.list
Keyring:      /usr/share/keyrings/proton-vpn-stable-archive-keyring.gpg
```

## Key Features

- **Split Tunneling**: Settings → Split Tunneling → Add apps to exclude
- **Kill Switch**: Settings → Advanced → Enable Kill Switch
- **Auto-Connect**: Settings → General → Enable Auto-Connect
- **Protocol**: Settings → Advanced → Choose OpenVPN or WireGuard

## Support Resources

- **Full Documentation**: docs/PROTONVPN.md
- **ProtonVPN Support**: https://protonvpn.com/support/
- **Service Logs**: `journalctl -u me.proton.vpn.split_tunneling.service`
