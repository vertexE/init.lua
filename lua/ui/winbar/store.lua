local M = {}

--- @class statusbar.State
--- @field segments statusbar.Segment[] table of available printers

--- @alias statusbar.SegmentName "default"|"player"|"git"|"filepath"|"stats"|"pager"|"system"|"project"

--- @alias statusbar.SegmentType "winbar"|"tabline"

--- @class statusbar.Content
--- @field display table<table<string>>
--- @field split_next boolean

--- @class statusbar.Segment
--- @field name statusbar.SegmentName
--- @field split boolean
--- @field type statusbar.SegmentType
--- @field content fun(focused: boolean): table<table<string>>

--- @return statusbar.State
local default_state = function()
    return {
        segments = {},
    }
end

--- @type statusbar.State
local state = default_state()

--- content ready to draw
--- @param type statusbar.SegmentType
--- @param focused boolean if the cursor is focused in this win
--- @return statusbar.Content[]
M.content = function(type, focused)
    local content = {}
    for _, segment in ipairs(state.segments) do
        if segment.type == type then
            table.insert(content, { display = segment.content(focused), split_next = segment.split })
        end
    end
    return content
end

--- adds a new statusbar segment
--- @param segment statusbar.Segment
M.register_segment = function(segment)
    table.insert(state.segments, segment)
end

return M
