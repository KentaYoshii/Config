require('gitsigns').setup({
  signs = {
    add          = { text = '┃' },
    change       = { text = '┃' },
    delete       = { text = '_' },
    topdelete    = { text = '‾' },
    changedelete = { text = '~' },
    untracked    = { text = '┆' },
  },
  signs_staged = {
    add          = { text = '┃' },
    change       = { text = '┃' },
    delete       = { text = '_' },
    topdelete    = { text = '‾' },
    changedelete = { text = '~' },
    untracked    = { text = '┆' },
  },
  signs_staged_enable = true,
  signcolumn = true,  -- Toggle with `:Gitsigns toggle_signs`
  numhl      = false, -- Toggle with `:Gitsigns toggle_numhl`
  linehl     = false, -- Toggle with `:Gitsigns toggle_linehl`
  word_diff  = false, -- Toggle with `:Gitsigns toggle_word_diff`
  watch_gitdir = {
    follow_files = true
  },
  auto_attach = true,
  attach_to_untracked = false,
  current_line_blame = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
  current_line_blame_opts = {
    virt_text = true,
    virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
    delay = 1000,
    ignore_whitespace = false,
    virt_text_priority = 100,
    use_focus = true,
  },
  current_line_blame_formatter = '<author>, <author_time:%R> - <summary>',
  blame_formatter = nil, -- Use default
  sign_priority = 6,
  update_debounce = 100,
  status_formatter = nil, -- Use default
  max_file_length = 40000, -- Disable if file is longer than this (in lines)
  preview_config = {
    -- Options passed to nvim_open_win
    style = 'minimal',
    relative = 'cursor',
    row = 0,
    col = 1
  },
  on_attach = function(bufnr)
  local gitsigns = require('gitsigns')
  
  local function map4(mode, l, r, opts)
    opts = opts or {}
    opts.buffer = bufnr
    vim.keymap.set(mode, l, r, opts)
  end
  
  -- Navigation
  map4('n', ']c', function()
    if vim.wo.diff then
      vim.cmd.normal({']c', bang = true})
    else
      gitsigns.nav_hunk('next')
    end
  end)
  
  map4('n', '[c', function()
    if vim.wo.diff then
      vim.cmd.normal({'[c', bang = true})
    else
      gitsigns.nav_hunk('prev')
    end
  end)
  
  -- Actions
  map4('n', '<leader>hs', gitsigns.stage_hunk)
  map4('n', '<leader>hr', gitsigns.reset_hunk)
  
  map4('v', '<leader>hs', function()
    gitsigns.stage_hunk({ vim.fn.line('.'), vim.fn.line('v') })
  end)
  
  map4('v', '<leader>hr', function()
    gitsigns.reset_hunk({ vim.fn.line('.'), vim.fn.line('v') })
  end)
  
  map4('n', '<leader>hS', gitsigns.stage_buffer)
  map4('n', '<leader>hR', gitsigns.reset_buffer)
  map4('n', '<leader>hp', gitsigns.preview_hunk)
  map4('n', '<leader>hi', gitsigns.preview_hunk_inline)
  
  map4('n', '<leader>hb', function()
    gitsigns.blame_line({ full = true })
  end)
  
  map4('n', '<leader>hd', gitsigns.diffthis)
  
  map4('n', '<leader>hD', function()
    gitsigns.diffthis('~')
  end)

  map4('n', '<leader>hQ', function() gitsigns.setqflist('all') end)
  map4('n', '<leader>hq', gitsigns.setqflist)
  
  -- Toggles
  map4('n', '<leader>hlb', gitsigns.toggle_current_line_blame)
  map4('n', '<leader>hw', gitsigns.toggle_word_diff)
  
  -- Text object
  map4({'o', 'x'}, 'hh', gitsigns.select_hunk)
  end
})
