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

# --- 1. Git Identity ---
info "Configuring Git..."
[[ -z "$(git config --global user.name)" ]] && read -p "Name: " n && git config --global user.name "$n"
[[ -z "$(git config --global user.email)" ]] && read -p "Email: " e && git config --global user.email "$e"

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

info "Installing tools & Hack Nerd Font..."
brew install git zsh neovim tmux fzf
brew install --cask font-hack-nerd-font

install_antidote

# --- 3. Deploy Configs ---
info "Deploying tool configurations..."
safe_copy "$CONFIG_SRC/zsh/zshrc" "$ZDOTDIR/.zshrc"
safe_copy "$CONFIG_SRC/zsh/zsh_plugins.txt" "$ZDOTDIR/.zsh_plugins.txt"
safe_copy "$CONFIG_SRC/tmux/tmux.conf" "$HOME/.tmux.conf"
safe_copy "$CONFIG_SRC/tmux/tmux-status.conf" "$HOME/.tmux-status.conf"
safe_copy "$CONFIG_SRC/nvim/init.lua" "$XDG_CONFIG_HOME/nvim/init.lua"

# --- 4. MacOS Specific Fixes ---
info "Disabling accent menu (Long-press fix)..."
defaults write -g ApplePressAndHoldEnabled -bool false

# --- 5. Finalization ---
info "Setting Zsh as default..."
ZSH_PATH="$(command -v zsh)"
[[ "$SHELL" != "$ZSH_PATH" ]] && sudo chsh -s "$ZSH_PATH" "$USER"

info "Running Neovim PlugInstall..."
nvim --headless +'PlugInstall --sync' +qa

success "Setup Complete! Restart iTerm2 to enjoy the slants."
