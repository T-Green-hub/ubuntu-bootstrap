# 🎯 Ubuntu Bootstrap - Visual Guide

**A picture is worth a thousand words!**

---

## 🎯 Which Path Is Right For You?

```
                  ╔════════════════════════════════╗
                  ║   WHICH PATH SHOULD I TAKE?    ║
                  ╚════════════════════════════════╝
                                  │
                                  ▼
                    ┌─────────────────────────┐
                    │  Are you brand new to   │
                    │  Ubuntu/Linux?          │
                    └─────────────┬───────────┘
                                  │
                    ┌─────────────┴───────────┐
                    │                         │
                   YES                       NO
                    │                         │
                    ▼                         ▼
          ┌───────────────────┐     ┌──────────────────┐
          │  SIMPLE START     │     │  Want menu or    │
          │  docs/            │     │  command line?   │
          │  SIMPLE_START.md  │     └────────┬─────────┘
          │                   │              │
          │  Just copy/paste  │      ┌───────┴────────┐
          │  ONE command!     │      │                │
          └───────────────────┘     MENU          COMMAND
                                     │                │
                                     ▼                ▼
                          ┌────────────────┐  ┌──────────────┐
                          │ Interactive    │  │ Quick Start  │
                          │ Menu           │  │ Guide        │
                          │ bash scripts/  │  │ make run     │
                          │ interactive_   │  └──────────────┘
                          │ menu.sh        │
                          └────────────────┘
```

**Recommendation:** 
- **Never used Linux?** → SIMPLE_START.md (easiest!)
- **Like visual menus?** → Interactive Menu
- **Prefer typing commands?** → Quick Start Guide

---

## 📊 Installation Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    START: Fresh Ubuntu 24.04                │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
        ┌──────────────────────────────┐
        │  Install Prerequisites       │
        │  git, curl, make             │
        └──────────────┬───────────────┘
                       │
                       ▼
        ┌──────────────────────────────┐
        │  Clone Repository            │
        │  git clone ...               │
        └──────────────┬───────────────┘
                       │
                       ▼
        ┌──────────────────────────────┐
        │  Optional: Preview           │
        │  DRY_RUN=1 make run          │
        └──────────────┬───────────────┘
                       │
                       ▼
        ┌──────────────────────────────┐
        │  Run Installation            │
        │  make run                    │
        └──────────────┬───────────────┘
                       │
        ┌──────────────┴──────────────┐
        │                             │
        ▼                             ▼
┌───────────────┐           ┌──────────────────┐
│ Base System   │           │ Optional Tools   │
│ ✓ Packages    │           │ □ ProtonVPN      │
│ ✓ Security    │           │ □ Brave Browser  │
│ ✓ Battery     │           │ □ TimeShift      │
└───────┬───────┘           │ □ VLC            │
        │                   │ □ LibreOffice    │
        │                   └────────┬─────────┘
        │                            │
        └────────────┬───────────────┘
                     │
                     ▼
        ┌────────────────────────────┐
        │   Dev Tools (Optional)     │
        │   ☑ Docker                 │
        │   ☑ Node.js                │
        │   ☑ Python                 │
        │   ☑ Rust                   │
        │   ☑ Go                     │
        │   ☑ VS Code                │
        │   ☑ Utilities              │
        └────────────┬───────────────┘
                     │
                     ▼
        ┌────────────────────────────┐
        │   Verification             │
        │   make verify              │
        └────────────┬───────────────┘
                     │
                     ▼
        ┌────────────────────────────┐
        │   DONE! 🎉                 │
        │   Log out/in to activate   │
        └────────────────────────────┘
```

---

## 🗺️ Project Structure

```
ubuntu-bootstrap/
│
├── 📄 README.md                  ← Start here
├── 📄 Makefile                   ← Main commands (make run)
│
├── 📂 scripts/                   ← Installation scripts
│   ├── run_bootstrap.sh          ← Main orchestrator
│   ├── 00_sane-apt.sh            ← APT configuration
│   ├── 10_base-packages.sh       ← Essential packages
│   ├── 20_drivers-firmware.sh    ← Hardware drivers
│   ├── 30_privacy-hardening.sh   ← Security setup
│   ├── 40_dev-tools.sh           ← Developer tools
│   ├── 50_laptop.sh              ← Laptop optimization
│   ├── 60_optional-features.sh   ← Optional features
│   └── 99_verify.sh              ← System verification
│
├── 📂 scripts/dev-modules/       ← Individual dev tools
│   ├── docker.sh                 ← Docker installation
│   ├── nodejs.sh                 ← Node.js (nvm)
│   ├── python.sh                 ← Python (pyenv)
│   ├── rust.sh                   ← Rust (rustup)
│   ├── go.sh                     ← Go language
│   ├── vscode.sh                 ← VS Code
│   ├── utilities.sh              ← CLI utilities
│   └── test_*.sh                 ← Test suites
│
├── 📂 scripts/optional-features/ ← Optional installations
│   ├── brave.sh                  ← Brave browser
│   ├── protonvpn.sh              ← ProtonVPN
│   ├── timeshift.sh              ← System snapshots
│   ├── vlc.sh                    ← Media player
│   └── libreoffice.sh            ← Office suite
│
├── 📂 hardware/                  ← Laptop profiles
│   ├── common.sh                 ← Shared functions
│   ├── thinkpad-t14.sh           ← ThinkPad profile
│   ├── hp-laptop-15.sh           ← HP profile
│   └── generic.sh                ← Universal profile
│
├── 📂 docs/                      ← Documentation
│   ├── SIMPLE_START.md           ← Quick start (you are here)
│   ├── CHEAT_SHEET.md            ← Command reference
│   ├── QUICK_START.md            ← Beginner guide
│   ├── INSTALL.md                ← Detailed install
│   ├── TROUBLESHOOTING.md        ← Problem solving
│   ├── UNINSTALL.md              ← Removal guide
│   └── INDEX.md                  ← All documentation
│
└── 📂 logs/                      ← Installation logs
    └── YYYYMMDD-HHMMSS/          ← Per-run logs
