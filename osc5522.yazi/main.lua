
local M = {}
local PackageName = "osc5522"

function M:setup(opts)

end

local function handle_gnome_uri_list(data)
    local is_cut = data:match("^cut")
    local uri_list = string.gsub(data, "^.-\n", "") or data
    if is_cut then
        require("dnd").cut_uri_list(uri_list)
    else
        require("clipboard").copy_uri_list(uri_list)
    end
end

function M:handle_clipboard_event(event)
    if event and event.type == "mimetypes" and event.pw then
		-- No harm in asking for unavailable types
		local mimetypes = "text/plain text/uri-list x-special/gnome-copied-files"
		rt.tty:queue("ReadClipboard", { mimes = mimetypes, pw = event.pw, name = "Paste Event", primary = event.primary })
		rt.tty:flush()
    elseif event and event.type == "data" then
        if event.data["x-special/gnome-copied-files"] ~= nil then
            handle_gnome_uri_list(event.data["x-special/gnome-copied-files"])
        elseif event.data["text/uri-list"] ~= nil then
			require("clipboard").copy_uri_list(event.data["text/uri-list"])
		end
	end
end

return M
