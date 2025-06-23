local M = {}

--- @class statusbar.State
--- @field content table<statusbar.Content>
--- @field focused string segment currently in focus, "default" for no segment in focus
--- @field segments statusbar.Segment[] table of available printers

--- @alias statusbar.SegmentName "default"|"player"|"git"|"filepath"|"stats"|"pager"|"system"

--- @class statusbar.Content
--- @field display table<table<string>>
--- @field split_next boolean

--- @class statusbar.Segment
--- @field name statusbar.SegmentName
--- @field split boolean
--- @field focused fun(): table<table<string>> when a segment is focused, show more details NOTE: (unsupported)
--- @field default fun(): table<table<string>>

--- @return statusbar.State
local default_state = function()
	return {
		content = {},
		focused = "default",
		segments = {},
	}
end

--- @type statusbar.State
local state = default_state()

--- @return statusbar.State
M.state = function()
	return state
end

--- return content to draw
--- @param filter ?statusbar.SegmentName
--- @return statusbar.Content[]
M.content = function(filter)
	if filter == nil then
		return state.content
	end

	local content = {}
	for _, segment in ipairs(state.segments) do
		if segment.name == filter then
			table.insert(content, { display = segment.default(), split_next = segment.split })
		end
	end
	return content
end

M.one_segment = function() end

--- adds a new statusbar segment
--- @param segment statusbar.Segment
M.register_segment = function(segment)
	table.insert(state.segments, segment)
end

--- @param name statusbar.SegmentName
M.focus_on = function(name)
	state.focused = name
end

--- update state, will run before ui.render
M.tick = function()
	if state.focused == "default" then
		local content = {}
		for _, segment in ipairs(state.segments) do
			table.insert(content, { display = segment.default(), split_next = segment.split })
		end
		state.content = content
	else
		local segment = state.segments[state.focused]
		state.content = { { display = segment.focused(), split_next = segment.split } }
	end
end

return M
