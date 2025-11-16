#!/usr/bin/env bash
# Interactive bootstrap menu for ubuntu-bootstrap v3.0.0
# Provides user-friendly interface for system setup

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/." && pwd)"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly MAGENTA='\033[0;35m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'

# Trap handler for graceful exit
cleanup() {
    echo ""
    echo -e "${YELLOW}Operation interrupted. Exiting cleanly...${NC}"
    exit 130
}
trap cleanup SIGINT SIGTERM

# Spinner for visual feedback
show_spinner() {
    local pid=$1
    local message="${2:-Processing}"
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    
    while kill -0 "$pid" 2>/dev/null; do
        local char="${spinstr:i++%${#spinstr}:1}"
        printf "\r${CYAN}%s${NC} %s" "$char" "$message"
        sleep 0.1
    done
    printf "\r%*s\r" "$((${#message} + 10))" ""
}

show_banner() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                                                               ║"
    echo "║           🚀 Ubuntu Bootstrap Interactive Menu 🚀            ║"
    echo "║                                                               ║"
    echo "║              Quick Setup for Ubuntu 24.04 LTS                 ║"
    echo "║                                                               ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

show_hardware_info() {
    echo -e "${BLUE}═══ System Information ═══${NC}"
    
    # Detect hardware
    local product=$(sudo dmidecode -s system-product-name 2>/dev/null || echo "Unknown")
    local cpu=$(grep 'model name' /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)
    local kernel=$(uname -r)
    local ubuntu=$(lsb_release -d 2>/dev/null | cut -f2 || echo "Ubuntu")
    
    echo "  Computer: $product"
    echo "  CPU: $cpu"
    echo "  Kernel: $kernel"
    echo "  OS: $ubuntu"
    echo ""
    
    # Check for specific hardware
    if echo "$product" | grep -qi "ThinkPad T14s.*Gen 2"; then
        echo -e "  ${GREEN}✓ ThinkPad T14s Gen 2 detected!${NC}"
        echo -e "    ${CYAN}→ Specific optimizations available${NC}"
        echo -e "    ${CYAN}→ See: docs/T14S_GEN2_QUICK_START.md${NC}"
        echo ""
    fi
}

show_main_menu() {
    echo -e "${BOLD}═══ Main Menu ═══${NC}"
    echo ""
    echo -e "  ${GREEN}1)${NC} ${BOLD}Full Bootstrap${NC} (Recommended)"
    echo "     └─ Complete system setup (~15-30 min)"
    echo "     └─ Base + Drivers + Power + Hardening + Laptop"
    echo ""
    echo -e "  ${GREEN}2)${NC} ${BOLD}Pre-Flight Check${NC}"
    echo "     └─ Verify system is ready (~1 min)"
    echo "     └─ Check hardware, network, disk space"
    echo ""
    echo -e "  ${GREEN}3)${NC} ${BOLD}Base System Only${NC}"
    echo "     └─ Essential packages (~5-10 min)"
    echo "     └─ Skip drivers, laptop optimizations"
    echo ""
    echo -e "  ${GREEN}4)${NC} ${BOLD}Developer Tools${NC}"
    echo "     └─ Docker, Node.js, Python, etc. (~10-20 min)"
    echo "     └─ Can select specific tools"
    echo ""
    echo -e "  ${GREEN}5)${NC} ${BOLD}Optional Features${NC}"
    echo "     └─ ProtonVPN, Brave, VLC, LibreOffice (~5-15 min)"
    echo "     └─ Privacy & productivity apps"
    echo ""
    echo -e "  ${GREEN}6)${NC} ${BOLD}Hardware-Specific Fixes${NC}"
    echo "     └─ ThinkPad T14s Gen 2 optimizations"
    echo "     └─ WiFi, TrackPoint, battery"
    echo ""
    echo -e "  ${GREEN}7)${NC} ${BOLD}View Documentation${NC}"
    echo "     └─ Browse guides and troubleshooting"
    echo ""
    echo -e "  ${GREEN}8)${NC} ${BOLD}Dry Run${NC} (Preview Mode)"
    echo "     └─ See what would be done without changes"
    echo ""
    echo -e "  ${RED}9)${NC} Exit"
    echo ""
}

