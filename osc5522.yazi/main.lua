--- @sync entry
local M = {}

function M:setup(opts)

end

local hovered_file = ya.sync(function()
    local file = cx.active.current.hovered
    if file then
        return {
            url = tostring(file.url),
            mime = file:mime(),
        }
    end
end)

--- COPY FUNCTIONS ---

local function copy_uri_list()
    local list = require("dnd").selected_uri_list()
    if #list == 0 then
        return false
    end
    local uri_list = table.concat(list, "\n")
    local gnome_list = "copy\n" .. uri_list

    local copy = { { mime = "text/uri-list", payload = uri_list, aliases = {"text/plain"} } }
    if gnome_list then
        copy[#copy + 1] = { mime = "x-special/gnome-copied-files", payload = gnome_list, aliases = {} }
    end

    ya.dbg("Copy URI List", copy)

    rt.tty:queue("WriteClipboard", copy)
    rt.tty:flush()
    return true
end

local function copy_file_contents()
    local file = hovered_file()
    if not (file and file.mime) then
        return false
    end

    ya.dbg("Copy File Contents", file)

    local data = io.open(file.url, "r"):read("*a")

    rt.tty:queue("WriteClipboard", { { mime = file.mime, payload = data, aliases = {} } })
    rt.tty:flush()
    return true
end

--- PASTE FUNCTIONS ---

function M.paste_file_uri(op, path)
	local from = Url(path)
	if from.name then
		local to = cx.active.current.cwd:join(from.name)
		ya.async(function() ya.task(op, { from = from, to = to }):spawn() end)
	end
end

local function handle_gnome_uri_list(data)
    cx.tasks.behavior:reset()
    local op = data:match("^cut") and "move" or "copy"
    ya.dbg("Gnome URI list", op, data)

    for uri in data:gmatch("[^\r\n]+") do
        if uri:sub(1, 7) == "file://" then
            M.paste_file_uri(op, ya.percent_decode(uri:sub(8)))
        end
    end
end

--- PLUGIN ENTRY FUNCTIONS ---

function M:entry(cmd)
    ya.dbg("Entry", cmd)
    local action = cmd.args[1]
    local type = cmd.args[2]
    if action and action == "copy" and type then
        if type == "uri_list" then
            copy_uri_list()
        elseif type == "file" then
            copy_file_contents()
        end
    end
end

function M:handle_clipboard_event(event)
    if event.type ~= "read" then
        return
    elseif event.data["."] then
        -- No harm in asking for unavailable types
        local mime = tostring(cx.layer) == "input" and "text/plain" or "x-special/gnome-copied-files text/uri-list"
        return require("clipboard").read_unsolicited(mime, event)
    elseif tostring(cx.layer) == "input" and event.data["text/plain"] then
        -- Paste text into input field
        ya.emit("input:feed", { event.data["text/plain"] })
    elseif event.data["x-special/gnome-copied-files"] ~= nil then
        handle_gnome_uri_list(event.data["x-special/gnome-copied-files"])
    elseif event.data["text/uri-list"] ~= nil then
        -- Use built-in clipboard URI list handler
        require("clipboard").copy_uri_list(event.data["text/uri-list"])
    end
end

return M
