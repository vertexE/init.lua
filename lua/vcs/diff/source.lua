local M = {}

local function git(cwd, args)
    local result = vim.system(vim.list_extend({ "git", "--literal-pathspecs" }, args), { cwd = cwd }):wait()
    if result.code ~= 0 then
        error(vim.trim(result.stderr), 0)
    end
    return result.stdout
end

local function text(contents, dos)
    if contents:find("\0", 1, true) then
        error("Ribbon views require text files", 0)
    end
    return dos and (contents:gsub("\r\n", "\n")) or contents
end

local function unmerged(cwd, name)
    return git(cwd, { "ls-files", "--unmerged", "-z", "--", name })
end

function M.unmerged(buf, entry)
    if entry then
        return unmerged(entry.root, entry.path) ~= ""
    end
    local path = vim.api.nvim_buf_get_name(buf)
    return unmerged(vim.fs.dirname(path), vim.fs.basename(path)) ~= ""
end

local function file_path(buf)
    local path = vim.api.nvim_buf_get_name(buf)
    if path == "" or vim.bo[buf].buftype ~= "" or vim.bo[buf].binary then
        error("Open a text file in a Git worktree first", 0)
    end
    return path
end

local function location(path, entry)
    if entry then
        return entry.root, entry.path, entry.path
    end
    local cwd, name = vim.fs.dirname(path), vim.fs.basename(path)
    local prefix = git(cwd, { "rev-parse", "--show-prefix" }):gsub("\n$", "")
    return cwd, name, prefix .. name
end

local function tree_file(cwd, revision, path, dos)
    local entry = git(cwd, { "ls-tree", "-z", "--full-tree", revision, "--", path })
    if not entry:match("^%d+ blob ") then
        return ""
    end
    local contents = git(cwd, { "show", revision .. ":" .. path })
    return text(contents, dos)
end

function M.branch_ref(cwd, branch)
    for _, prefix in ipairs({ "refs/heads/", "refs/remotes/" }) do
        local ok, hash = pcall(git, cwd, { "show-ref", "--verify", "--hash", "--", prefix .. branch })
        if ok then
            return vim.trim(hash)
        end
    end
    error("Unknown Git branch: " .. vim.fn.strtrans(branch), 0)
end

function M.read_branch(buf, branch, entry)
    local cwd, _, path = location(not entry and file_path(buf), entry)
    local head = entry and entry.head or vim.trim(git(cwd, { "rev-parse", "--verify", "HEAD" }))
    local revision = entry and entry.revision or M.branch_ref(cwd, branch)
    return tree_file(cwd, head, path, true), tree_file(cwd, revision, path, true), path
end

function M.read(buf, merge, entry)
    local cwd, name, relative = location(file_path(buf), entry)
    local dos = vim.bo[buf].fileformat == "dos"
    local function blob(revision)
        return text(git(cwd, { "show", revision .. relative }), dos)
    end

    if not merge then
        return tree_file(cwd, "HEAD", relative, dos)
    end

    local stages = {}
    for entry in unmerged(cwd, name):gmatch("[^%z]+") do
        local stage = entry:match("^%d+ %x+ ([123])\t")
        if stage then
            stages[stage] = true
        end
    end
    if not next(stages) then
        error("Current file has no unmerged Git index entries", 0)
    end
    local marker_attr = git(cwd, { "check-attr", "-z", "conflict-marker-size", "--", name })
    local width = tonumber(marker_attr:match("([^%z]+)%z$"))
    return stages["2"] and blob(":2:") or "", stages["3"] and blob(":3:") or "", width and width > 0 and width or 7
end

function M.buffer_text(buf)
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    if #lines == 1 and lines[1] == "" then
        if vim.api.nvim_buf_call(buf, function()
            return vim.fn.line2byte(2) == -1
        end) then
            return ""
        end
    end
    return table.concat(lines, "\n") .. (vim.bo[buf].endofline and "\n" or "")
end

local function marker(line, char, width)
    local run, suffix = line:match("^(" .. char .. "+)(.*)$")
    return run and #run == width and (suffix == "" or suffix:sub(1, 1) == " ")
end

function M.conflicts(lines, width)
    local blocks = {}
    local first, base, divider
    local separator = string.rep("=", width)
    for i, line in ipairs(lines) do
        if not first and marker(line, "<", width) then
            first = i
        elseif first and not divider and marker(line, "|", width) then
            base = i
        elseif first and not divider and line == separator then
            divider = i
        elseif divider and marker(line, ">", width) then
            blocks[#blocks + 1] = {
                first = first,
                last = i,
                ours = vim.list_slice(lines, first + 1, (base or divider) - 1),
                theirs = vim.list_slice(lines, divider + 1, i - 1),
            }
            first, base, divider = nil, nil, nil
        end
    end
    if first then
        error("Incomplete Git conflict block", 0)
    end
    return blocks
end

return M
