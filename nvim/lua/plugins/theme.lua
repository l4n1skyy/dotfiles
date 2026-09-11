local current_theme = vim.fn.expand("~/.local/state/omarchy/current/theme/neovim.lua")

if vim.fn.filereadable(current_theme) == 1 then
	return dofile(current_theme)
end

return {}
