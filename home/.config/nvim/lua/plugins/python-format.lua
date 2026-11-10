return {
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.python = { "ruff_format" } -- LazyVim has no python entry, so the ruff LSP formats and ignores the args below
      opts.formatters = opts.formatters or {}
      opts.formatters.ruff_format = {
        append_args = {
          "--target-version",
          "py313", -- py314 target makes ruff strip parens from `except (A, B)`
          "--config",
          "format.skip-magic-trailing-comma=false",
        },
      }
      return opts
    end,
  },
}