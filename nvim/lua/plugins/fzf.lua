return {
  "ibhagwan/fzf-lua",
  config = function()
    local fzf = require("fzf-lua")
    fzf.setup({
      "telescope",
      winopts = {
        height = 0.80,
        width = 0.80,
        border = "none",
        preview = { hidden = "hidden" },
      },
      fzf_opts = {
        ["--info"] = "inline-right",
        ["--border"] = "rounded",
        ["--multi"] = true,
      },
      files = {
        -- Added --no-ignore to show .log and other gitignored files
        fd_opts = "--color=never --type f --hidden --follow --no-ignore "
          .. "--exclude .git --exclude .local --exclude .Trash-1000 "
          .. "--exclude .steam --exclude .var",

        actions = {
          ["default"] = function(selected, opts)
            for i, entry in ipairs(selected) do
              local file_data = fzf.path.entry_to_file(entry, opts)
              -- Expand to full absolute path so Neovim finds it regardless of CWD
              local absolute_path = vim.fn.fnamemodify(file_data.path, ":p")

              pcall(function()
                if i == 1 then
                  vim.cmd("edit " .. vim.fn.fnameescape(absolute_path))
                else
                  vim.cmd("badd " .. vim.fn.fnameescape(absolute_path))
                end
              end)
            end
          end,
        },
      },
    })
  end,
}
