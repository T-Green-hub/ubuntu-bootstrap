#!/usr/bin/env bash
# Development Profiles Module for ubuntu-bootstrap
# Provides curated dev tool bundles: minimal, full-stack, ai-ml

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(dirname "$SCRIPT_DIR")/lib"

# Source dependencies
source "$LIB_DIR/logging.sh"
source "$LIB_DIR/privileged.sh"
source "$LIB_DIR/package.sh"

# Default configuration
DRY_RUN="${DRY_RUN:-0}"
AUTO_YES="${AUTO_YES:-0}"

# Profile definitions
declare -A PROFILE_MINIMAL=(
    [description]="Essential development tools for any project"
    [packages]="build-essential git curl wget ca-certificates gnupg jq vim-nox"
    [modules]=""
)

declare -A PROFILE_FULLSTACK=(
    [description]="Full-stack web development (Node.js, Python, Docker)"
    [packages]="build-essential git curl wget ca-certificates gnupg jq vim-nox tmux htop tree"
    [modules]="nodejs python docker"
)

declare -A PROFILE_AIML=(
    [description]="AI/ML development with Python ecosystem"
    [packages]="build-essential git curl wget ca-certificates gnupg jq vim-nox tmux htop tree"
    [modules]="python"
    [pip_packages]="numpy pandas matplotlib scikit-learn jupyter notebook"
)

declare -A PROFILE_SYSTEMS=(
    [description]="Systems programming (Rust, Go, C/C++)"
    [packages]="build-essential git curl wget ca-certificates gnupg jq vim-nox tmux htop tree cmake gdb valgrind"
    [modules]="rust go"
)

# Show available profiles
show_profiles() {
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "  💻 Available Development Profiles"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    echo "Choose a profile that matches your development needs:"
    echo ""
    echo "  1) 🔧 minimal     - Essential Development Tools"
    echo "     ${PROFILE_MINIMAL[description]}"
    echo "     Best for: Basic coding, learning, scripting"
    echo "     Includes: gcc, make, git, curl, vim"
    echo ""
    echo "  2) 🌐 fullstack   - Full-Stack Web Development"
    echo "     ${PROFILE_FULLSTACK[description]}"
    echo "     Best for: Web apps, APIs, microservices"
    echo "     Includes: Node.js, Python, Docker + dev utilities"
    echo ""
    echo "  3) 🤖 ai-ml       - AI & Machine Learning"
    echo "     ${PROFILE_AIML[description]}"
    echo "     Best for: Data science, ML models, Jupyter notebooks"
    echo "     Includes: Python + NumPy, Pandas, Scikit-learn, Jupyter"
    echo ""
    echo "  4) ⚙️  systems     - Systems Programming"
    echo "     ${PROFILE_SYSTEMS[description]}"
    echo "     Best for: Low-level programming, performance-critical apps"
    echo "     Includes: Rust, Go, C/C++, GDB, Valgrind"
    echo ""
    echo "  5) 🎯 custom      - Choose Your Own Tools"
    echo "     Pick exactly what you need interactively"
    echo ""
    echo "💡 How It Works:"
    echo "   Each profile installs a curated set of tools optimized"
    echo "   for specific workflows. You can always add more later!"
    echo ""
}

# Install a dev module
install_module() {
    local module="$1"
    local module_script="$SCRIPT_DIR/${module}.sh"

    if [[ ! -f "$module_script" ]]; then
        log_warning "Module not found: $module"
        return 1
    fi

    log_info "Installing module: $module"

    if (( DRY_RUN == 1 )); then
        log_info "[DRY RUN] Would run: bash $module_script"
        return 0
    fi

    bash "$module_script"
}

# Install Python packages via pip
install_pip_packages() {
    local packages="$1"

    if [[ -z "$packages" ]]; then
        return 0
    fi

    log_info "Installing Python packages: $packages"

    if (( DRY_RUN == 1 )); then
        log_info "[DRY RUN] Would install pip packages: $packages"
        return 0
    fi

    # Prefer pipx for CLI tools, pip for libraries
    if command -v pip3 >/dev/null 2>&1; then
        pip3 install --user $packages
    else
        log_warning "pip3 not found, installing python3-pip first..."
        apt_install python3-pip
        pip3 install --user $packages
    fi

    log_success "Python packages installed"
}

