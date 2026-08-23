require('fzf-lua').setup({
  -- each of these options can also be passed as function that return options table
  -- e.g. winopts = function() return { ... } end
  -- winopts = { ...  },     -- UI Options
  -- keymap = { ...  },      -- Neovim keymaps / fzf binds
  -- actions = { ...  },     -- Fzf "accept" binds
  -- fzf_opts = { ...  },    -- Fzf CLI flags
  -- fzf_colors = { ...  },  -- Fzf `--color` specification
  -- hls = { ...  },         -- Highlights
  -- previewers = { ...  },  -- Previewers options
    defaults = {
        git_icons = false,
        file_icons = false,
        color_icons = false,
        formatter = "path.dirname_first",
    }
})
