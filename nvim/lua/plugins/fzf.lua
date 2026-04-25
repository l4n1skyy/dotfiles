return {
  "ibhagwan/fzf-lua",
  config = function()
    local fzf = require("fzf-lua")
    fzf.setup({
      "telescope",
      winopts = {
        height = 0.80, width = 0.80, border = "none",
        preview = { hidden = "hidden" },
      },
      fzf_opts = { 
        ["--info"] = "inline-right",
        ["--border"] = "rounded",
        ["--multi"] = true 
      },
      files = {
        -- Keep those heavy Bottles and Steam folders out!
        fd_opts = "--color=never --type f --hidden --follow " ..
                  "--exclude .git --exclude .local --exclude .Trash-1000 " ..
                  "--exclude .steam --exclude .var",

        actions = {
          ["default"] = function(selected)
            for _, entry in ipairs(selected) do
              local path = fzf.path.entry_to_file(entry).path
              
              -- Use pcall (protected call) to prevent the "ATTENTION" red screen
              pcall(function()
                vim.cmd("edit " .. vim.fn.fnameescape(path))
              end)
            end
          end,
        },
      },
    })
  end,
}