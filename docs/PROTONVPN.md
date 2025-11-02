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

4. **Configure Auto-Connect** (recommended):
   - Open ProtonVPN app → Settings → Connection
   - Enable "Auto-connect"
   - Select your preferred server or "Quick Connect"
   - Enable "Start minimized" to keep the app in system tray

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

**Note**: ProtonVPN automatically creates an IPv6 leak protection interface (`ipv6leakintrf0`) that routes IPv6 traffic to a black hole, preventing IPv6 leaks even when IPv6 is enabled system-wide.

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

### Issue: Offline or restricted network (cannot fetch key)

If both remote key URLs are blocked, the installer now falls back to local key files if present. Place one of these files at the repository root and rerun the installer:

```
protonvpn_public_key.asc
protonvpn_stable_public_key.asc
```

The script will dearmor the local file into:

```
/usr/share/keyrings/proton-vpn-stable-archive-keyring.gpg
```

Tip: If you have another machine with internet access, download the key and copy it over:

```bash
wget -O protonvpn_public_key.asc https://repo.protonvpn.com/debian/public_key.asc
# Copy this file to your ubuntu-bootstrap directory on the offline host
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

## Security Analysis

### Connection Architecture

ProtonVPN uses a **dynamic connection model**:
- Connections are created on-demand by the daemon
- Stored in `/run/NetworkManager/` (temporary, RAM-based)
- Automatically removed when disconnected
- Managed by `me.proton.vpn.split_tunneling.service`

### Security Features Verified

1. **IPv6 Leak Protection**: ✅ Active
   - Dummy interface `pvpn-killswitch-ipv6` created
   - IPv6 traffic routed to black hole (fdeb:446c:912d:8da::1)
   - Confirmed: No IPv6 leaks

2. **DNS Configuration**: ✅ Secure
   - ProtonVPN DNS: 10.2.0.1
   - DNS priority: -1500 (high priority)
   - Catch-all domain: `~` (all queries)

3. **WireGuard Protocol**: ✅ Modern
   - Using WireGuard (fast, secure)
   - Interface: `proton0`

4. **Repository Security**: ✅ Verified
   - GPG key: RSA 3072-bit (expires 2027-03-03)
   - Fingerprint: 84B0D3492C76C9C6F5873C18EDA3E22630349F1C
   - HTTPS repository (Cloudflare CDN)

### Auto-Start Configuration

The bootstrap installer automatically configures:
- **Daemon**: Enabled (`me.proton.vpn.split_tunneling.service`)
- **GUI Auto-Start**: `~/.config/autostart/proton-vpn.desktop`
- **NetworkManager Auto-Connect**: Enabled on VPN connections

**For pre-login auto-connect**, configure in the ProtonVPN GUI:
- Settings → Connection → Enable "Auto-connect"
- This persists across reboots and sessions

### Important Notes

1. **Dynamic Connections**: ProtonVPN connections are ephemeral
   - Created when you connect via GUI/daemon
   - Removed when disconnected
   - Permissions changes don't persist across reconnections

2. **Kill Switch**: Must be enabled in GUI
   - Settings → Advanced → Kill Switch
   - Creates iptables rules to block non-VPN traffic
   - Recommended for maximum security

3. **System-Wide vs User**: 
   - Connections are user-specific by default
   - System-wide connections require GUI configuration
   - Auto-connect setting is stored in ProtonVPN's config

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
