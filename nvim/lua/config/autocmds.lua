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
