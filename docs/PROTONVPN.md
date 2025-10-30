# ProtonVPN Installation Guide

## Overview

The `protonvpn.sh` script installs the official ProtonVPN app on Ubuntu 24.04, including:
- ProtonVPN daemon (background service)
- GTK GUI application (`protonvpn-app`)
- Split tunneling support

## Quick Start

### Installation

Run the ProtonVPN installation script:

```bash
cd /home/tg/ubuntu-bootstrap
sudo bash scripts/optional-features/protonvpn.sh
```

Or as part of the full bootstrap process:

```bash
sudo bash scripts/run_bootstrap.sh
```

### First Time Setup

1. **Launch the GUI**:
   ```bash
   protonvpn-app
   ```
   Or find "Proton VPN" in your Applications menu.

2. **Sign in** with your Proton account credentials.

3. **Connect** to a VPN server using the GUI.

## Usage

### GUI Application

- **Launch**: `protonvpn-app` or Applications → Proton VPN
- **Connect**: Click on a server or use Quick Connect
- **Disconnect**: Click Disconnect button
- **Settings**: Access split tunneling, kill switch, and other features

### Service Management

The ProtonVPN daemon runs as a systemd service:

```bash
# Check service status
systemctl status me.proton.vpn.split_tunneling.service

# View service logs
journalctl -u me.proton.vpn.split_tunneling.service -f

# Restart service (if needed)
sudo systemctl restart me.proton.vpn.split_tunneling.service
```

## Features

### Split Tunneling

Configure which apps bypass the VPN:
1. Open ProtonVPN GUI
2. Go to Settings → Split Tunneling
3. Add applications to exclude from VPN

### Kill Switch

Prevent traffic leaks if VPN disconnects:
1. Open ProtonVPN GUI
2. Go to Settings → Advanced
3. Enable Kill Switch

## Verification

Check if ProtonVPN is properly installed:

```bash
# Check GUI is available
command -v protonvpn-app && echo "✓ GUI installed"

# Check service is running
systemctl is-active me.proton.vpn.split_tunneling.service

# Verify connection (when connected)
curl https://api.ipify.org && echo
```

## Troubleshooting

### Issue: GUI won't launch

**Solution**: Check if the service is running:
```bash
sudo systemctl restart me.proton.vpn.split_tunneling.service
protonvpn-app
```

### Issue: Connection fails

**Solutions**:
1. Check your internet connection
2. Try a different server
3. Restart the VPN daemon:
   ```bash
   sudo systemctl restart me.proton.vpn.split_tunneling.service
   ```
4. Check logs:
   ```bash
   journalctl -u me.proton.vpn.split_tunneling.service -n 50
   ```

### Issue: Split tunneling not working

**Solution**: 
1. Ensure the service is running
2. Restart the service after configuration changes
3. Check that the app has proper permissions

### Issue: Repository key errors during installation

The script automatically handles key refresh. If you still see errors:

```bash
# Manually refresh the key
wget -qO- https://repo.protonvpn.com/debian/public_key.asc | \
  sudo gpg --batch --yes --dearmor -o \
  /usr/share/keyrings/proton-vpn-stable-archive-keyring.gpg

# Update package list
sudo apt update
```

## Uninstallation

To completely remove ProtonVPN:

```bash
cd /home/tg/ubuntu-bootstrap
source scripts/optional-features/protonvpn.sh
uninstall_protonvpn
```

Or manually:

```bash
# Stop and disable service
sudo systemctl stop me.proton.vpn.split_tunneling.service
sudo systemctl disable me.proton.vpn.split_tunneling.service

# Remove packages
sudo apt remove -y proton-vpn-gnome-desktop proton-vpn-gtk-app proton-vpn-daemon

# Remove repository
sudo rm -f /etc/apt/sources.list.d/protonvpn-stable.list
sudo rm -f /usr/share/keyrings/proton-vpn-stable-archive-keyring.gpg
sudo apt update
```

## Advanced Usage

### Headless/Server Usage

The official ProtonVPN app is GUI-focused. For headless servers, consider:

1. **Manual WireGuard/OpenVPN configs**: Download from Proton account
2. **Third-party CLI tools**: Community-maintained alternatives
3. **Web dashboard**: Manage connections via browser

### Dry Run Mode

Test the installation without making changes:

```bash
DRY_RUN=1 bash scripts/optional-features/protonvpn.sh
```

## Notes

- **Legacy CLI**: The old community `protonvpn-cli` is NOT included in the official app
- **Ubuntu 24.04+**: This script is tested on Ubuntu 24.04 LTS
- **Debian/Ubuntu**: Works on Debian-based distributions
- **Account Required**: You need a Proton account (free or paid)

## Resources

- [ProtonVPN Official Site](https://protonvpn.com/)
- [ProtonVPN Support](https://protonvpn.com/support/)
- [ProtonVPN GitHub](https://github.com/ProtonVPN)

## Script Details

**Location**: `scripts/optional-features/protonvpn.sh`

**Functions**:
- `install_protonvpn()`: Main installation logic
- `verify_protonvpn()`: Checks installation success
- `uninstall_protonvpn()`: Complete removal

**Dependencies**: 
- `hardware/common.sh`: Shared utility functions
- `wget`, `gpg`: For repository setup
