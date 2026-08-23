-- config/keymaps.lua — global keymaps only.
--
-- Context-scoped bindings live with whatever owns them: telescope's <leader>f*
-- in plugins/telescope.lua, gitsigns' <leader>h* in plugins/git.lua, and the
-- LSP navigation maps in lsp/common.lua (buffer-local, set on attach).

local function map(m, k, v) 
    vim.keymap.set(m, k, v, { noremap = true, silent = true })
end

-- Clear search highlight with <Enter>.
map('n', '<CR>', '<cmd>nohlsearch<CR>', { silent = true })

-- Barbar
map('n', '<leader>u',  '<Cmd>BufferPrevious<CR>')
map('n', '<leader>i',  '<Cmd>BufferNext<CR>')
map('n', '<leader>w',  '<Cmd>BufferClose<CR>')
map('n', '<leader>wa', '<Cmd>BufferCloseAllButCurrentOrPinned<CR>')
map('n', '<leader>pi', '<Cmd>BufferPin<CR>')
map('n', '<leader>p',  '<Cmd>BufferPick<CR>')
map('n', '<leader>pd', '<Cmd>BufferPickDelete<CR>')
map('n', '<leader>1',  '<Cmd>BufferGoto 1<CR>')
map('n', '<leader>2',  '<Cmd>BufferGoto 2<CR>')
map('n', '<leader>3',  '<Cmd>BufferGoto 3<CR>')
map('n', '<leader>4',  '<Cmd>BufferGoto 4<CR>')
map('n', '<leader>5',  '<Cmd>BufferGoto 5<CR>')
map('n', '<leader>6',  '<Cmd>BufferGoto 6<CR>')
map('n', '<leader>7',  '<Cmd>BufferGoto 7<CR>')
map('n', '<leader>8',  '<Cmd>BufferGoto 8<CR>')
map('n', '<leader>9',  '<Cmd>BufferGoto 9<CR>')
map('n', '<leader>0',  '<Cmd>BufferLast<CR>')
map('n', '<leader>bn', '<Cmd>BufferOrderByName<CR>')

-- nvim-tree
map('n', '<leader>t', '<Cmd>NvimTreeToggle<CR>') 

-- twilight
map('n', '<leader>f', '<Cmd>Twilight<CR>')

-- Own augroup, named after this module. An ungrouped autocmd is added again on
-- every re-source rather than replaced, so the copies accumulate; 'clear = true'
-- makes re-running this file idempotent. The name must be unique per module --
-- two files sharing one group name would have the second to load clear the
-- first's autocmds.
local group = vim.api.nvim_create_augroup('config_keymaps', { clear = true })

-- Keep <CR> as "open entry" inside the quickfix / location list, where the
-- global nohlsearch map above would otherwise shadow the built-in behavior.
vim.api.nvim_create_autocmd('FileType', {
  group = group,
  pattern = 'qf',
  desc = 'Restore <CR> to open the entry under the cursor',
  callback = function()
    vim.keymap.set('n', '<CR>', '<CR>', { buffer = true, remap = false, silent = true })
  end,
})
