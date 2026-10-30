return {
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    -- Unbind defaults to prevent keymap wars
    keys = {
      { "<leader>aa", false },
      { "<leader>aq", false },
      { "<leader>ax", false },
      { "<leader>ad", false },
      { "<leader>ap", false },
    },
    opts = {
      window = {
        layout = "vertical", -- Better for side-by-side work
        width = 0.4,
      },
      -- Adds the user handle from your 42KL login to the chat
      question_header = " " .. (vim.env.USER or "User") .. " ",
      answer_header = "  Copilot ",
    },
  },
}