# Install a profile
install_profile() {
    local profile="$1"
    local packages=""
    local modules=""
    local pip_packages=""

    case "$profile" in
        minimal)
            packages="${PROFILE_MINIMAL[packages]}"
            modules="${PROFILE_MINIMAL[modules]:-}"
            ;;
        fullstack)
            packages="${PROFILE_FULLSTACK[packages]}"
            modules="${PROFILE_FULLSTACK[modules]}"
            ;;
        ai-ml|aiml)
            packages="${PROFILE_AIML[packages]}"
            modules="${PROFILE_AIML[modules]}"
            pip_packages="${PROFILE_AIML[pip_packages]:-}"
            ;;
        systems)
            packages="${PROFILE_SYSTEMS[packages]}"
            modules="${PROFILE_SYSTEMS[modules]}"
            ;;
        *)
            log_error "Unknown profile: $profile"
            log_info "Available: minimal, fullstack, ai-ml, systems"
            return 1
            ;;
    esac

    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "  Installing Development Profile: $profile"
    echo "═══════════════════════════════════════════════════════════"
    echo ""

    # Install base packages
    log_step "Installing base packages..."
    if (( DRY_RUN == 1 )); then
        log_info "[DRY RUN] Would install: $packages"
    else
        apt_install $packages
    fi

    # Install dev modules
    if [[ -n "$modules" ]]; then
        log_step "Installing development modules..."
        for module in $modules; do
            install_module "$module"
        done
    fi

    # Install pip packages (AI/ML profile)
    if [[ -n "$pip_packages" ]]; then
        log_step "Installing Python packages..."
        install_pip_packages "$pip_packages"
    fi

    log_success "Profile '$profile' installation complete"

    # Post-install notes
    show_profile_notes "$profile"
}

# Show post-install notes for profile
show_profile_notes() {
    local profile="$1"

    echo ""
    log_info "Post-installation notes for '$profile' profile:"
    echo ""

    case "$profile" in
        minimal)
            echo "  • Build tools ready: gcc, g++, make"
            echo "  • Git configured for development"
            echo "  • Consider adding: VS Code, Docker"
            ;;
        fullstack)
            echo "  • Node.js: node -v, npm -v"
            echo "  • Python: python3 --version, pip3 --version"
            echo "  • Docker: docker --version"
            echo "  • Log out/in for Docker group membership"
            echo ""
            echo "  Quick start:"
            echo "    npx create-next-app@latest my-app"
            echo "    python3 -m venv .venv && source .venv/bin/activate"
            ;;
        ai-ml|aiml)
            echo "  • Python: python3 --version"
            echo "  • Jupyter: jupyter notebook"
            echo "  • Libraries: numpy, pandas, scikit-learn, matplotlib"
            echo ""
            echo "  Quick start:"
            echo "    python3 -m venv ml-env && source ml-env/bin/activate"
            echo "    pip install torch tensorflow  # Choose your framework"
            echo "    jupyter notebook"
            ;;
        systems)
            echo "  • Rust: rustc --version, cargo --version"
            echo "  • Go: go version"
            echo "  • C/C++: gcc --version, g++ --version"
            echo "  • Debug: gdb, valgrind"
            echo ""
            echo "  Quick start:"
            echo "    cargo new my-rust-project"
            echo "    go mod init my-go-project"
            ;;
    esac

    echo ""
}

