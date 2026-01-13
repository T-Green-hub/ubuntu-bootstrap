#!/usr/bin/env bash
# Shell Customization Helper for ubuntu-bootstrap
# Allows users to configure their preferred shell environment

set -euo pipefail

SCRIPT_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_LIB_DIR/logging.sh" ]]; then
    source "$SCRIPT_LIB_DIR/logging.sh"
else
    log_info() { echo "[INFO] $*"; }
    log_success() { echo "[SUCCESS] $*"; }
    log_warning() { echo "[WARNING] $*"; }
    log_error() { echo "[ERROR] $*" >&2; }
fi

# Detect available shells
get_available_shells() {
    local shells=()
    [[ -x /bin/bash ]] && shells+=("bash")
    [[ -x /usr/bin/zsh ]] || [[ -x /bin/zsh ]] && shells+=("zsh")
    [[ -x /usr/bin/fish ]] && shells+=("fish")
    echo "${shells[@]}"
}

# Get current default shell
get_current_shell() {
    basename "$SHELL"
}

# Check if zsh is installed
is_zsh_installed() {
    command -v zsh >/dev/null 2>&1
}

# Check if fish is installed
is_fish_installed() {
    command -v fish >/dev/null 2>&1
}

# Install zsh with oh-my-zsh
install_zsh() {
    if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
        log_info "[DRY RUN] Would install zsh and oh-my-zsh"
        return 0
    fi

    log_info "Installing zsh..."
    sudo apt-get update -qq
    sudo apt-get install -y zsh

    log_success "zsh installed"

    # Offer to install oh-my-zsh
    echo ""
    log_info "Oh-My-Zsh provides:"
    log_info "  • Beautiful themes and prompts"
    log_info "  • Plugin system for git, docker, etc."
    log_info "  • Easy customization"
    echo ""

    read -p "Install Oh-My-Zsh? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        install_oh_my_zsh
    fi
}

# Install oh-my-zsh
install_oh_my_zsh() {
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        log_info "Oh-My-Zsh already installed"
        return 0
    fi

    if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
        log_info "[DRY RUN] Would install Oh-My-Zsh"
        return 0
    fi

    log_info "Installing Oh-My-Zsh..."

    # Install without changing shell automatically
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || {
        log_warning "Oh-My-Zsh installation had issues"
        return 1
    }

    log_success "Oh-My-Zsh installed"

    # Suggest popular plugins
    log_info ""
    log_info "Recommended plugins to add to ~/.zshrc:"
    log_info "  plugins=(git docker docker-compose sudo history-substring-search)"
    log_info ""
    log_info "Popular themes:"
    log_info "  ZSH_THEME=\"robbyrussell\"  (default)"
    log_info "  ZSH_THEME=\"agnoster\"      (powerline style)"
    log_info "  ZSH_THEME=\"powerlevel10k\" (highly customizable)"
}

# Install fish shell
install_fish() {
    if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
        log_info "[DRY RUN] Would install fish shell"
        return 0
    fi

    log_info "Installing fish shell..."
    sudo apt-get update -qq
    sudo apt-get install -y fish

    log_success "fish shell installed"

    log_info ""
    log_info "Fish features:"
    log_info "  • Autosuggestions based on history"
    log_info "  • Syntax highlighting"
    log_info "  • Web-based configuration (fish_config)"
    log_info ""
    log_info "To configure: fish_config"
}

# Change default shell
change_default_shell() {
    local new_shell="$1"
    local shell_path

    case "$new_shell" in
        bash) shell_path="/bin/bash" ;;
        zsh)  shell_path="$(command -v zsh)" ;;
        fish) shell_path="$(command -v fish)" ;;
        *)
            log_error "Unknown shell: $new_shell"
            return 1
            ;;
    esac

    if [[ ! -x "$shell_path" ]]; then
        log_error "Shell not found or not executable: $shell_path"
        return 1
    fi

    if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
        log_info "[DRY RUN] Would change default shell to: $shell_path"
        return 0
    fi

    log_info "Changing default shell to: $new_shell"

    # Ensure shell is in /etc/shells
    if ! grep -q "^$shell_path$" /etc/shells 2>/dev/null; then
        log_info "Adding $shell_path to /etc/shells..."
        echo "$shell_path" | sudo tee -a /etc/shells > /dev/null
    fi

    # Change shell
    chsh -s "$shell_path"

    log_success "Default shell changed to: $new_shell"
    log_info "Log out and back in for changes to take effect"
}

# Configure bash with useful defaults
configure_bash_defaults() {
    if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
        log_info "[DRY RUN] Would configure bash defaults"
        return 0
    fi

    local bashrc="$HOME/.bashrc"
    local backup="$HOME/.bashrc.backup.$(date +%Y%m%d-%H%M%S)"

    # Backup existing
    if [[ -f "$bashrc" ]]; then
        cp "$bashrc" "$backup"
        log_info "Backed up: $backup"
    fi

    # Add useful aliases if not present
    local additions=""

    if ! grep -q "alias ll=" "$bashrc" 2>/dev/null; then
        additions+="
# Added by ubuntu-bootstrap
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
"
    fi

    if ! grep -q "alias grep=" "$bashrc" 2>/dev/null; then
        additions+="alias grep='grep --color=auto'
"
    fi

    if ! grep -q "HISTSIZE=" "$bashrc" 2>/dev/null; then
        additions+="
# History settings
HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoreboth:erasedups
"
    fi

    if [[ -n "$additions" ]]; then
        echo "$additions" >> "$bashrc"
        log_success "Added useful defaults to ~/.bashrc"
    else
        log_info "Bash defaults already configured"
    fi
}

