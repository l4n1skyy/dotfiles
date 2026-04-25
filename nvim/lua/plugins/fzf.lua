return {
  "ibhagwan/fzf-lua",
  config = function()
    require("fzf-lua").setup({
      "telescope",

      winopts = {
        height = 0.80,
        width = 0.80,
        border = "none", -- THIS KILLS THE OUTER DOUBLE BORDER
        preview = { hidden = "hidden" }, -- No file preview
      },

      fzf_opts = {
        ["--info"] = "inline-right",
        ["--border"] = "rounded", -- Keeps the rounded detached boxes
      },

      files = {
        -- Blocks fzf from scanning Steam games, Windows emulators, and Trash!
        fd_opts = "--color=never --type f --hidden --follow --exclude .git --exclude .local --exclude .Trash-1000 --exclude .steam --exclude .var",
      },

      oldfiles = {
        cwd_only = true,
        stat_file = true,
      },
    })
  end,
}
