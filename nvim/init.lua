-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- Grouping file-opening logic
local function open_with_system(path)
  vim.fn.jobstart({ "xdg-open", path }, { detach = true })
  vim.api.nvim_command("bdelete")
end

-- PDF handler
vim.api.nvim_create_autocmd("BufReadCmd", {
  pattern = "*.pdf",
  callback = function()
    open_with_system(vim.fn.expand("<afile>"))
  end,
})

-- Image handler
vim.api.nvim_create_autocmd("BufReadCmd", {
  pattern = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.svg", "*.webp", "*.bmp" },
  callback = function()
    open_with_system(vim.fn.expand("<afile>"))
  end,
})
