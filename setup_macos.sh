#!/bin/bash

# =============================================================================
# MACOS ENVIRONMENT INITIALIZER
# =============================================================================

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_SRC="$REPO_DIR/configs"
ZDOTDIR="${ZDOTDIR:-$HOME}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
ANTIDOTE_DIR="${ANTIDOTE_HOME:-$XDG_DATA_HOME/antidote}"
GIT_USER_NAME="Jihun Choi"
GIT_USER_EMAIL="1898501+jihunchoi@users.noreply.github.com"

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

deploy_ghostty_config() {
    local managed_config="$XDG_CONFIG_HOME/ghostty/my-dev-settings.conf"
    # The legacy filename is supported by both older and newer Ghostty versions.
    local user_config="$HOME/Library/Application Support/com.mitchellh.ghostty/config"
    local include_line="config-file = \"$managed_config\""

    safe_copy "$CONFIG_SRC/ghostty/config" "$managed_config"

    if [[ -f "$user_config" ]] && grep -Fxq "$include_line" "$user_config"; then
        success "Ghostty already includes the shared configuration."
        return 0
    fi

    mkdir -p "$(dirname "$user_config")"
    if [[ -f "$user_config" ]]; then
        warn "Backing up existing Ghostty config before adding the shared settings."
        cp -p "$user_config" "$user_config.bak.$(date +%Y%m%d%H%M%S)"
    fi
    printf '\n# Shared terminal settings from my-dev-settings\n%s\n' "$include_line" >> "$user_config"
    success "Added shared Ghostty settings to $user_config"
}

find_brew() {
    local brew_bin

    if brew_bin="$(command -v brew 2>/dev/null)"; then
        echo "$brew_bin"
        return 0
    fi

    for brew_bin in \
        "${BREW_BIN:-}" \
        "${HOMEBREW_PREFIX:+$HOMEBREW_PREFIX/bin/brew}" \
        /opt/homebrew/bin/brew \
        /usr/local/bin/brew; do
        if [[ -n "$brew_bin" && -x "$brew_bin" ]]; then
            echo "$brew_bin"
            return 0
        fi
    done

    return 1
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

# --- 1. Git Identity ---
info "Configuring Git..."
git config --global user.name "$GIT_USER_NAME"
git config --global user.email "$GIT_USER_EMAIL"

# --- 2. Homebrew & Tools ---
info "Checking Homebrew..."
BREW_BIN="$(find_brew || true)"
if [[ -z "$BREW_BIN" ]]; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    BREW_BIN="$(find_brew || true)"
fi

if [[ -z "$BREW_BIN" ]]; then
    error "Homebrew was not found after installation."
    exit 1
fi

eval "$("$BREW_BIN" shellenv)"

info "Installing tools..."
brew install git zsh neovim tmux fzf

install_antidote

# --- 3. Deploy Configs ---
info "Deploying tool configurations..."
safe_copy "$CONFIG_SRC/zsh/zshrc" "$ZDOTDIR/.zshrc"
safe_copy "$CONFIG_SRC/zsh/zsh_plugins.txt" "$ZDOTDIR/.zsh_plugins.txt"
safe_copy "$CONFIG_SRC/tmux/tmux.conf" "$HOME/.tmux.conf"
safe_copy "$CONFIG_SRC/tmux/tmux-status.conf" "$HOME/.tmux-status.conf"
safe_copy "$CONFIG_SRC/nvim/init.lua" "$XDG_CONFIG_HOME/nvim/init.lua"
deploy_ghostty_config

# --- 4. MacOS Specific Fixes ---
info "Disabling accent menu (Long-press fix)..."
defaults write -g ApplePressAndHoldEnabled -bool false

# --- 5. Finalization ---
info "Setting Zsh as default..."
ZSH_PATH="$(command -v zsh)"
[[ "$SHELL" != "$ZSH_PATH" ]] && sudo chsh -s "$ZSH_PATH" "$USER"

install_neovim_plugins

success "Setup Complete! Open a new terminal session to use the configuration."
info "In Ghostty, press Cmd+Shift+, to reload its configuration."
