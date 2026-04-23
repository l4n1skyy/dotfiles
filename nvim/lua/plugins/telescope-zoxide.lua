return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    {
      "jvgrootveld/telescope-zoxide",
      config = function()
        -- Tells Telescope to load the Zoxide extension
        require("telescope").load_extension("zoxide")
      end,
    },
  },
  keys = {
    -- Binds Space + f + z to open your Zoxide history
    { "<leader>fz", "<cmd>Telescope zoxide list<CR>", desc = "Find Folders (Zoxide)" },
  },
}
