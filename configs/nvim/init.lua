-- ============================================================================
-- BOOTSTRAP VIM-PLUG
-- ============================================================================
local plug_path = vim.fn.stdpath('data') .. '/site/autoload/plug.vim'
if vim.fn.empty(vim.fn.glob(plug_path)) > 0 then
    vim.fn.system({'curl', '-fLo', plug_path, '--create-dirs', 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'})
end

-- ============================================================================
-- PLUGINS (Modern Lua Alternatives)
-- ============================================================================
local Plug = vim.fn['plug#']
vim.call('plug#begin')

-- Git integration
Plug 'tpope/vim-fugitive'

-- Text manipulation
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-surround'

-- Navigation
Plug 'nvim-tree/nvim-tree.lua'         -- Replaces NERDTree
Plug 'nvim-tree/nvim-web-devicons'    -- Required for icons
Plug 'justinmk/vim-sneak'
Plug 'easymotion/vim-easymotion'

-- Appearance
Plug 'shaunsingh/solarized.nvim'
Plug 'nvim-lualine/lualine.nvim'
Plug 'edkolev/tmuxline.vim'

vim.call('plug#end')

-- ============================================================================
-- GENERAL SETTINGS
-- ============================================================================
vim.opt.number = true
vim.opt.clipboard = 'unnamedplus'
vim.opt.termguicolors = true
vim.opt.background = 'light'
vim.cmd('colorscheme solarized')

-- Indentation
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4

-- Search
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true

-- ============================================================================
-- PLUGIN CONFIGURATION (LUA SETUP)
-- ============================================================================

-- Lualine (Modern Statusline)
require('lualine').setup {
  options = {
    theme = 'solarized_light',
    icons_enabled = true,
    component_separators = '|',
    section_separators = '',
  }
}

-- Nvim-Tree (Modern File Explorer)
require('nvim-tree').setup {
  view = { width = 30 },
  renderer = { group_empty = true },
  filters = { dotfiles = false },
}

-- ============================================================================
-- KEY MAPPINGS
-- ============================================================================
vim.g.mapleader = ' '

-- Quick escape
vim.keymap.set('i', 'jj', '<Esc>', { noremap = true })

-- Clear search
vim.keymap.set('n', '<C-l>', ':nohl<CR><C-l>', { silent = true })

-- NvimTree Toggle
vim.keymap.set('n', '<C-n>', ':NvimTreeToggle<CR>', { noremap = true })
