-- lsp/common.lua — setup shared by every language server in lua/lsp/.
--
-- The capabilities block and the navigation keymaps live here rather than in
-- each language module, so a binding added for one language is available in all
-- of them.

local M = {}

-- Deferred rather than `local fzf = require('fzf-lua')` at module scope: this
-- file loads from ftplugin/*.lua, which can fire before vim-plug has put the
-- plugins on the runtimepath (e.g. during config.options' `syntax enable` on the
-- first argument buffer), and an eager require there breaks LSP setup entirely.
-- Resolving inside each callback defers it to actual keypress time, well after
-- startup has finished.
local function fzf(method)
  return function() require('fzf-lua')[method]() end
end

-- Client capabilities advertised to a server: Neovim's defaults extended with
-- what nvim-cmp supports (snippets, resolve support, additionalTextEdits).
-- pcall'd so the servers still start before :PlugInstall has run.
function M.capabilities()
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  local ok_cmp, cmp_lsp = pcall(require, 'cmp_nvim_lsp')
  if ok_cmp then
    capabilities = cmp_lsp.default_capabilities(capabilities)
  end
  return capabilities
end

-- Buffer-local LSP keymaps, the same across languages so they carry over.
--
-- opts.format   replaces the default <leader>cf handler. Used where more than
--               one client attaches and only one of them should format.
-- opts.extra    function(map) for language-specific bindings, called with the
--               same `map(keys, fn, desc)` helper used below.
--
-- Guarded so a second client attaching to the same buffer does not re-map over
-- the first one's bindings.
function M.on_attach(bufnr, opts)
  if vim.b[bufnr].lsp_keymaps_set then
    return
  end
  vim.b[bufnr].lsp_keymaps_set = true

  opts = opts or {}

  local function map(keys, fn, desc)
    vim.keymap.set('n', keys, fn, { buffer = bufnr, silent = true, desc = desc })
  end

  -- Routed through fzf-lua rather than the bare vim.lsp.buf.* handlers so
  -- multi-result lists (references/implementations/symbols) get a preview pane
  -- instead of landing in a plain quickfix window.
  map('gd', fzf('lsp_definitions'), 'Go to definition')
  map('gD', fzf('lsp_declarations'), 'Go to declaration')
  map('gi', fzf('lsp_implementations'), 'Go to implementation')
  map('gr', fzf('lsp_references'), 'List references')
  map('K', vim.lsp.buf.hover, 'Hover docs')
  map('<leader>rn', vim.lsp.buf.rename, 'Rename symbol')
  map('<leader>ca', fzf('lsp_code_actions'), 'Code action')
  map('<leader>fo', fzf('lsp_document_symbols'), 'Document symbols')
  map('<leader>fO', fzf('lsp_live_workspace_symbols'), 'Workspace symbols')
  map('<leader>cf',
    opts.format or function() vim.lsp.buf.format({ async = true }) end,
    opts.format_desc or 'Format')
  map('[d', function() vim.diagnostic.jump({ count = -1 }) end, 'Prev diagnostic')
  map(']d', function() vim.diagnostic.jump({ count = 1 }) end, 'Next diagnostic')
  map('<leader>e', vim.diagnostic.open_float, 'Line diagnostics')

  if opts.extra then
    opts.extra(map)
  end
end

-- Stop the named clients, wait for them to actually exit, then reload every
-- loaded buffer of the given filetypes so the ftplugin re-runs and starts a
-- fresh server. Backs :JdtRestart and :JdtWipe.
--
-- The wait is the point: vim.lsp.start reuses a client whose name and root_dir
-- match, and jdt.ls corrupts its Eclipse index if two servers share a workspace,
-- so reloading a buffer too early re-attaches to the server that is still
-- exiting instead of starting the new one.
--
-- opts.force       passed to vim.lsp.stop_client. jdt.ls needs a force-kill.
-- opts.tries       how many 250ms polls to wait before giving up and reloading.
-- opts.after_stop  called once the clients are confirmed gone (see when_gone
--                  below). :JdtWipe deletes the Eclipse workspace here.
-- opts.label       name used in the restart notification, where the client name
--                  is not what the user calls the server ('jdtls' / 'jdt.ls').
function M.restart_clients(name, filetypes, opts)
  opts = opts or {}
  local max_tries = opts.tries or 40

  for _, client in ipairs(vim.lsp.get_clients({ name = name })) do
    pcall(vim.lsp.stop_client, client.id, opts.force or false)
  end

  local wanted = {}
  for _, ft in ipairs(filetypes) do wanted[ft] = true end

  local tries = 0
  local function when_gone()
    if #vim.lsp.get_clients({ name = name }) == 0 or tries > max_tries then
      -- vim.lsp.get_clients() emptying out means Neovim has torn down its
      -- client object, not that the jdt.ls JVM has actually exited and
      -- released the workspace directory -- stop_client only requests the
      -- stop. after_stop (:JdtWipe's directory delete) used to run before
      -- this wait even started, racing a JVM still shutting down: it could
      -- recreate files under the directory being deleted, and Eclipse's own
      -- crash-recovery ("workspace exited with unsaved changes... refreshing
      -- workspace to recover changes") would then restore the very state the
      -- wipe was meant to clear. Deferring after_stop() to here closes most
      -- of that race; the extra 300ms below covers the remaining gap between
      -- the client object disappearing and the OS process actually exiting.
      vim.defer_fn(function()
        if opts.after_stop then
          opts.after_stop()
        end
        -- Reload the buffers explicitly rather than issuing a bare ':edit',
        -- so an unnamed focused buffer cannot fail this deferred callback
        -- with E32.
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_loaded(buf)
            and wanted[vim.bo[buf].filetype]
            and vim.api.nvim_buf_get_name(buf) ~= '' then
            -- Clear the guard so on_attach re-maps after the reload.
            vim.b[buf].lsp_keymaps_set = nil
            vim.api.nvim_buf_call(buf, function() vim.cmd('edit') end)
          end
        end
        vim.notify((opts.label or name) .. ': restarting…')
      end, 300)
    else
      tries = tries + 1
      vim.defer_fn(when_gone, 250)
    end
  end
  vim.defer_fn(when_gone, 250)
end

return M
