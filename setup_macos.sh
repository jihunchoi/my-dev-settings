#!/bin/bash

# =============================================================================
# MACOS ENVIRONMENT INITIALIZER
# =============================================================================

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_SRC="$REPO_DIR/configs"

info() { echo -e "\033[1;34m[INFO]\033[0m $1"; }
success() { echo -e "\033[1;32m[SUCCESS]\033[0m $1"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m $1"; }

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

# --- 1. Git Identity ---
info "Configuring Git..."
[[ -z "$(git config --global user.name)" ]] && read -p "Name: " n && git config --global user.name "$n"
[[ -z "$(git config --global user.email)" ]] && read -p "Email: " e && git config --global user.email "$e"

# --- 2. Homebrew & Tools ---
info "Checking Homebrew..."
command -v brew &> /dev/null || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || eval "$(/usr/local/bin/brew shellenv)"

info "Installing tools & Hack Nerd Font..."
brew install git zsh neovim tmux fzf antidote
brew install --cask font-hack-nerd-font

# --- 3. Deploy Configs ---
info "Deploying tool configurations..."
safe_copy "$CONFIG_SRC/zsh/zshrc" "$HOME/.zshrc"
safe_copy "$CONFIG_SRC/zsh/zsh_plugins.txt" "$HOME/.zsh_plugins.txt"
safe_copy "$CONFIG_SRC/tmux/tmux.conf" "$HOME/.tmux.conf"
safe_copy "$CONFIG_SRC/tmux/tmux-status.conf" "$HOME/.tmux-status.conf"
safe_copy "$CONFIG_SRC/nvim/init.lua" "$HOME/.config/nvim/init.lua"

# --- 4. MacOS Specific Fixes ---
info "Disabling accent menu (Long-press fix)..."
defaults write -g ApplePressAndHoldEnabled -bool false

# --- 5. Finalization ---
info "Setting Zsh as default..."
[[ "$SHELL" != "$(which zsh)" ]] && sudo chsh -s "$(which zsh)" "$USER"

info "Running Neovim PlugInstall..."
nvim --headless +PlugInstall +qa

success "Setup Complete! Restart iTerm2 to enjoy the slants."