```

---

## 🎭 Installation Modes

```
┌─────────────────────────────────────────────────────────────┐
│                      INSTALLATION MODES                     │
└─────────────────────────────────────────────────────────────┘

1️⃣  FULL INSTALLATION (Everything)
    ┌────────────────────────────────────┐
    │  make run                          │
    │  • Base system                     │
    │  • Developer tools                 │
    │  • Laptop optimization             │
    │  • Verification                    │
    └────────────────────────────────────┘
    ⏱️  Time: 5-10 minutes

2️⃣  BASE ONLY (No dev tools)
    ┌────────────────────────────────────┐
    │  scripts/run_bootstrap.sh          │
    │    --skip-script=40                │
    │  • Base packages ✓                 │
    │  • Security ✓                      │
    │  • Battery ✓                       │
    │  • Dev tools ✗                     │
    └────────────────────────────────────┘
    ⏱️  Time: 2-3 minutes

3️⃣  PRIVACY-FIRST (Privacy before dev)
    ┌────────────────────────────────────┐
    │  make privacy-first                │
    │  1. ProtonVPN                      │
    │  2. Brave browser                  │
    │  3. TimeShift                      │
    │  4. Then dev tools                 │
    └────────────────────────────────────┘
    ⏱️  Time: 8-12 minutes

4️⃣  DRY RUN (Preview only)
    ┌────────────────────────────────────┐
    │  DRY_RUN=1 make run                │
    │  • Shows what would happen         │
    │  • No actual changes               │
    │  • 100% safe                       │
    └────────────────────────────────────┘
    ⏱️  Time: 1-2 minutes

5️⃣  CUSTOM (Pick your tools)
    ┌────────────────────────────────────┐
    │  scripts/40_dev-tools.sh docker    │
    │  scripts/60_optional-features.sh   │
    │    brave protonvpn                 │
    └────────────────────────────────────┘
    ⏱️  Time: Varies
```

---

## 🎨 Feature Matrix

```
┌────────────────────┬──────┬─────────┬─────────┬────────┐
│ Feature            │ Base │ DevTools│ Privacy │ Ideal  │
├────────────────────┼──────┼─────────┼─────────┼────────┤
│ Essential Packages │  ✓   │    ✓    │    ✓    │   ✓    │
│ Security (UFW)     │  ✓   │    ✓    │    ✓    │   ✓    │
│ Battery Optimizer  │  ✓   │    ✓    │    ✓    │   ✓    │
│ Docker             │  ✗   │    ✓    │    ✗    │   ✓    │
│ Node.js            │  ✗   │    ✓    │    ✗    │   ✓    │
│ Python             │  ✗   │    ✓    │    ✗    │   ✓    │
│ Rust               │  ✗   │    ✓    │    ✗    │   ✓    │
│ Go                 │  ✗   │    ✓    │    ✗    │   ✓    │
│ VS Code            │  ✗   │    ✓    │    ✗    │   ✓    │
│ Utilities          │  ✗   │    ✓    │    ✗    │   ✓    │
│ ProtonVPN          │  ✗   │    ✗    │    ✓    │   ✓    │
│ Brave Browser      │  ✗   │    ✗    │    ✓    │   ✓    │
│ TimeShift          │  ✗   │    ✗    │    ✓    │   ✓    │
│ VLC Player         │  ✗   │    ✗    │    ✗    │   ✓    │
│ LibreOffice        │  ✗   │    ✗    │    ✗    │   ✓    │
└────────────────────┴──────┴─────────┴─────────┴────────┘

Commands:
  Base:     scripts/run_bootstrap.sh --skip-script=40
  DevTools: make run
  Privacy:  make privacy-first
  Ideal:    make ideal
