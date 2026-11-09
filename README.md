# 💻 My Dotfiles

A portable development environment for **Neovim**, **Tmux**, and **Zsh** that uses your terminal's color palette. Choose any terminal theme, light or dark.

## 🏗 Environment Requirements
Configure these settings in your local terminal, including when connecting to Linux / WSL:

### 🖋 Appearance & Font
* **Font**: Ghostty's default **JetBrains Mono** and built-in Nerd Font support cover Powerline glyphs and file icons; leave `font-family` unset. No extra font installation is needed. In other terminals, choose any font or fallback with the required glyph support. See Ghostty's [built-in Nerd Font support](https://ghostty.org/docs/install/release-notes/1-2-0#built-in-nerd-font-improvement).
* **Color Palette**: Choose it in your terminal. No specific theme is required.
* **Glyphs (iTerm2)**: If using a Nerd Font, you can disable "Built-in Powerline Glyphs" to let that font handle rendering.
* **Unicode (iTerm2)**: Set "Unicode Normalization Form" to **NFC**.

Tmux's status bar uses the terminal's default foreground/background and reverse video for emphasis. Neovim uses its bundled `vim` colorscheme (legacy defaults on versions before 0.10) with `termguicolors` disabled, so it inherits the terminal's default foreground/background and uses indexed syntax colors. Lualine reuses Neovim's statusline highlights. Zsh's Pure prompt already uses terminal palette colors.

Neovim leaves `background` unset so its terminal UI can detect light/dark appearance. If detection fails (for example, through an older tmux or SSH setup), use `:set background=light` or `:set background=dark`. Some built-in highlights and plugins use extended 256-color entries, so changing a terminal theme need not recolor every accent. This trades independent RGB editor colors for terminal palette integration; to use an RGB colorscheme later, enable `termguicolors` and load that scheme.

### ⌨️ Key Mapping Essentials
* **Leader Key**: `Space`
* **Alt Navigation**: Your terminal must be configured to treat the **Alt/Option** key as `Meta` (Esc+) to allow `Alt + h/j/k/l` pane switching.
* **Key Repeat**: The setup scripts handle disabling the OS "Accent Menu" (long-press menu) to allow for high-speed Vim motions.

---

## 🚀 Installation & Platform Setup

### macOS (Ghostty or iTerm2)
1.  Install [Ghostty](https://ghostty.org/) or [iTerm2](https://iterm2.com/).
2.  Configure the Option key:
    * **Ghostty**: The initializer sets `macos-option-as-alt = left` automatically. It installs `configs/ghostty/config` as `$XDG_CONFIG_HOME/ghostty/my-dev-settings.conf` (default: `~/.config/ghostty/my-dev-settings.conf`) and includes it from `~/Library/Application Support/com.mitchellh.ghostty/config`. Existing config content is preserved and backed up before adding the include; rerunning does not duplicate it. The shared file controls the left Option key; font and theme choices remain in your personal config. Leave `font-family` and `theme` unset to use Ghostty's defaults. No fonts are installed. See Ghostty's [configuration guide](https://ghostty.org/docs/config) and [Option key reference](https://ghostty.org/docs/config/reference#macos-option-as-alt).
    * **iTerm2**: In **Profiles > Keys**, set **Left Option Key** to `Esc+`. If file icons are missing, choose a Nerd Font of your choice.
3.  Run the initializer:
    ```bash
    chmod +x setup_macos.sh
    ./setup_macos.sh
    ```
4.  In Ghostty, reload its configuration with `Cmd + Shift + ,` (or restart Ghostty).

### Apply appearance changes to an existing installation

The bootstrap scripts copy files rather than symlinking them. To update only the appearance settings, run these commands from this repository (they back up existing installed files):

```bash
(
    nvim_config="${XDG_CONFIG_HOME:-$HOME/.config}/nvim/init.lua"
    backup_suffix="bak.$(date +%Y%m%d%H%M%S)"
    mkdir -p "$(dirname "$nvim_config")"
    [ ! -f "$nvim_config" ] || cp -p "$nvim_config" "$nvim_config.$backup_suffix"
    [ ! -f "$HOME/.tmux-status.conf" ] || cp -p "$HOME/.tmux-status.conf" "$HOME/.tmux-status.conf.$backup_suffix"
    cp configs/nvim/init.lua "$nvim_config"
    cp configs/tmux/tmux-status.conf "$HOME/.tmux-status.conf"
)
tmux source-file "$HOME/.tmux-status.conf"  # If a tmux server is running
```

Restart Neovim after copying. The old Solarized plugin can remain installed without being used; `:PlugClean` can remove unused plugins after you review its list.

### Linux / WSL
Designed for Ubuntu / WSL and shared-server environments. The script configures the current user. If required tools are missing, it asks before using `sudo apt`; if Zsh is not the default shell, it uses `sudo chsh` only for local `/etc/passwd` users and otherwise offers a per-user interactive SSH handoff.

1.  Use Ghostty's default font support, or configure your local terminal with a font or fallback that supports the icons you use. Nothing needs to be installed on the server for font rendering.
2.  Run the initializer:
    ```bash
    chmod +x setup_linux.sh
    ./setup_linux.sh
    ```
3.  Follow the prompts. Any package installation, login-shell change, or SSH handoff change requires confirmation. If the system Neovim is older than `0.10`, the script installs the latest stable Neovim under `~/.local` for the current user.
4.  Optional: start Zsh for the current session:
    ```bash
    exec zsh -l
    ```

---

## Zsh configuration and migration

Both setup scripts install [Zim](https://github.com/zimfw/zimfw) for the current user and deploy `configs/zsh/zimrc` as `${ZDOTDIR:-$HOME}/.zimrc`. The selected modules provide environment defaults, input keybindings, utility aliases/man-page colors, and completion. Pure, `rupa/z`, and fzf are retained. General helper aliases and completion styling follow Zim's defaults; the explicit `rm`/`mv`/`cp` confirmation aliases and `vim`/`vi` aliases remain.

To migrate an existing installation, rerun the setup script for that machine, then open a new shell or run `exec zsh -l`. Changed `.zshrc` and `.zimrc` files are backed up automatically. The existing `~/.zsh_history` is reused. Antidote and its old `.zsh_plugins.txt` and caches are no longer loaded; the setup leaves those files in place.

The manager is installed under `${XDG_DATA_HOME:-$HOME/.local/share}/zim`. New installations use release `v1.20.2`; set `ZIM_VERSION` to another release tag to select the initial download. Existing managers are reused. Use the same exported `ZIM_HOME` or `ZIM_CONFIG_FILE` overrides during setup and in your shell if you customize these paths.

Zim modules are installed and `init.zsh` is generated during setup. Normal shell startup sources that generated file; after editing `.zimrc`, Zim initializes new modules and rebuilds it on the next startup. Run `zimfw list` to inspect modules, `zimfw update` to update them, and `zimfw upgrade` to upgrade the manager. Modules follow their upstream branches by default; use `--tag` in `.zimrc` to select a fixed release, or `--branch` to choose a different branch.

---

## 📜 Cheat Sheet (Core & Advanced)

### TMUX (Prefix: `Ctrl + b`)
| Action | Shortcut |
| :--- | :--- |
| **Vertical Split** | `Prefix + v` or `|` |
| **Horizontal Split** | `Prefix + s` or `-` |
| **Navigate Panes** | `Alt + h/j/k/l` |
| **Resize Pane (5px)** | `Prefix + Shift + H/J/K/L` |
| **Reload Config** | `Prefix + r` |

### NEOVIM (Leader: `Space`)
| Action | Shortcut |
| :--- | :--- |
| **Exit Insert Mode** | `jj` |
| **Toggle File Tree** | `Ctrl + n` |
| **Sneak (2-char)** | `s` + `[char][char]` |
| **EasyMotion (Word)** | `<Space><Space>w` |
| **EasyMotion (Pattern)** | `<Space><Space>s` |

### NVIM-TREE & ZSH
| Category | Action | Shortcut |
| :--- | :--- | :--- |
| **Nvim-Tree** | Create / Delete / Rename | `a` / `d` / `r` |
| **Nvim-Tree** | Cut / Open | `x` / `Enter` |
| **Zsh Shell** | Fuzzy History Search | `Ctrl + r` |
| **Zsh Shell** | Fuzzy File Picker (inserts a path into the command line) | `Ctrl + t` |

---

## 📂 Structure
* `configs/ghostty/`: Shared Ghostty settings deployed by the macOS initializer.
* `configs/nvim/`: Neovim Lua configurations.
* `configs/tmux/`: Tmux logic and status line styling.
* `configs/zsh/`: Shell environment and Zim module list.
* `scripts/setup_zim.sh`: Shared user-scoped Zim bootstrap helpers.
* `setup_macos.sh`: Automated bootstrap script for Mac.
* `setup_linux.sh`: User-scoped Ubuntu / WSL bootstrap script.
