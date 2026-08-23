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

-- Common Stuff
-- 1. Color Scheme
Plug('catppuccin/nvim', { ['as'] = 'catppuccin' }) 
-- 2. Icons
Plug('nvim-tree/nvim-web-devicons') 
-- 3. Status Line Bar
Plug('nvim-lualine/lualine.nvim') 
-- 4. Mappings popup menu
-- Plug('folke/which-key.nvim') 
-- 5. Buffers tab bar
Plug('romgrk/barbar.nvim') 
-- 6. File Tree
Plug('nvim-tree/nvim-tree.lua') 
-- 7. Auto pairings
Plug('windwp/nvim-autopairs') 
-- 8. Commenting
Plug('numToStr/Comment.nvim') 
-- 9. Git signs / blames / hunks
Plug('lewis6991/gitsigns.nvim')
-- 10. Git lifecycle
Plug('tpope/vim-fugitive') 
-- 11. Focus 
Plug('folke/twilight.nvim')


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
-- require('plugins.which-key') disabled bc it is a little annoying
require('plugins.nvim-tree')
require('plugins.autopairs')
require('plugins.comment')
require('plugins.gitsigns')
require('plugins.twilight')


-- TOOD:
-- nvim-lint
-- nvim-lspconfig
