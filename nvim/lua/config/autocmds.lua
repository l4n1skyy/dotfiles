vim.api.nvim_create_autocmd("BufDelete", {
  desc = "Open dashboard when last buffer is closed",
  callback = function(args)
    local bufs = vim.tbl_filter(function(b)
      return vim.bo[b].buflisted and b ~= args.buf
    end, vim.api.nvim_list_bufs())

    if #bufs == 0 then
      vim.schedule(function()
        if Snacks and Snacks.dashboard then
          Snacks.dashboard.open()
        else
          pcall(vim.cmd, "Alpha")
        end
      end)
    end
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "c", "cpp" },
  callback = function()
    vim.b.autoformat = false
  end,
})

local function update_dashboard_theme()
  for _, group in ipairs({
    "SnacksDashboardHeader",
    "SnacksDashboardFooter",
    "SnacksDashboardKey",
    "SnacksDashboardIcon",
    "SnacksDashboardNormal",
    "SnacksDashboardTerminal",
  }) do
    vim.api.nvim_set_hl(0, group, { link = "Identifier" })
  end

  local colors_file = vim.fn.expand("~/.local/state/omarchy/current/theme/colors.toml")
  local accent
  for _, line in ipairs(vim.fn.readfile(colors_file)) do
    accent = line:match('^accent%s*=%s*"([^"]+)"')
    if accent then
      break
    end
  end

  if accent then
    vim.api.nvim_set_hl(0, "SnacksDashboardDesc", { fg = accent })
  end
end

vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    vim.schedule(update_dashboard_theme)
  end,
})

vim.api.nvim_create_autocmd("User", {
  pattern = "SnacksDashboardOpened",
  callback = update_dashboard_theme,
})

vim.schedule(update_dashboard_theme)

