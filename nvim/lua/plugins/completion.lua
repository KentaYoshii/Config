-- plugins/completion.lua — nvim-cmp completion engine and its sources.
--
-- LuaSnip is required rather than optional: jdt.ls emits snippet completions
-- (method calls arrive with placeholder arguments), and without an expander
-- those insert their raw ${1:arg} text.

local cmp = require('cmp')
local luasnip = require('luasnip')

cmp.setup({
  snippet = {
    expand = function(args) luasnip.lsp_expand(args.body) end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-e>'] = cmp.mapping.abort(),
    -- select = false: <CR> confirms only an explicitly selected entry, so it
    -- still inserts a newline when the menu is open but nothing is picked.
    ['<CR>'] = cmp.mapping.confirm({ select = false }),
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then luasnip.expand_or_jump()
      else fallback() end
    end, { 'i', 's' }),
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then luasnip.jump(-1)
      else fallback() end
    end, { 'i', 's' }),
  }),
  -- Two groups: buffer/path results appear only when the LSP and snippet
  -- sources return nothing, keeping plain words out of a populated method list.
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
  }, {
    { name = 'buffer' },
    { name = 'path' },
  }),
})
