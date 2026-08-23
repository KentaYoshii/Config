local vim = vim 
local Plug =  vim.fn['plug#']

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- disable netrw at the very start of your init.lua
-- for nvim-tree
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Plugins 
vim.call('plug#begin') -- #BEGIN

Plug('catppuccin/nvim', { ['as'] = 'catppuccin' }) --colorscheme
Plug('nvim-tree/nvim-web-devicons') --pretty icons
Plug('nvim-lualine/lualine.nvim') --statusline
Plug('folke/which-key.nvim') --mappings popup
Plug('romgrk/barbar.nvim') --bufferline
Plug('nvim-tree/nvim-tree.lua') --file explorer
Plug('windwp/nvim-autopairs') --autopairs 
Plug('numToStr/Comment.nvim') --easier comments
Plug('lewis6991/gitsigns.nvim') --git

Plug('ibhagwan/fzf-lua') --fuzzy finder and grep
Plug('mfussenegger/nvim-lint') --async linter
Plug('MeanderingProgrammer/render-markdown.nvim') --render md inline
Plug('neovim/nvim-lspconfig') --lsp config

vim.call('plug#end') -- #END

-- Vim Options
require('config.options')
-- Key Maps
require('config.keymaps')

require('plugins.colorscheme')
require('plugins.lualine')
require('plugins.which-key')
require('plugins.nvim-tree')
require('plugins.autopairs')
require('plugins.comment')
require('plugins.gitsigns')


-- TOOD:
-- nvim-lint
-- nvim-lspconfig
