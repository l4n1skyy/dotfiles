return {
  "ibhagwan/fzf-lua",
  config = function()
    local fzf = require("fzf-lua")

    -- Your custom multi-open logic (Ported from your Telescope script)
    local custom_enter = function(selected)
      if not selected or #selected == 0 then
        return
      end

      -- If you selected multiple files with Tab
      if #selected > 1 then
        for i = 1, #selected do
          -- Add each file to the buffer list quietly
          vim.cmd(string.format("badd %s", selected[i]))
        end
        -- Focus the first selected file
        vim.cmd(string.format("edit %s", selected[1]))
      else
        -- Normal Enter behavior for a single file
        fzf.actions.file_edit(selected)
      end
    end

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
        ["--multi"] = true, -- Enables the Tab selection ability
      },

      -- Set the Enter key (<CR>) to use your custom script
      actions = {
        files = {
          ["default"] = custom_enter,
        },
        -- Also apply it to recent files (oldfiles)
        oldfiles = {
          ["default"] = custom_enter,
        },
      },

      keymap = {
        fzf = {
          ["tab"] = "toggle",
          ["shift-tab"] = "toggle-all",
        },
      },

      files = {
        fd_opts = "--color=never --type f --hidden --follow --exclude .git --exclude .local --exclude .Trash-1000 --exclude .steam --exclude .var",
      },

      oldfiles = {
        cwd_only = true,
        stat_file = true,
      },
    })
  end,
}
