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
-- 12. Treesitter
Plug('nvim-treesitter/nvim-treesitter')
-- 13. fzf-lua for greps
Plug('ibhagwan/fzf-lua')
-- 14. Completion engine + its sources
Plug('hrsh7th/nvim-cmp')
Plug('hrsh7th/cmp-nvim-lsp')      -- LSP completion source
Plug('hrsh7th/cmp-buffer')        -- current-buffer words
Plug('hrsh7th/cmp-path')          -- filesystem paths
Plug('L3MON4D3/LuaSnip')          -- snippet engine (jdt.ls emits snippets)
Plug('saadparwaiz1/cmp_luasnip')
-- 15. Java: jdt.ls speaks extra protocol on top of standard LSP, which this
-- wraps. Configured in lua/lsp/java.lua, started from ftplugin/java.lua.
Plug('mfussenegger/nvim-jdtls')


-- Nice to haves (but not desperately needed rignt now)
-- nvim-treesitter-textobjects
-- nvim-treesitter-context

Plug('mfussenegger/nvim-lint') --async linter
Plug('MeanderingProgrammer/render-markdown.nvim') --render md inline
Plug('neovim/nvim-lspconfig') --lsp config (unused by Java; for future servers)

vim.call('plug#end') -- #END

-- Vim Options
require('config.options')
-- Key Maps
require('config.keymaps')

-- Plugin modules load through this rather than a bare `require`: before
-- :PlugInstall has run, the plugin is not on the runtimepath, `require` throws,
-- and that aborts the rest of this file -- so one uninstalled plugin takes out
-- every configuration below it. Report the failure and carry on instead.
-- Scheduled so the message lands after startup rather than scrolling past.
local function setup(module)
  local ok, err = pcall(require, module)
  if not ok then
    vim.schedule(function()
      vim.notify(('%s failed to load (run :PlugInstall?)\n%s'):format(module, err),
        vim.log.levels.WARN)
    end)
  end
end

setup('plugins.nvim-treesitter')
setup('plugins.colorscheme')
setup('plugins.lualine')
-- setup('plugins.which-key') disabled bc it is a little annoying
setup('plugins.nvim-tree')
setup('plugins.autopairs')
setup('plugins.comment')
setup('plugins.gitsigns')
setup('plugins.twilight')
setup('plugins.fzf-lua')
setup('plugins.completion')

-- LSP. Per-language setup lives in lua/lsp/ and is invoked from ftplugin/<ft>.lua;
-- only the user commands need loading up front.
setup('lsp.commands')

-- TOOD:
-- nvim-lint
