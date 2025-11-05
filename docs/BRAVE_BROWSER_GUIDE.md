# Brave Browser - Quick Reference Guide

## Overview

Brave Browser is a privacy-focused, open-source web browser built on Chromium with built-in ad blocking and tracking protection.

**Installed Version:** 142.1.84.132  
**Installation Date:** November 5, 2025

---

## Installation

### Automated Installation

```bash
# Using the bootstrap script
sudo bash scripts/optional-features/brave.sh

# Or from the main bootstrap menu
./scripts/run_bootstrap.sh
# Select: Optional Features → Brave Browser
```

### Manual Installation

```bash
# Add Brave repository
sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
    https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | \
    sudo tee /etc/apt/sources.list.d/brave-browser-release.list

# Install
sudo apt update
sudo apt install brave-browser
```

---

## Usage

### Launch Brave

**From Terminal:**
```bash
brave-browser
```

**From Application Menu:**
- Open applications menu
- Search for "Brave"
- Click to launch

### Command Line Options

```bash
# Open specific URL
brave-browser https://example.com

# Open in private (Tor) window
brave-browser --incognito --tor

# Open with specific profile
brave-browser --profile-directory="Profile 1"

# Start with DevTools open
brave-browser --auto-open-devtools-for-tabs

# Disable GPU acceleration (if issues)
brave-browser --disable-gpu

# Run in headless mode (testing/automation)
brave-browser --headless --screenshot https://example.com
```

---

## Privacy Features

### Built-in Ad & Tracker Blocking

**Default Shields:**
- Blocks ads and trackers
- Upgrades connections to HTTPS
- Blocks scripts (configurable)
- Blocks fingerprinting
- Blocks cookies (configurable)

**Shield Levels:**
- **Aggressive:** Maximum blocking (may break sites)
- **Standard:** Balanced protection (default)
- **Allow:** Disable shields for specific sites

### Brave Rewards (Optional)

- Earn BAT (Basic Attention Token) for viewing privacy-respecting ads
- Support content creators
- **Disabled by default** - must opt-in

### Private Browsing with Tor

**Features:**
- Routes traffic through Tor network
- Hides IP address
- Access .onion sites
- DuckDuckGo as default search

**Launch Tor Window:**
```bash
brave-browser --incognito --tor

# Or: Menu → New Private Window with Tor
```

**Limitations:**
- Slower browsing speed
- Some sites may block Tor exit nodes
- JavaScript disabled by default in Tor windows

---

## Configuration

### Settings Location

**Profile Directory:**
```
~/.config/BraveSoftware/Brave-Browser/
```

**Main Files:**
- `Default/Preferences` - Browser settings
- `Default/Bookmarks` - Bookmark data
- `Default/History` - Browsing history
- `Default/Extensions/` - Installed extensions

### Sync Settings

**Enable Sync:**
1. Settings → Sync → Start a new Sync Chain
2. Generate sync code or scan QR code
3. Add devices using the code

**What Syncs:**
- Bookmarks
- Extensions
- History
- Settings
- Passwords (optional)
- Open tabs

### Search Engine

**Default:** DuckDuckGo (privacy-focused)

**Change Search Engine:**
1. Settings → Search engine
2. Select from dropdown or add custom

**Popular Privacy-Focused Options:**
- DuckDuckGo
- Startpage
- Brave Search
- Qwant

---

## Extensions

### Chromium Extension Support

Brave supports all Chrome Web Store extensions.

