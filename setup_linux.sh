#!/bin/bash

# =============================================================================
# UBUNTU / WSL ENVIRONMENT INITIALIZER
# =============================================================================

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_SRC="$REPO_DIR/configs"
ZDOTDIR="${ZDOTDIR:-$HOME}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
ANTIDOTE_DIR="${ANTIDOTE_HOME:-$XDG_DATA_HOME/antidote}"

info() { echo -e "\033[1;34m[INFO]\033[0m $1"; }
success() { echo -e "\033[1;32m[SUCCESS]\033[0m $1"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m $1"; }
error() { echo -e "\033[1;31m[ERROR]\033[0m $1"; }

# Helper: Deploys files with backup logic
safe_copy() {
    local src="$1"
    local dest="$2"
    mkdir -p "$(dirname "$dest")"
    if [[ -f "$dest" ]]; then
        # If identical, do nothing
        cmp -s "$src" "$dest" && return 0
        warn "File '$dest' exists. Backing up..."
        mv "$dest" "$dest.bak.$(date +%Y%m%d%H%M%S)"
    fi
    cp "$src" "$dest"
    success "Deployed $dest"
}

install_missing_packages() {
    local missing_packages=("$@")

    if [[ ${#missing_packages[@]} -eq 0 ]]; then
        return 0
    fi

    warn "Missing required packages: ${missing_packages[*]}"
    echo "This is a shared-server-safe setup, so package installation requires explicit approval."
    read -r -p "Install missing packages with sudo apt now? [y/N] " answer

    if [[ ! "$answer" =~ ^[Yy]$ ]]; then
        error "Required packages are missing."
        echo "Install them manually with:"
        echo "  sudo apt update && sudo apt install -y ${missing_packages[*]}"
        exit 1
    fi

    if ! command -v sudo >/dev/null 2>&1; then
        error "sudo is not available. Install the missing packages manually:"
        echo "  apt update && apt install -y ${missing_packages[*]}"
        exit 1
    fi

    if ! command -v apt >/dev/null 2>&1; then
        error "apt was not found. setup_linux.sh currently supports Ubuntu/WSL only."
        exit 1
    fi

    sudo apt update
    sudo apt install -y "${missing_packages[@]}"
}

check_required_tools() {
    local required=(
        "git:git"
        "zsh:zsh"
        "nvim:neovim"
        "tmux:tmux"
        "fzf:fzf"
        "curl:curl"
    )
    local missing_packages=()
    local entry command package

    for entry in "${required[@]}"; do
        command="${entry%%:*}"
        package="${entry##*:}"
        if ! command -v "$command" >/dev/null 2>&1; then
            missing_packages+=("$package")
        fi
    done

    install_missing_packages "${missing_packages[@]}"
}

verify_required_tools() {
    local commands=(git zsh nvim tmux fzf curl)
    local missing_commands=()
    local command

    for command in "${commands[@]}"; do
        if ! command -v "$command" >/dev/null 2>&1; then
            missing_commands+=("$command")
        fi
    done

    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        error "Required commands are still missing: ${missing_commands[*]}"
        exit 1
    fi
}

configure_git_identity() {
    info "Configuring user Git identity..."
    if [[ -z "$(git config --global user.name)" ]]; then
        read -r -p "Name: " git_name
        git config --global user.name "$git_name"
    fi
    if [[ -z "$(git config --global user.email)" ]]; then
        read -r -p "Email: " git_email
        git config --global user.email "$git_email"
    fi
}

install_antidote() {
    if [[ -f "$ANTIDOTE_DIR/antidote.zsh" ]]; then
        success "Antidote already installed at $ANTIDOTE_DIR"
        return 0
    fi

    info "Installing Antidote for current user..."
    mkdir -p "$(dirname "$ANTIDOTE_DIR")"
    git clone --depth=1 https://github.com/mattmc3/antidote.git "$ANTIDOTE_DIR"
    success "Installed Antidote at $ANTIDOTE_DIR"
}

deploy_configs() {
    info "Deploying tool configurations..."
    safe_copy "$CONFIG_SRC/zsh/zshrc" "$ZDOTDIR/.zshrc"
    safe_copy "$CONFIG_SRC/zsh/zsh_plugins.txt" "$ZDOTDIR/.zsh_plugins.txt"
    safe_copy "$CONFIG_SRC/tmux/tmux.conf" "$HOME/.tmux.conf"
    safe_copy "$CONFIG_SRC/tmux/tmux-status.conf" "$HOME/.tmux-status.conf"
    safe_copy "$CONFIG_SRC/nvim/init.lua" "$XDG_CONFIG_HOME/nvim/init.lua"
}

install_neovim_plugins() {
    local plugin_home="$XDG_DATA_HOME/nvim/plugged"
    local expected_plugins=(
        vim-fugitive
        vim-repeat
        vim-commentary
        vim-surround
        nvim-tree.lua
        nvim-web-devicons
        vim-sneak
        vim-easymotion
        solarized.nvim
        lualine.nvim
    )
    local missing_plugins=()
    local plugin

    info "Running Neovim PlugInstall..."
    nvim --headless +'PlugInstall --sync' +qa

    for plugin in "${expected_plugins[@]}"; do
        if [[ ! -d "$plugin_home/$plugin" ]]; then
            missing_plugins+=("$plugin")
        fi
    done

    if [[ ${#missing_plugins[@]} -gt 0 ]]; then
        error "Neovim plugin installation did not complete: ${missing_plugins[*]}"
        echo "Try rerunning:"
        echo "  nvim --headless +'PlugInstall --sync' +qa"
        exit 1
    fi
}

has_local_passwd_entry() {
    awk -F: -v user="$USER" '$1 == user { found = 1 } END { exit found ? 0 : 1 }' /etc/passwd
}

shell_handoff_file() {
    if [[ -f "$HOME/.bash_profile" ]]; then
        echo "$HOME/.bash_profile"
    elif [[ -f "$HOME/.bash_login" ]]; then
        echo "$HOME/.bash_login"
    else
        echo "$HOME/.profile"
    fi
}

install_shell_handoff() {
    local profile_file
    local marker_start="# >>> my-dev-settings zsh handoff >>>"
    local marker_end="# <<< my-dev-settings zsh handoff <<<"

    profile_file="$(shell_handoff_file)"

    echo
    echo "This adds a per-user interactive login handoff to:"
    echo "  $profile_file"
    echo "It does not change /etc/passwd or the server login-shell database."
    read -r -p "Start zsh automatically for future interactive SSH logins? [y/N] " answer

    if [[ ! "$answer" =~ ^[Yy]$ ]]; then
        echo "Start zsh for the current session with:"
        echo "  exec zsh -l"
        return 0
    fi

    if [[ -f "$profile_file" ]] && grep -Fqx "$marker_start" "$profile_file"; then
        success "Zsh handoff is already configured in $profile_file"
        return 0
    fi

    if [[ -f "$profile_file" ]]; then
        warn "File '$profile_file' exists. Backing up..."
        cp "$profile_file" "$profile_file.bak.$(date +%Y%m%d%H%M%S)"
    fi

    mkdir -p "$(dirname "$profile_file")"
    {
        echo
        echo "$marker_start"
        echo '_my_dev_settings_zsh="$(command -v zsh 2>/dev/null)"'
        echo 'if [ -n "$PS1" ] && [ -z "${ZSH_VERSION:-}" ] && [ -z "${MY_DEV_SETTINGS_ZSH_HANDOFF:-}" ] && [ -n "$_my_dev_settings_zsh" ]; then'
        echo '    export MY_DEV_SETTINGS_ZSH_HANDOFF=1'
        echo '    exec "$_my_dev_settings_zsh" -l'
        echo 'fi'
        echo 'unset _my_dev_settings_zsh'
        echo "$marker_end"
    } >> "$profile_file"

    success "Configured zsh handoff in $profile_file"
}

configure_default_shell() {
    local zsh_path

    zsh_path="$(command -v zsh)"
    if [[ "$SHELL" == "$zsh_path" ]]; then
        success "Zsh is already the default shell for this session."
        return 0
    fi

    echo
    echo "Changing the login shell affects only user '$USER', but updates the server account database."
    echo "On key-only SSH accounts, plain chsh often fails because it asks for the account password."

    if ! has_local_passwd_entry; then
        warn "User '$USER' is not present in /etc/passwd; sudo chsh cannot update this account."
        echo "This is common on Google Compute Engine when OS Login or external identity mapping provides the user."
        install_shell_handoff
        return 0
    fi

    read -r -p "Make zsh your default login shell with sudo chsh? [y/N] " answer

    if [[ "$answer" =~ ^[Yy]$ ]]; then
        if [[ -r /etc/shells ]] && ! grep -qx "$zsh_path" /etc/shells; then
            warn "$zsh_path is not listed in /etc/shells; chsh may be rejected."
        fi

        if sudo chsh -s "$zsh_path" "$USER"; then
            success "Default shell changed to $zsh_path. Start a new login session for it to take effect."
            return 0
        fi

        warn "sudo chsh failed. Default login shell was not changed."
    else
        warn "Default login shell was not changed."
    fi

    install_shell_handoff
}

print_final_notes() {
    success "Setup Complete!"
    echo
    echo "No global font settings were changed."
    echo "Configure Hack Nerd Font in your local terminal client for correct icons and slants."
}

check_required_tools
verify_required_tools
configure_git_identity
install_antidote
deploy_configs
install_neovim_plugins
configure_default_shell
print_final_notes
