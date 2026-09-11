-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- Open non-text files externally and remove their temporary Neovim buffers.
local function wipe_external_buffer(buffer, delay)
  vim.defer_fn(function()
    if vim.api.nvim_buf_is_valid(buffer) then
      vim.cmd("noautocmd silent! bwipeout! " .. buffer)
    end
  end, delay)
end

local function open_with_system(args)
  local path = vim.api.nvim_buf_get_name(args.buf)
  local extension = vim.fn.fnamemodify(path, ":e"):lower()
  if not vim.tbl_contains({ "pdf", "png", "jpg", "jpeg", "gif", "svg", "webp", "bmp" }, extension) then
    return
  end

  if vim.b[args.buf].external_opened then
    wipe_external_buffer(args.buf, 50)
    return
  end

  vim.b[args.buf].external_opened = true
  path = vim.fn.fnamemodify(path, ":p")
  vim.fn.jobstart({ "xdg-open", path }, { detach = true })
  wipe_external_buffer(args.buf, 100)
end

vim.api.nvim_create_autocmd({ "BufReadPost", "BufWinEnter", "BufEnter", "WinEnter" }, {
  callback = function(args)
    open_with_system(args)
  end,
})
