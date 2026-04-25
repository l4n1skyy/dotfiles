-- Exit terminal mode with Esc
vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { desc = "Exit terminal mode" })

-- Move between splits from terminal mode
vim.keymap.set("t", "<C-h>", [[<C-\><C-n><C-w>h]])
vim.keymap.set("t", "<C-j>", [[<C-\><C-n><C-w>j]])
vim.keymap.set("t", "<C-k>", [[<C-\><C-n><C-w>k]])
vim.keymap.set("t", "<C-l>", [[<C-\><C-n><C-w>l]])

-- THE CDD COMMAND: Jump between Home and Shared
vim.api.nvim_create_user_command("Cdd", function(opts)
  local fd_cmd = 'printf \'%s\n%s\n\' "$HOME" "/mnt/shared"; ' ..
                 'fd -t d -H . "$HOME" "/mnt/shared" ' ..
                 '--exclude .git --exclude .Trash-1000 --exclude .local ' ..
                 '--exclude .steam --exclude .var'

  require("fzf-lua").fzf_exec(fd_cmd, {
    prompt = " Cdd ❯ ",
    winopts = { width = 0.70, preview = { hidden = "hidden" } },
    actions = {
      ["default"] = function(selected)
        if not selected or not selected[1] then return end
        vim.cmd.cd(selected[1])
        vim.notify("CWD: " .. selected[1])
      end,
      ["ctrl-u"] = function()
        vim.cmd("cd ..")
        vim.cmd("Cdd")
      end,
    },
  })
end, { nargs = "?" })

-- Open folder jumper
vim.keymap.set("n", "<leader>cd", ":Cdd<CR>", { desc = "Global CD" })

-- Open file search (Respects your fzf.lua settings and multi-select)
vim.keymap.set("n", "<leader>ff", function()
  require("fzf-lua").files()
end, { desc = "Find Files" })