# shellcheck shell=bash
# Shared Zim installation helpers, sourced by the macOS and Linux initializers.

install_zim() {
    local download
    if [[ -s "$ZIM_HOME/zimfw.zsh" ]]; then
        success "Zim already installed at $ZIM_HOME"
        return 0
    fi

    info "Installing Zim $ZIM_VERSION for current user..."
    mkdir -p "$ZIM_HOME"
    download="$(mktemp "$ZIM_HOME/zimfw.zsh.XXXXXX")"
    if ! curl -fL --retry 3 \
        "https://github.com/zimfw/zimfw/releases/download/$ZIM_VERSION/zimfw.zsh" \
        -o "$download" || ! zsh -n "$download"; then
        rm -f "$download"
        error "Failed to download a valid Zim manager."
        return 1
    fi
    mv "$download" "$ZIM_HOME/zimfw.zsh"
    success "Installed Zim at $ZIM_HOME"
}

install_zim_modules() {
    info "Installing Zim modules and building the shell startup file..."
    if ! ZIM_HOME="$ZIM_HOME" ZIM_CONFIG_FILE="$ZIM_CONFIG_FILE" ZDOTDIR="$ZDOTDIR" \
        zsh -f -c 'source "$ZIM_HOME/zimfw.zsh" install'; then
        error "Zim module installation failed; setup stopped. Fix the reported download error and rerun setup."
        return 1
    fi
    if [[ ! -s "$ZIM_HOME/init.zsh" ]]; then
        error "Zim did not generate $ZIM_HOME/init.zsh."
        return 1
    fi
}
