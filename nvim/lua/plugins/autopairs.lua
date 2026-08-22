require('nvim-autopairs').setup({
-- put this to setup function and press <a-e> to use fast_wrap
    fast_wrap = {
      map = '<C-l>',
      chars = { '{', '[', '(', '"', "'" },
      pattern = [=[[%'%"%>%]%)%}%,]]=],
      end_key = '$',
      before_key = 'h',
      after_key = 'l',
      cursor_pos_before = true,
      keys = 'qwertyuiopzxcvbnmasdfghjkl',
      manual_position = true,
      highlight = 'Search',
      highlight_grey='Comment'
    },
})

-- Fast Wrap
-- Insert mode
-- <C-l> to add missing pair

