require("config.remote_clipboard").setup()
-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.opt.relativenumber = true

vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.virtualedit = "onemore"
vim.opt.conceallevel = 0

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "c", "h" },
	callback = function()
		vim.opt_local.expandtab = false
		vim.opt_local.shiftwidth = 4
		vim.opt_local.tabstop = 4
	end,
})