run_preflight() {
    echo -e "${CYAN}Running pre-flight checks...${NC}"
    echo ""
    if bash "$REPO_DIR/scripts/preflight_check.sh"; then
        echo ""
        echo -e "${GREEN}✓ System is ready for bootstrap!${NC}"
        echo ""
        read -p "Press Enter to return to menu..." -r
    else
        echo ""
        echo -e "${RED}⚠ System has issues. Please fix them first.${NC}"
        echo ""
        read -p "Press Enter to return to menu..." -r
    fi
}

run_full_bootstrap() {
    echo -e "${CYAN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  Starting Full Bootstrap                      ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BOLD}${YELLOW}⚡ This will:${NC}"
    echo -e "  ${GREEN}✓${NC} Configure APT and repositories"
    echo -e "  ${GREEN}✓${NC} Install base packages and tools"
    echo -e "  ${GREEN}✓${NC} Install drivers and firmware"
    echo -e "  ${GREEN}✓${NC} Apply privacy hardening"
    echo -e "  ${GREEN}✓${NC} Optimize for laptop (if applicable)"
    echo -e "  ${GREEN}✓${NC} Verify installation"
    echo ""
    echo -e "${BOLD}Requirements:${NC}"
    echo -e "  ${CYAN}⏱${NC}  Time: ~15-30 minutes"
    echo -e "  ${CYAN}🌐${NC} Network: Required (downloading packages)"
    echo -e "  ${CYAN}💾${NC} Disk: ~2-5 GB will be downloaded"
    echo ""
    echo -e "${YELLOW}⚠  Your system will be optimized but NOT rebooted automatically.${NC}"
    echo ""
    read -p "$(echo -e "${BOLD}Continue with full bootstrap? (y/N):${NC} ")" -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo -e "${CYAN}Starting bootstrap... Please be patient.${NC}"
        echo ""
        bash "$REPO_DIR/scripts/run_bootstrap.sh"
        echo ""
        echo -e "${GREEN}${BOLD}✓ Bootstrap complete!${NC}"
        echo ""
        show_next_steps
        read -p "Press Enter to return to menu..." -r
    else
        echo -e "${YELLOW}Bootstrap cancelled.${NC}"
        sleep 1
    fi
}

run_base_only() {
    echo -e "${CYAN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  Base System Installation Only                ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}⚡ This will install:${NC}"
    echo -e "  ${GREEN}✓${NC} Essential system packages"
    echo -e "  ${GREEN}✓${NC} Development tools (build-essential, git, etc)"
    echo -e "  ${GREEN}✓${NC} System utilities"
    echo ""
    echo -e "${YELLOW}⊗ This will SKIP:${NC}"
    echo -e "  ${RED}✗${NC} Hardware drivers"
    echo -e "  ${RED}✗${NC} Laptop optimizations"
    echo -e "  ${RED}✗${NC} Optional features"
    echo ""
    echo -e "${CYAN}⏱${NC}  Estimated time: ~5-10 minutes"
    echo ""
    read -p "$(echo -e "${BOLD}Continue? (y/N):${NC} ")" -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        bash "$REPO_DIR/scripts/run_bootstrap.sh" --skip-script=20 --skip-script=30 --skip-script=40 --skip-script=50 --skip-script=60
        echo ""
        echo -e "${GREEN}${BOLD}✓ Base installation complete!${NC}"
        echo ""
        read -p "Press Enter to return to menu..." -r
    else
        echo -e "${YELLOW}Installation cancelled.${NC}"
        sleep 1
    fi
}

