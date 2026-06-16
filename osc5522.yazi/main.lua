--- @sync entry
local M = {}

function M:setup(opts)

end

local function handle_gnome_uri_list(data)
    local is_cut = data:match("^cut")
    if is_cut then
        ya.dbg("Cut", uri_list)
        require("dnd").cut_uri_list(data)
    else
        ya.dbg("Copy", uri_list)
        require("clipboard").copy_uri_list(data)
    end
end

local function copy_uri_list()
    local list = require("dnd").selected_uri_list()
    if #list == 0 then
        return false
    end
    local uri_list = table.concat(list, "\n")
    local gnome_list = "copy\n" .. uri_list

    local copy = { { mime = "text/uri-list", data = uri_list, alias = "text/plain" } }
    if gnome_list then
        copy[#copy + 1] = { mime = "x-special/gnome-copied-files", data = gnome_list, alias = "" }
    end

    -- ya.dbg("Copy URI List", copy)

    rt.tty:queue("WriteClipboard", copy)
    rt.tty:flush()
    return true
end

local function copy_file_contents()
    local list = require("dnd").selected_uri_list()
    return true
end

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
    if event and event.type == "mimetypes" and event.pw then
        -- No harm in asking for unavailable types
        local mimetypes = "text/plain text/uri-list x-special/gnome-copied-files code/file-list"
        rt.tty:queue("ReadClipboard", { mimes = mimetypes, pw = event.pw, name = "Paste Event", primary = event.primary })
        rt.tty:flush()
    elseif event and event.type == "data" then
        self:handle_paste(event.data)
    end
end

function M:handle_paste(data)
    if data["x-special/gnome-copied-files"] ~= nil then
        handle_gnome_uri_list(data["x-special/gnome-copied-files"])
    elseif data["text/uri-list"] ~= nil then
        require("clipboard").copy_uri_list(data["text/uri-list"])
    elseif data["code/file-list"] ~= nil then
        require("clipboard").copy_file_list(data["code/file-list"])
    end
end

return M
