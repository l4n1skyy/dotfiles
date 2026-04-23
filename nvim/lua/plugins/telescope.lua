return {
  "nvim-telescope/telescope.nvim",
  opts = function(_, opts)
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")

    local custom_enter = function(prompt_bufnr)
      local picker = action_state.get_current_picker(prompt_bufnr)
      local multi = picker:get_multi_selection()

      -- If you selected multiple things using Tab
      if not vim.tbl_isempty(multi) then
        actions.close(prompt_bufnr)
        for _, j in pairs(multi) do
          if j.path ~= nil then
            -- Open them quietly in the background
            vim.cmd(string.format("edit %s", j.path))
          end
        end
      else
        -- Otherwise, just do the normal Enter behavior
        actions.select_default(prompt_bufnr)
      end
    end

    -- Tell Telescope to use this function when you press Enter in Insert mode
    opts.defaults = opts.defaults or {}
    opts.defaults.mappings = opts.defaults.mappings or {}
    opts.defaults.mappings.i = opts.defaults.mappings.i or {}
    opts.defaults.mappings.i["<CR>"] = custom_enter
  end,
}