run_dev_tools() {
    echo -e "${CYAN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  Developer Tools Installation                  ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Available tools:"
    echo "  1) All tools (Docker, Node.js, Python, Rust, Go, VS Code)"
    echo "  2) Docker only"
    echo "  3) Node.js only"
    echo "  4) Python only"
    echo "  5) Custom selection"
    echo "  6) Back to main menu"
    echo ""
    read -p "Choose option (1-6): " -r choice
    
    case $choice in
        1)
            echo ""
            echo -e "${YELLOW}Installing all dev tools (~15-20 min)...${NC}"
            bash "$REPO_DIR/scripts/40_dev-tools.sh"
            ;;
        2)
            echo ""
            echo -e "${YELLOW}Installing Docker (~5 min)...${NC}"
            bash "$REPO_DIR/scripts/40_dev-tools.sh" docker
            ;;
        3)
            echo ""
            echo -e "${YELLOW}Installing Node.js (~3 min)...${NC}"
            bash "$REPO_DIR/scripts/40_dev-tools.sh" nodejs
            ;;
        4)
            echo ""
            echo -e "${YELLOW}Installing Python (~3 min)...${NC}"
            bash "$REPO_DIR/scripts/40_dev-tools.sh" python
            ;;
        5)
            echo ""
            echo "Available: docker, nodejs, python, rust, go, vscode, utilities"
            read -p "Enter tools (space-separated): " -r tools
            bash "$REPO_DIR/scripts/40_dev-tools.sh" $tools
            ;;
        *)
            return
            ;;
    esac
    
    echo ""
    echo -e "${GREEN}✓ Developer tools installed!${NC}"
    echo ""
    echo -e "${YELLOW}Post-install notes:${NC}"
    echo "  • Docker: Log out and back in to use without sudo"
    echo "  • Node.js: Run 'source ~/.nvm/nvm.sh' or restart terminal"
    echo "  • Python: Run 'source ~/.bashrc' or restart terminal"
    echo ""
    read -p "Press Enter to return to menu..." -r
}

run_optional_features() {
    echo -e "${CYAN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  Optional Features Installation                ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Available features:"
    echo "  1) ProtonVPN (privacy VPN)"
    echo "  2) Brave Browser (privacy browser)"
    echo "  3) VLC Media Player"
    echo "  4) LibreOffice (office suite)"
    echo "  5) TimeShift (system backup)"
    echo "  6) All privacy tools (ProtonVPN + Brave)"
    echo "  7) All desktop apps (VLC + LibreOffice)"
    echo "  8) Everything"
    echo "  9) Back to main menu"
    echo ""
    read -p "Choose option (1-9): " -r choice
    
    case $choice in
        1) bash "$REPO_DIR/scripts/60_optional-features.sh" protonvpn ;;
        2) bash "$REPO_DIR/scripts/60_optional-features.sh" brave ;;
        3) bash "$REPO_DIR/scripts/60_optional-features.sh" vlc ;;
        4) bash "$REPO_DIR/scripts/60_optional-features.sh" libreoffice ;;
        5) bash "$REPO_DIR/scripts/60_optional-features.sh" timeshift ;;
        6) bash "$REPO_DIR/scripts/60_optional-features.sh" protonvpn brave ;;
        7) bash "$REPO_DIR/scripts/60_optional-features.sh" vlc libreoffice ;;
        8) bash "$REPO_DIR/scripts/60_optional-features.sh" protonvpn brave vlc libreoffice timeshift ;;
        *) return ;;
    esac
    
    echo ""
    echo -e "${GREEN}✓ Optional features installed!${NC}"
    read -p "Press Enter to return to menu..." -r
}

run_hardware_fixes() {
    echo -e "${CYAN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  Hardware-Specific Fixes                       ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════╝${NC}"
    echo ""
    
    local product=$(sudo dmidecode -s system-product-name 2>/dev/null || echo "Unknown")
    
    if echo "$product" | grep -qi "ThinkPad T14s.*Gen 2"; then
        echo -e "${GREEN}✓ ThinkPad T14s Gen 2 detected!${NC}"
        echo ""
        echo "Available fixes:"
        echo "  1) Apply all T14s Gen 2 optimizations"
        echo "  2) View T14s Gen 2 documentation"
        echo "  3) Back"
        echo ""
        read -p "Choose option (1-3): " -r choice
        
        case $choice in
            1)
                if [ -f "$REPO_DIR/scripts/fix_t14s_gen2.sh" ]; then
                    bash "$REPO_DIR/scripts/fix_t14s_gen2.sh"
                    echo ""
                    echo -e "${GREEN}✓ T14s Gen 2 fixes applied!${NC}"
                    echo -e "${YELLOW}⚠ Reboot recommended to apply all changes${NC}"
                else
                    echo -e "${RED}Fix script not found${NC}"
                fi
                ;;
            2)
                less "$REPO_DIR/docs/T14S_GEN2_QUICK_START.md"
                ;;
            *)
                return
                ;;
        esac
    else
        echo "Hardware: $product"
        echo ""
        echo "No specific optimizations available for this model."
        echo ""
        echo "Generic laptop optimizations are applied during"
        echo "the full bootstrap (option 1 in main menu)."
    fi
    
    echo ""
    read -p "Press Enter to return to menu..." -r
}

