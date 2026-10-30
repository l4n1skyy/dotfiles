return {
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters = opts.formatters or {}
      opts.formatters.ruff_format = {
        append_args = {
          "--config",
          "format.skip-magic-trailing-comma=false",
        },
      }
      return opts
    end,
  },
}