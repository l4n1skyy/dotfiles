return {
  -- Config for blink.cmp (LazyVim's newer default)
  {
    "saghen/blink.cmp",
    optional = true,
    opts = {
      completion = {
        menu = { auto_show = false }, -- Disables the automatic popup
        ghost_text = { enabled = false }, -- Disables the phantom text ahead of the cursor
      },
    },
  },
}
