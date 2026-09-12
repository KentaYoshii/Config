-- config/options.lua — editor options (mirrors the previous ~/.vimrc, plus
-- Neovim niceties), clipboard integration, and diagnostic display.

local opt = vim.opt

-- Display
opt.number = true          -- line numbers
opt.ruler = true           -- cursor position
opt.showcmd = true         -- partial commands
opt.laststatus = 2         -- always show status line
opt.wildmenu = true        -- enhanced command-line completion
opt.scrolloff = 3          -- keep 3 lines above/below cursor
opt.termguicolors = true   -- 24-bit colour (Ghostty supports it)
vim.cmd('syntax enable')   -- ensure syntax highlighting is on
opt.signcolumn = 'yes'     -- reserve gutter so diagnostics don't shift text

-- Search
opt.incsearch = true
opt.hlsearch = true
opt.ignorecase = true      -- case-insensitive...
opt.smartcase = true       -- ...unless the query has capitals

-- Indentation
opt.expandtab = true       -- spaces instead of tabs
opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4
opt.autoindent = true

-- Editing / files
opt.mouse = 'a'            -- mouse in all modes
opt.hidden = true          -- switch buffers without saving
opt.backup = false
opt.swapfile = false
opt.updatetime = 300       -- faster diagnostics / CursorHold
opt.completeopt = { 'menuone', 'noselect' }  -- better completion UX

-- Diagnostics display
vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})

opt.foldlevelstart = 99