# Configure terminal colors (dark/light mode hint)
configure_terminal_theme() {
    local mode="${1:-dark}"

    log_info ""
    log_info "Terminal theme configuration:"
    log_info ""
    log_info "For GNOME Terminal:"
    log_info "  1. Right-click in terminal → Preferences"
    log_info "  2. Select your profile → Colors tab"
    log_info "  3. Uncheck 'Use colors from system theme'"
    log_info "  4. Choose a built-in scheme or customize"
    log_info ""
    log_info "Popular color schemes to install:"
    log_info "  • Dracula: https://draculatheme.com/gnome-terminal"
    log_info "  • Nord: https://github.com/arcticicestudio/nord-gnome-terminal"
    log_info "  • Gruvbox: https://github.com/morhetz/gruvbox-contrib"
    log_info ""

    if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
        log_info "[DRY RUN] Would offer to install Dracula theme"
        return 0
    fi

    read -p "Install Dracula theme for GNOME Terminal? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        install_dracula_theme
    fi
}

# Install Dracula theme for GNOME Terminal
install_dracula_theme() {
    if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
        log_info "[DRY RUN] Would install Dracula theme"
        return 0
    fi

    log_info "Installing Dracula theme for GNOME Terminal..."

    local tmp_dir="/tmp/dracula-gnome-terminal"
    rm -rf "$tmp_dir"

    if git clone https://github.com/dracula/gnome-terminal "$tmp_dir" 2>/dev/null; then
        cd "$tmp_dir"
        if [[ -f "./install.sh" ]]; then
            ./install.sh
            log_success "Dracula theme installed"
            log_info "Select 'Dracula' profile in Terminal preferences"
        else
            log_warning "Dracula installer not found"
        fi
        cd - > /dev/null
        rm -rf "$tmp_dir"
    else
        log_warning "Could not clone Dracula theme repository"
    fi
}

# Interactive shell setup
interactive_shell_setup() {
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "  🎨 Shell & Terminal Customization"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    echo "Your shell is the command-line interface you interact with."
    echo "Customizing it can dramatically improve your productivity!"
    echo ""
    echo "💡 Shell Options Explained:"
    echo ""
    echo "  🐚 Bash (Default)"
    echo "     The standard Linux shell. Reliable and universal."
    echo "     Best for: Compatibility, scripting, servers"
    echo ""
    echo "  ⚡ Zsh + Oh-My-Zsh"
    echo "     Enhanced shell with themes, plugins, and autocomplete."
    echo "     Best for: Developers, daily terminal users"
    echo "     Features: Git integration, syntax highlighting, themes"
    echo ""
    echo "  🐟 Fish"
    echo "     Modern shell with autosuggestions out-of-the-box."
    echo "     Best for: Beginners, interactive use"
    echo "     Features: Web-based config, smart autocomplete"
    echo ""
    echo "───────────────────────────────────────────────────────────"
    echo "Current shell: $(get_current_shell)"
    echo "Available shells: $(get_available_shells)"
    echo "───────────────────────────────────────────────────────────"
    echo ""
    echo "Options:"
    echo "  1) Keep bash (configure useful defaults)"
    echo "  2) Install and switch to zsh (with Oh-My-Zsh)"
    echo "  3) Install and switch to fish"
    echo "  4) Configure terminal theme"
    echo "  5) Show current configuration"
    echo "  q) Quit"
    echo ""

    read -p "Enter choice: " choice

    case "$choice" in
        1)
            configure_bash_defaults
            ;;
        2)
            if ! is_zsh_installed; then
                install_zsh
            fi
            change_default_shell "zsh"
            ;;
        3)
            if ! is_fish_installed; then
                install_fish
            fi
            change_default_shell "fish"
            ;;
        4)
            configure_terminal_theme
            ;;
        5)
            echo ""
            echo "Current shell: $(get_current_shell)"
            echo "Shell path: $SHELL"
            echo "Available: $(get_available_shells)"
            if [[ -d "$HOME/.oh-my-zsh" ]]; then
                echo "Oh-My-Zsh: installed"
            fi
            ;;
        q|Q)
            log_info "No changes made"
            ;;
        *)
            log_error "Invalid choice"
            ;;
    esac
}

# Main entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        --install-zsh)
            install_zsh
            ;;
        --install-fish)
            install_fish
            ;;
        --set-shell)
            change_default_shell "${2:-bash}"
            ;;
        --configure-bash)
            configure_bash_defaults
            ;;
        --theme)
            configure_terminal_theme "${2:-dark}"
            ;;
        --status)
            echo "Current shell: $(get_current_shell)"
            echo "Available: $(get_available_shells)"
            ;;
        --interactive|-i)
            interactive_shell_setup
            ;;
        --help|-h)
            echo "Shell Customization Helper for ubuntu-bootstrap"
            echo ""
            echo "Usage: $0 [OPTION]"
            echo ""
            echo "Options:"
            echo "  --install-zsh       Install zsh and optionally Oh-My-Zsh"
            echo "  --install-fish      Install fish shell"
            echo "  --set-shell <name>  Change default shell (bash/zsh/fish)"
            echo "  --configure-bash    Add useful defaults to ~/.bashrc"
            echo "  --theme             Configure terminal theme"
            echo "  --status            Show current shell configuration"
            echo "  --interactive, -i   Interactive setup wizard"
            echo "  --help, -h          Show this help"
            ;;
        *)
            interactive_shell_setup
            ;;
    esac
fi
