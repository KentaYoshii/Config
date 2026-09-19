-- lsp/commands.lua — user commands for recovering a wedged language server, plus
-- the stop-servers-on-exit hook. The work itself lives in the per-language
-- modules; this file only wires it to command names.

-- jdt.ls: :JdtRestart restarts the server for the current project, :JdtWipe
-- additionally deletes its Eclipse workspace so the next open re-imports from
-- scratch. See lua/lsp/java.lua for why a shared workspace wedges imports.
vim.api.nvim_create_user_command('JdtRestart', function()
  require('lsp.java').restart(false)
end, { desc = 'Restart the jdt.ls server for this project' })

vim.api.nvim_create_user_command('JdtWipe', function()
  require('lsp.java').restart(true)
end, { desc = 'Wipe the jdt.ls workspace and re-import from scratch' })

-- Own augroup, named after this module, so re-sourcing replaces the autocmd
-- below rather than adding another copy. The name is per-module on purpose: two
-- files sharing one group name would have the second to load clear the first's
-- autocmds.
local group = vim.api.nvim_create_augroup('lsp_commands', { clear = true })

-- Stop LSP servers cleanly on exit. Without this, jdt.ls can outlive Neovim and
-- orphan itself; a later Neovim then starts a second server on the same project
-- workspace, and two servers writing one Eclipse index corrupts it and stalls
-- imports. Force-stopping clients on quit prevents the orphan.
vim.api.nvim_create_autocmd('VimLeavePre', {
  group = group,
  desc = 'Stop all LSP clients so none outlives Neovim',
  callback = function()
    for _, client in ipairs(vim.lsp.get_clients()) do
      pcall(vim.lsp.stop_client, client.id, true)
    end
  end,
})