view_documentation() {
    echo -e "${CYAN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  Documentation Browser                         ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Available documentation:"
    echo "  1) Quick Start Guide"
    echo "  2) Troubleshooting Guide"
    echo "  3) Hardware Profiles"
    echo "  4) ThinkPad T14s Gen 2 Guide"
    echo "  5) Post-Install Guide"
    echo "  6) Uninstall Guide"
    echo "  7) List all docs"
    echo "  8) Back"
    echo ""
    read -p "Choose option (1-8): " -r choice
    
    case $choice in
        1) less "$REPO_DIR/docs/QUICK_START.md" ;;
        2) less "$REPO_DIR/docs/TROUBLESHOOTING.md" ;;
        3) less "$REPO_DIR/docs/HARDWARE_PROFILES.md" ;;
        4) less "$REPO_DIR/docs/T14S_GEN2_QUICK_START.md" ;;
        5) less "$REPO_DIR/docs/POST_INSTALL.md" ;;
        6) less "$REPO_DIR/docs/UNINSTALL.md" ;;
        7)
            echo ""
            ls -1 "$REPO_DIR/docs/"*.md | xargs -n1 basename
            echo ""
            read -p "Enter filename to view (or press Enter to go back): " -r doc
            if [[ -n "$doc" ]]; then
                less "$REPO_DIR/docs/$doc"
            fi
            ;;
        *)
            return
            ;;
    esac
    
    echo ""
    read -p "Press Enter to return to menu..." -r
}

run_dry_run() {
    echo -e "${CYAN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  Dry Run Mode (Preview)                        ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "This will show what would be done WITHOUT making changes."
    echo ""
    read -p "Continue? (y/N): " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        DRY_RUN=1 bash "$REPO_DIR/scripts/run_bootstrap.sh"
        echo ""
        read -p "Press Enter to return to menu..." -r
    fi
}

show_next_steps() {
    echo -e "${BOLD}${GREEN}═══ Next Steps ═══${NC}"
    echo ""
    echo "1. Reboot your system:"
    echo "   ${CYAN}sudo reboot${NC}"
    echo ""
    echo "2. After reboot, verify everything:"
    echo "   ${CYAN}bash $REPO_DIR/scripts/preflight_check.sh${NC}"
    echo ""
    echo "3. Install developer tools (if needed):"
    echo "   ${CYAN}bash $REPO_DIR/scripts/40_dev-tools.sh${NC}"
    echo ""
    echo "4. Install optional features:"
    echo "   ${CYAN}bash $REPO_DIR/scripts/60_optional-features.sh${NC}"
    echo ""
    echo "Need help? Check docs/TROUBLESHOOTING.md"
    echo ""
}

# Validate numeric input
validate_choice() {
    local input="$1"
    local min="$2"
    local max="$3"
    
    if [[ ! "$input" =~ ^[0-9]+$ ]]; then
        return 1
    fi
    
    if ((input < min || input > max)); then
        return 1
    fi
    
    return 0
}

main() {
    while true; do
        show_banner
        show_hardware_info
        show_main_menu
        
        read -p "Choose an option (1-9): " -r choice
        echo ""
        
        # Validate input
        if ! validate_choice "$choice" 1 9; then
            echo -e "${RED}✗ Invalid option '$choice'. Please enter a number between 1-9.${NC}"
            sleep 2
            continue
        fi
        
        case $choice in
            1) run_full_bootstrap ;;
            2) run_preflight ;;
            3) run_base_only ;;
            4) run_dev_tools ;;
            5) run_optional_features ;;
            6) run_hardware_fixes ;;
            7) view_documentation ;;
            8) run_dry_run ;;
            9)
                echo -e "${GREEN}Thank you for using Ubuntu Bootstrap!${NC}"
                echo ""
                exit 0
                ;;
        esac
    done
}

main "$@"
