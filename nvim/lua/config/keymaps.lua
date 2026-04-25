-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua

-- Exit terminal mode with Esc
vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { desc = "Exit terminal mode" })

-- Optional: Move between splits directly from terminal mode
vim.keymap.set("t", "<C-h>", [[<C-\><C-n><C-w>h]], { desc = "Move to left split" })
vim.keymap.set("t", "<C-j>", [[<C-\><C-n><C-w>j]], { desc = "Move to bottom split" })
vim.keymap.set("t", "<C-k>", [[<C-\><C-n><C-w>k]], { desc = "Move to top split" })
vim.keymap.set("t", "<C-l>", [[<C-\><C-n><C-w>l]], { desc = "Move to right split" })

vim.api.nvim_create_user_command("Cdd", function(opts)
  local query = opts.args or ""
  local fd_cmd =
    'printf \'%s\n%s\n\' "$HOME" "/mnt/shared"; fd -t d -H . "$HOME" "/mnt/shared" --exclude .git --exclude .Trash-1000 --exclude .local'
  require("fzf-lua").fzf_exec(fd_cmd, {
    prompt = " Cdd ❯ ",
    -- Override the global UI just for this command
    winopts = {
      width = 0.70, -- Make the box a bit narrower since there is no preview
      preview = { hidden = "hidden" }, -- DISABLE PREVIEW
    },
    actions = {
      ["default"] = function(selected)
        if not selected or not selected[1] then
          return
        end
        vim.cmd.cd(selected[1])
        vim.notify("CWD: " .. selected[1], vim.log.levels.INFO)
      end,
      ["ctrl-u"] = function()
        vim.cmd("cd ..")
        vim.cmd("Cdd")
      end,
    },
  })
end, { nargs = "?", desc = "Global CD" })
vim.keymap.set("n", "<leader>cd", ":Cdd<CR>", { desc = "Cdd Global" })
