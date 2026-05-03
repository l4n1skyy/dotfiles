local fzf = require("fzf-lua")

-- Exit terminal mode with Esc
vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { desc = "Exit terminal mode" })

-- Move between splits from terminal mode
vim.keymap.set("t", "<C-h>", [[<C-\><C-n><C-w>h]])
vim.keymap.set("t", "<C-j>", [[<C-\><C-n><C-w>j]])
vim.keymap.set("t", "<C-k>", [[<C-\><C-n><C-w>k]])
vim.keymap.set("t", "<C-l>", [[<C-\><C-n><C-w>l]])

-- Relocate Harpoon's 'Add File' to <leader>ha to free up <leader>H
vim.keymap.set("n", "<leader>ha", function()
  require("harpoon"):list():add()
end, { desc = "Harpoon Add File" })

-- THE CDD COMMAND: Jump between Home and Shared
vim.api.nvim_create_user_command("Cdd", function()
  local fd_cmd = 'printf \'%s\n%s\n\' "$HOME" "/mnt/shared"; '
    .. 'fd -t d -H --no-ignore . "$HOME" "/mnt/shared" '
    .. "--exclude .git --exclude .Trash-1000 --exclude .local "
    .. "--exclude .steam --exclude .var"

  fzf.fzf_exec(fd_cmd, {
    prompt = " Cdd ❯ ",
    winopts = { width = 0.70, preview = { hidden = "hidden" } },
    actions = {
      ["default"] = function(selected)
        if not selected or not selected[1] then
          return
        end
        -- Clean and expand path
        local target = vim.fn.expand(selected[1]:gsub("^%s*(.-)%s*$", "%1"))
        vim.cmd.cd(target)
        vim.notify("CWD: " .. target, vim.log.levels.INFO)
      end,
      ["ctrl-u"] = function()
        vim.cmd("cd ..")
        vim.cmd("Cdd")
      end,
    },
  })
end, { desc = "Jump between Home and Shared directories" })

-- Quick CD
vim.keymap.set("n", "<leader>cd", ":Cdd<CR>", { desc = "Global CD" })

-- Find Files (Including .log and ignored files)
vim.keymap.set("n", "<leader>ff", function()
  fzf.files()
end, { desc = "Find Files" })

-- THE "GO HOME" SHORTCUT (Conflict-Proofed)
pcall(vim.keymap.del, "n", "<leader>H")
vim.keymap.set("n", "<leader>H", function()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].buflisted then
      vim.api.nvim_buf_delete(buf, { force = false })
    end
  end
  vim.schedule(function()
    if Snacks and Snacks.dashboard then
      Snacks.dashboard.open()
    else
      pcall(vim.cmd, "Alpha")
    end
  end)
end, { desc = "Close all buffers and go Home", nowait = true })
