return {
  {
    "nvim-mini/mini.files",
    keys = {
      {
        "<leader>fm",
        function()
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
        end,
        desc = "Open mini.files",
      },
    },
  },
}