```

---

## 🔄 Workflow Diagram

```
                    ╔═══════════════════╗
                    ║   NEW USER?       ║
                    ╚═════════╤═════════╝
                              │
                    ┌─────────▼──────────┐
                    │ Read SIMPLE_START  │
                    └─────────┬──────────┘
                              │
                    ┌─────────▼──────────┐
                    │ Install pre-reqs   │
                    │ git, make          │
                    └─────────┬──────────┘
                              │
                    ┌─────────▼──────────┐
                    │ Clone repo         │
                    └─────────┬──────────┘
                              │
                    ╔═════════▼═════════╗
                    ║ WANT TO PREVIEW?  ║
                    ╚═════════╤═════════╝
                              │
                    ┌─────YES─┴─NO───┐
                    │                │
            ┌───────▼──────┐  ┌─────▼──────┐
            │ DRY_RUN=1    │  │ make run   │
            │ make run     │  └─────┬──────┘
            └───────┬──────┘        │
                    │               │
                    └───────┬───────┘
                            │
                  ┌─────────▼──────────┐
                  │ Installation runs  │
                  │ (3-5 minutes)      │
                  └─────────┬──────────┘
                            │
                  ┌─────────▼──────────┐
                  │ Log out/in         │
                  └─────────┬──────────┘
                            │
                  ┌─────────▼──────────┐
                  │ make verify        │
                  └─────────┬──────────┘
                            │
                  ╔═════════▼═════════╗
                  ║   ALL GOOD? ✓     ║
                  ╚═══════════════════╝
```

---

## 📱 Quick Decision Tree

```
START HERE
    │
    ├─ Just want a working Ubuntu?
    │  └─> make run
    │
    ├─ Privacy is most important?
    │  └─> make privacy-first
    │
    ├─ Want to customize everything?
    │  └─> Read INSTALL.md
    │
    ├─ Not sure / want to be safe?
    │  └─> DRY_RUN=1 make run
    │
    └─ Something broke?
       └─> Check TROUBLESHOOTING.md
```

---

## 🎓 Learning Path

```
Level 1: BEGINNER
├─ Read: SIMPLE_START.md (this file)
├─ Run:  DRY_RUN=1 make run
└─ Do:   make run

Level 2: INTERMEDIATE
├─ Read: CHEAT_SHEET.md
├─ Read: INSTALL.md
└─ Try:  Custom installations

Level 3: ADVANCED
├─ Read: Source code in scripts/
├─ Read: UNINSTALL.md
└─ Modify: Hardware profiles

Level 4: EXPERT
├─ Read: All docs/ files
├─ Contribute: Submit PRs
└─ Create: Your own modules
```

---

## 🛠️ Tools Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     DEVELOPER TOOLS                         │
├─────────────┬───────────────────────────────────────────────┤
│ Docker      │ Run containers, microservices                 │
│ Node.js     │ JavaScript/TypeScript development (nvm)       │
│ Python      │ Python programming (pyenv)                    │
│ Rust        │ Systems programming (rustup)                  │
│ Go          │ Google's Go language                          │
│ VS Code     │ Code editor with extensions                   │
│ Utilities   │ jq, ripgrep, fd, bat, ncdu, httpie, tmux     │
└─────────────┴───────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                   OPTIONAL FEATURES                         │
├─────────────┬───────────────────────────────────────────────┤
│ ProtonVPN   │ Privacy-focused VPN service                   │
│ Brave       │ Privacy browser with ad-blocking              │
│ TimeShift   │ System snapshots & restore                    │
│ VLC         │ Media player                                  │
│ LibreOffice │ Office suite (Writer, Calc, Impress)          │
└─────────────┴───────────────────────────────────────────────┘
```

---

## 📊 Time Estimates

```
Activity                           Time
────────────────────────────────   ──────────
Prerequisites installation         30 sec
Clone repository                   10 sec
Base system install                2 min
Developer tools install            3 min
Optional features (each)           1-2 min
Verification                       30 sec
────────────────────────────────   ──────────
TOTAL (full install)               5-10 min
```

---

## 🎯 Common Paths

### Path 1: Student/Hobbyist Developer
```bash
make run                           # Get everything
make verify                        # Check it works
```

### Path 2: Privacy-Conscious User
```bash
make privacy-first                 # Privacy tools first
```

### Path 3: Professional Developer
```bash
make run                           # Full dev environment
scripts/60_optional-features.sh timeshift  # Add backups
```

### Path 4: Minimal User
```bash
scripts/run_bootstrap.sh --skip-script=40  # Base only
```

---

## 📚 Next Steps

After installation:

1. ✅ **Log out and back in** (activates Docker group)
2. ✅ **Run `make verify`** (check everything works)
3. ✅ **Read [CHEAT_SHEET.md](CHEAT_SHEET.md)** (quick commands)
4. ✅ **Explore your new tools!**

---

## 🔗 Related Guides

- **Commands:** [CHEAT_SHEET.md](CHEAT_SHEET.md)
- **Detailed:** [INSTALL.md](INSTALL.md)
- **Problems:** [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- **Remove:** [UNINSTALL.md](UNINSTALL.md)
- **Everything:** [INDEX.md](INDEX.md)

---

**Visual learner? This guide is for you! 🎨**