# Custom interactive selection
interactive_custom_install() {
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "  Custom Tool Selection"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    echo "Select tools to install (y/n for each):"
    echo ""

    local tools_selected=()
    local modules_selected=()

    # Base tools
    read -p "  Build tools (gcc, make, cmake)? [Y/n] " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Nn]$ ]] && tools_selected+=("build-essential" "cmake")

    read -p "  Git version control? [Y/n] " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Nn]$ ]] && tools_selected+=("git")

    read -p "  Network tools (curl, wget, jq)? [Y/n] " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Nn]$ ]] && tools_selected+=("curl" "wget" "jq")

    read -p "  Terminal utilities (tmux, htop, tree)? [y/N] " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]] && tools_selected+=("tmux" "htop" "tree")

    # Dev modules
    echo ""
    echo "Development environments:"

    read -p "  Node.js (JavaScript/TypeScript)? [y/N] " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]] && modules_selected+=("nodejs")

    read -p "  Python (with pip, venv)? [y/N] " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]] && modules_selected+=("python")

    read -p "  Rust? [y/N] " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]] && modules_selected+=("rust")

    read -p "  Go? [y/N] " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]] && modules_selected+=("go")

    read -p "  Docker? [y/N] " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]] && modules_selected+=("docker")

    read -p "  VS Code? [y/N] " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]] && modules_selected+=("vscode")

    # Summary and confirm
    echo ""
    echo "Selected packages: ${tools_selected[*]:-none}"
    echo "Selected modules: ${modules_selected[*]:-none}"
    echo ""

    if (( AUTO_YES == 0 )); then
        read -p "Proceed with installation? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Installation cancelled"
            return 0
        fi
    fi

    # Install packages
    if (( ${#tools_selected[@]} > 0 )); then
        log_step "Installing packages..."
        if (( DRY_RUN == 1 )); then
            log_info "[DRY RUN] Would install: ${tools_selected[*]}"
        else
            apt_install "${tools_selected[@]}"
        fi
    fi

    # Install modules
    for module in "${modules_selected[@]}"; do
        install_module "$module"
    done

    log_success "Custom installation complete"
}

# Interactive profile selection
interactive_profile_selection() {
    show_profiles

    read -p "Select profile [1-5]: " -n 1 -r choice
    echo

    case "$choice" in
        1) install_profile "minimal" ;;
        2) install_profile "fullstack" ;;
        3) install_profile "ai-ml" ;;
        4) install_profile "systems" ;;
        5) interactive_custom_install ;;
        *)
            log_error "Invalid choice"
            return 1
            ;;
    esac
}

# Check what's already installed
show_status() {
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "  Development Environment Status"
    echo "═══════════════════════════════════════════════════════════"
    echo ""

    # Build tools
    echo "Build Tools:"
    command -v gcc >/dev/null 2>&1 && echo "  ✓ gcc $(gcc --version | head -1 | awk '{print $NF}')" || echo "  ✗ gcc"
    command -v cmake >/dev/null 2>&1 && echo "  ✓ cmake $(cmake --version | head -1 | awk '{print $3}')" || echo "  ✗ cmake"
    command -v make >/dev/null 2>&1 && echo "  ✓ make" || echo "  ✗ make"

    # Version control
    echo ""
    echo "Version Control:"
    command -v git >/dev/null 2>&1 && echo "  ✓ git $(git --version | awk '{print $3}')" || echo "  ✗ git"

    # Languages
    echo ""
    echo "Languages & Runtimes:"
    command -v node >/dev/null 2>&1 && echo "  ✓ Node.js $(node --version)" || echo "  ✗ Node.js"
    command -v python3 >/dev/null 2>&1 && echo "  ✓ Python $(python3 --version | awk '{print $2}')" || echo "  ✗ Python"
    command -v rustc >/dev/null 2>&1 && echo "  ✓ Rust $(rustc --version | awk '{print $2}')" || echo "  ✗ Rust"
    command -v go >/dev/null 2>&1 && echo "  ✓ Go $(go version | awk '{print $3}' | sed 's/go//')" || echo "  ✗ Go"

    # Tools
    echo ""
    echo "Development Tools:"
    command -v docker >/dev/null 2>&1 && echo "  ✓ Docker $(docker --version | awk '{print $3}' | tr -d ',')" || echo "  ✗ Docker"
    command -v code >/dev/null 2>&1 && echo "  ✓ VS Code" || echo "  ✗ VS Code"

    echo ""
}

# Main
main() {
    case "${1:-}" in
        --profile|-p)
            install_profile "${2:-minimal}"
            ;;
        --custom|-c)
            interactive_custom_install
            ;;
        --status|-s)
            show_status
            ;;
        --list|-l)
            show_profiles
            ;;
        --help|-h)
            echo "Development Profiles for ubuntu-bootstrap"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --profile, -p <name>  Install a profile (minimal/fullstack/ai-ml/systems)"
            echo "  --custom, -c          Interactive custom tool selection"
            echo "  --status, -s          Show installed development tools"
            echo "  --list, -l            List available profiles"
            echo "  --help, -h            Show this help"
            echo ""
            echo "Examples:"
            echo "  $0 --profile fullstack"
            echo "  $0 --profile ai-ml"
            echo "  $0 --custom"
            ;;
        *)
            interactive_profile_selection
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
