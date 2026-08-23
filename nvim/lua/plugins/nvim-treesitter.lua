local treesitter = require('nvim-treesitter')
treesitter.setup()
treesitter.install({ "bash", "c", "cpp", "go", "java", "json", "lua", "markdown", "markdown_inline", "python" })

vim.api.nvim_create_autocmd('FileType', {
    pattern = { "bash", "c", "cpp", "go", "java", "json", "lua", "markdown", "markdown_inline", "python" },
    callback = function() 
        vim.treesitter.start()
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
        vim.wo[0][0].foldmethod = 'expr'
    end,
})
