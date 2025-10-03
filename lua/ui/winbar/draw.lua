local M = {}

--- @param to_draw statusbar.Content[]
--- @return string
M.winbar = function(to_draw)
	local winbar = ""
	for _, content in ipairs(to_draw) do
		local segment = table.concat(
			vim.iter(content.display)
				:map(function(pair)
					local display = type(pair[1]) == "function" and pair[1]() or pair[1]
					return string.format("%%#%s#%s", pair[2], display)
				end)
				:totable(),
			""
		)
		if content.split_next then
			winbar = winbar .. segment .. "%="
		else
			winbar = winbar .. segment .. " "
		end
	end

	return winbar
end

return M
