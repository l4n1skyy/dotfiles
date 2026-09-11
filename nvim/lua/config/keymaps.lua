local fzf = require("fzf-lua")

-- Exit terminal mode with Esc
vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { desc = "Exit terminal mode" })

-- Move between splits from terminal mode
vim.keymap.set("t", "<C-h>", [[<C-\><C-n><C-w>h]])
vim.keymap.set("t", "<C-j>", [[<C-\><C-n><C-w>j]])
vim.keymap.set("t", "<C-k>", [[<C-\><C-n><C-w>k]])
vim.keymap.set("t", "<C-l>", [[<C-\><C-n><C-w>l]])

local function open_mini_files()
  local path = vim.api.nvim_buf_get_name(0)
  if vim.bo.buftype == "terminal" then
    path = vim.fn.getcwd()
    local terminal_job_id = vim.b.terminal_job_id
    if terminal_job_id then
      local terminal_pid = vim.fn.jobpid(terminal_job_id)
      local terminal_cwd = vim.fn.resolve("/proc/" .. terminal_pid .. "/cwd")
      if vim.fn.isdirectory(terminal_cwd) == 1 then
        path = terminal_cwd
      end
    end
  end
  require("mini.files").open(path, true)
end

vim.keymap.set("n", "<leader>fm", open_mini_files, { desc = "Open mini.files" })
vim.keymap.set("t", "<leader>fm", open_mini_files, { desc = "Open mini.files at Terminal CWD" })

-- Relocate Harpoon's 'Add File' to <leader>ha to free up <leader>H
vim.keymap.set("n", "<leader>ha", function()
  require("harpoon"):list():add()
end, { desc = "Harpoon Add File" })

-- THE CDD COMMAND: Jump between Home and Shared
local function open_cdd(local_scope)
  local root = vim.fn.getcwd()
  local fd_cmd
  if local_scope then
    local escaped_root = vim.fn.shellescape(root)
    fd_cmd = "printf '%s\\n' " .. escaped_root .. "; "
      .. "fd -t d --no-ignore . " .. escaped_root .. " "
      .. "--exclude .git --exclude .Trash-1000 --exclude .local "
      .. "--exclude .steam --exclude .var"
  else
    fd_cmd = 'printf \'%s\n%s\n\' "$HOME" "/mnt/shared"; '
      .. 'fd -t d -H --no-ignore . "$HOME" "/mnt/shared" '
      .. "--exclude .git --exclude .Trash-1000 --exclude .local "
      .. "--exclude .steam --exclude .var"
  end

  fzf.fzf_exec(fd_cmd, {
    prompt = local_scope and " Cdd Local ❯ " or " Cdd ❯ ",
    winopts = { width = 0.70, preview = { hidden = "hidden" } },
    actions = {
      ["default"] = function(selected)
        if not selected or not selected[1] then
          return
        end
        -- Clean and expand path
        local target = vim.fn.expand(selected[1]:gsub("^%s*(.-)%s*$", "%1"))
        if local_scope then
          vim.cmd.lcd(target)
          vim.notify("Local CWD: " .. target, vim.log.levels.INFO)
        else
          vim.cmd.cd(target)
          vim.notify("CWD: " .. target, vim.log.levels.INFO)
        end
      end,
      ["ctrl-u"] = function()
        if local_scope then
          vim.cmd("lcd ..")
        else
          vim.cmd("cd ..")
        end
        open_cdd(local_scope)
      end,
    },
  })
end

vim.api.nvim_create_user_command("Cdd", function()
  open_cdd(false)
end, { desc = "Jump between Home and Shared directories globally" })

vim.api.nvim_create_user_command("CddLocal", function()
  open_cdd(true)
end, { desc = "Jump between Home and Shared directories locally" })

-- Quick CD
vim.keymap.set("n", "<leader>cd", ":Cdd<CR>", { desc = "Global CD" })
vim.keymap.set("n", "<leader>cD", ":CddLocal<CR>", { desc = "Local CD" })

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
