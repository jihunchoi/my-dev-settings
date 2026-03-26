# 💻 My Dotfiles (Multimodal & Extensible)

This repository contains my personal development environment. It is designed to be **portable** (configs are tool-based) and **automated** (OS-specific setup scripts).

## 📂 Structure
- `setup_macos.sh`: Full bootstrap for Mac (Brew, Fonts, System Defaults).
- `configs/`: Clean, tool-specific dotfiles that can be reused on Linux/WSL.

## 🚀 Usage
On a new Mac, simply run:
```bash
chmod +x setup_macos.sh
./setup_macos.sh
