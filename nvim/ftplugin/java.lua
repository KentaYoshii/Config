-- ftplugin/java.lua — per-buffer eclipse.jdt.ls setup, loaded automatically for
-- every Java file. The configuration lives in lua/lsp/java.lua.
require('lsp.java').start()
require('config.gjf').attach(0)