**Install Extensions:**
1. Visit [Chrome Web Store](https://chrome.google.com/webstore)
2. Click "Add to Brave"

**Recommended Privacy Extensions:**
- uBlock Origin (extra blocking)
- Privacy Badger
- HTTPS Everywhere (built-in, but extension adds features)
- Bitwarden (password manager)
- Decentraleyes

**Note:** Many extension features are built into Brave's Shields.

---

## Keyboard Shortcuts

### General

| Shortcut | Action |
|----------|--------|
| `Ctrl+T` | New tab |
| `Ctrl+N` | New window |
| `Ctrl+Shift+N` | New private window |
| `Ctrl+Shift+Alt+N` | New Tor window |
| `Ctrl+W` | Close tab |
| `Ctrl+Shift+T` | Reopen closed tab |
| `Ctrl+Tab` | Next tab |
| `Ctrl+Shift+Tab` | Previous tab |
| `Ctrl+1-8` | Switch to tab 1-8 |
| `Ctrl+9` | Switch to last tab |

### Navigation

| Shortcut | Action |
|----------|--------|
| `Ctrl+L` | Focus address bar |
| `Alt+Left` | Back |
| `Alt+Right` | Forward |
| `F5` or `Ctrl+R` | Reload |
| `Ctrl+Shift+R` | Hard reload (bypass cache) |
| `Ctrl+D` | Bookmark page |
| `Ctrl+Shift+D` | Bookmark all tabs |

### Developer Tools

| Shortcut | Action |
|----------|--------|
| `F12` or `Ctrl+Shift+I` | Open DevTools |
| `Ctrl+Shift+J` | Open Console |
| `Ctrl+Shift+C` | Inspect element |
| `Ctrl+U` | View page source |

---

## Shields Configuration

### Per-Site Shields

**Adjust Shields for Current Site:**
1. Click Brave icon in address bar
2. Toggle individual protections
3. Settings persist per site

**Advanced View:**
- Click "Advanced View" in Shields panel
- See blocked resources count
- Detailed blocking statistics

### Global Shields Defaults

**Location:** Settings → Shields

**Options:**
- **Trackers & ads blocking:** Standard/Aggressive/Disabled
- **Upgrade connections to HTTPS:** On/Off
- **Block Scripts:** On/Off
- **Block Fingerprinting:** Standard/Strict/Off
- **Block Cookies:** All/3rd party/None

---

## Troubleshooting

### Site Not Working

**Common Fix:**
1. Click Brave icon in address bar
2. Click "Shields Down" for this site
3. Reload page

**Granular Fix:**
1. Advanced View in Shields
2. Toggle specific protections
3. Test which setting is causing issue

### Performance Issues

```bash
# Disable hardware acceleration
brave-browser --disable-gpu

# Clear cache and cookies
Settings → Privacy and security → Clear browsing data

# Disable extensions
Settings → Extensions → Disable all → Test
```

### Brave Not Starting

```bash
# Check if process is running
ps aux | grep brave

# Kill hanging processes
killall brave-browser

# Reset settings (caution: loses data)
rm -rf ~/.config/BraveSoftware/Brave-Browser/

# Reinstall
sudo apt remove --purge brave-browser
sudo apt install brave-browser
```

### Update Issues

```bash
# Check current version
brave-browser --version

# Force update check
sudo apt update
sudo apt upgrade brave-browser

# Check repository
cat /etc/apt/sources.list.d/brave-browser-release.list
```

---

## Uninstallation

### Using Bootstrap Script

```bash
cd /home/tg/ubuntu-bootstrap-1
source scripts/optional-features/brave.sh
uninstall_brave
```

### Manual Uninstallation

```bash
# Remove package
sudo apt remove --purge brave-browser brave-keyring

# Remove repository
sudo rm /etc/apt/sources.list.d/brave-browser-release.list
sudo rm /usr/share/keyrings/brave-browser-archive-keyring.gpg

# Update package lists
sudo apt update

# Remove user data (optional)
rm -rf ~/.config/BraveSoftware/
rm -rf ~/.cache/BraveSoftware/
```

---

## Backup & Migration

### Backup Profile

```bash
# Backup entire profile
tar -czf brave-backup-$(date +%Y%m%d).tar.gz \
    ~/.config/BraveSoftware/Brave-Browser/

# Backup bookmarks only
cp ~/.config/BraveSoftware/Brave-Browser/Default/Bookmarks \
    ~/brave-bookmarks-$(date +%Y%m%d).json
```

### Restore Profile

```bash
# Restore full profile
tar -xzf brave-backup-YYYYMMDD.tar.gz -C ~/

# Import bookmarks
# Settings → Bookmarks → Import bookmarks and settings
```

### Migrate from Chrome/Firefox

**Import Data:**
1. Settings → Get started
2. Click "Import bookmarks and settings"
3. Select source browser
4. Choose what to import
5. Click "Import"

**What Can Be Imported:**
- Browsing history
- Favorites/Bookmarks
- Saved passwords
- Autofill data
- Search engines

---

## Brave vs Chrome

### Advantages

✅ **Privacy:**
- No Google tracking
- Built-in ad/tracker blocking
- Fingerprinting protection
- HTTPS upgrading

✅ **Performance:**
- Faster page loads (ads blocked)
- Lower memory usage
- Better battery life

✅ **Security:**
- Regular security updates
- Same Chromium security features
- Additional privacy protections

### Compatibility

✅ **Same as Chrome:**
- Chromium-based engine
- All Chrome extensions work
- Same DevTools
- PWA support

⚠️ **Differences:**
- Some Google services may work differently
- DRM content may require enabling
- Brave Rewards instead of Google Rewards

---

## Advanced Configuration

### Custom Flags

**Access:** `brave://flags/`

**Useful Flags:**
```
#enable-parallel-downloading - Faster downloads
#enable-quic - Faster connections
#smooth-scrolling - Better scroll experience
#enable-gpu-rasterization - Better graphics performance
```

### Developer Tools

**Remote Debugging:**
```bash
brave-browser --remote-debugging-port=9222
```

**Custom User Agent:**
```bash
brave-browser --user-agent="Custom Agent String"
```

### Profile Management

**Create New Profile:**
```bash
brave-browser --profile-directory="Work"
```

**List Profiles:**
```bash
ls ~/.config/BraveSoftware/Brave-Browser/
```

---

## Integration with Ubuntu

### Default Browser

**Set as Default:**
```bash
xdg-settings set default-web-browser brave-browser.desktop

# Or: Settings → Apps → Default apps → Web browser
```

### Desktop Entry

**Location:** `/usr/share/applications/brave-browser.desktop`

**Custom Desktop Entry:**
```bash
# Create custom launcher
cat > ~/.local/share/applications/brave-incognito.desktop <<'EOF'
[Desktop Entry]
Version=1.0
Name=Brave (Private)
Exec=brave-browser --incognito
Terminal=false
Type=Application
Icon=brave-browser
Categories=Network;WebBrowser;
EOF
```

---

## Security Best Practices

### Recommended Settings

1. **Shields:** Keep on "Standard" or "Aggressive"
2. **HTTPS-Only:** Enable in Settings → Security
3. **WebRTC:** Block in brave://settings/privacy
4. **Safe Browsing:** Enable Google Safe Browsing
5. **Passwords:** Use external password manager
6. **Extensions:** Minimize, review permissions

### Privacy Hardening

```
Settings → Privacy and security:
☑ Send a "Do Not Track" request
☑ HTTPS-Only Mode
☑ Disable WebRTC
☑ Block social media buttons
☑ Block autoplay
☐ Allow Google login (disable if not needed)
```

---

## Resources

### Official Links

- **Website:** https://brave.com
- **Support:** https://support.brave.com
- **Community:** https://community.brave.com
- **GitHub:** https://github.com/brave/brave-browser

### Documentation

- **Privacy Whitepaper:** https://brave.com/privacy-updates
- **Brave Rewards:** https://brave.com/brave-rewards
- **FAQ:** https://brave.com/faq

### Ubuntu Bootstrap Integration

- **Installation Script:** `scripts/optional-features/brave.sh`
- **Troubleshooting:** `docs/TROUBLESHOOTING.md`
- **Uninstall Guide:** `docs/UNINSTALL.md`

---

## Quick Tips

💡 **Performance:**
- Disable unused extensions
- Clear cache regularly
- Use tab groups for organization
- Enable hardware acceleration

💡 **Privacy:**
- Use Tor windows for sensitive browsing
- Clear data on exit (Settings → Privacy)
- Review site permissions regularly
- Use separate profiles for different purposes

💡 **Productivity:**
- Learn keyboard shortcuts
- Use vertical tabs (brave://flags)
- Enable tab groups
- Sync across devices

---

**Last Updated:** November 5, 2025  
**Brave Version:** 142.1.84.132  
**Ubuntu Version:** 24.04 LTS
