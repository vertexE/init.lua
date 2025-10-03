local M = {}

--- @class statusbar.MenuOption
--- @field display string
--- @field key string
--- @field icon string
--- @field hl ?statusbar.MenuOptionHl optional highlights for icon, display, or key
--- @field action fun()

--- @class statusbar.MenuOptionHl
--- @field icon ?string
--- @field display ?string
--- @field key ?string

--- @type statusbar.MenuOptionHl
local default_hl = {
	icon = "",
	display = "",
	key = "",
}

--- @param options table<statusbar.MenuOption>
M.open = function(options)
	local winr = vim.api.nvim_get_current_win()
	local win_width = vim.api.nvim_win_get_width(winr)
	local win_height = vim.api.nvim_win_get_height(winr)
	local width = math.ceil(win_width * 0.4) -- set width & height based on longest menu item + appropriate offset
	local height = math.ceil(win_height * 0.2)
	local float_buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_open_win(float_buf, true, {
		title = "buffers",
		relative = "editor",
		row = 0,
		col = 0,
		width = width,
		height = height,
		style = "minimal",
		border = "single",
	})

end

return M
