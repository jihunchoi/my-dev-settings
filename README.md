# 💻 My Dotfiles

A high-performance, portable development environment featuring a **Solarized Light** aesthetic for **Neovim**, **Tmux**, and **Zsh**.

## 🏗 Environment Requirements
Regardless of the OS, the following environment settings are **required** for the UI to render correctly:

### 🖋 Appearance & Font
* **Font**: **Hack Nerd Font** (Non-mono version). This is the secret to the seamless status line slants and file icons.
* **Color Palette**: **Solarized Light**. 
* **Glyphs**: Disable "Built-in Powerline Glyphs" in your terminal settings; let the Nerd Font handle the rendering.
* **Unicode**: Set "Unicode Normalization Form" to **NFC**.

### ⌨️ Key Mapping Essentials
* **Leader Key**: `Space`
* **Alt Navigation**: Your terminal must be configured to treat the **Alt/Option** key as `Meta` (Esc+) to allow `Alt + h/j/k/l` pane switching.
* **Key Repeat**: The setup scripts handle disabling the OS "Accent Menu" (long-press menu) to allow for high-speed Vim motions.

---

## 🚀 Installation & Platform Setup

### macOS (iTerm2)
1.  Install [iTerm2](https://iterm2.com/).
2.  In **Profiles > Keys**, set **Left Option Key** to `Esc+`.
3.  Run the initializer:
    ```bash
    chmod +x setup_macos.sh
    ./setup_macos.sh
    ```

### Linux / WSL
*Coming soon. The `configs/` directory is already structured for immediate reuse once a `setup_linux.sh` is created.*

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
| **Fuzzy Find Files** | `Ctrl + t` |
| **Sneak (2-char)** | `s` + `[char][char]` |
| **EasyMotion (Word)** | `<Space><Space>w` |
| **EasyMotion (Pattern)** | `<Space><Space>s` |

### NVIM-TREE & ZSH
| Category | Action | Shortcut |
| :--- | :--- | :--- |
| **Nvim-Tree** | Create / Delete / Rename | `a` / `d` / `r` |
| **Nvim-Tree** | Cut / Open | `x` / `Enter` |
| **Zsh Shell** | Fuzzy History Search | `Ctrl + r` |

---

## 📂 Structure
* `configs/nvim/`: Neovim Lua configurations.
* `configs/tmux/`: Tmux logic and status line styling.
* `configs/zsh/`: Shell environment and plugin lists.
* `setup_macos.sh`: Automated bootstrap script for Mac.
