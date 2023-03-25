--[[
	Copyright 2023 Zakret

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]--

function descriptor()
	return {
		title = "VLC Rename";
		version = "0.1";
		author = "Zakret";
		url = "https://github.com/Zakret/vlc-rename/";
		shortdesc = "Rena&me current file";
		description = [[
<h1>vlc-rename</h1>"
When you are playing a file, use VLC Rename to rename the current file<br />
and rejoin it to the current playlist. <br />
This extension has been tested on GNU Linux and MS Windows 10 with VLC 3.x.<br />
The author is not responsible for damage caused by this extension.<br />
This code is based on another extension VLC Delete created by Surrim: <br />
https://github.com/surrim/vlc-delete/
		]];
	}
end

function fileExists(file)
	return io.popen("if exist " .. file .. " (echo 1)") : read "*l" == "1"
end

function sleep(seconds)
	local t0 = os.clock()
	local tOriginal = t0
	while os.clock() - t0 <= seconds and os.clock() >= tOriginal do end
end

function windowsRename(file, newfile, trys, pause)
	file = string.gsub(file, "/", "\\")
	newfile = string.gsub(newfile, "/", "\\")
	if not fileExists("\"" .. file .. "\"") then return nil, "File does not exist" end
	for i = trys, 1, -1
	do
		retval, err = os.rename(file,newfile)
		--retval, err = os.execute("del " .. file )
		if retval == true then
			return true
		end
		sleep(pause)
	end
	return {nil, "Unable to rename file"}
end

function removeItem(id)
	vlc.playlist.delete(id)
	vlc.playlist.gotoitem(id + 1)
end

function restoreItem(id, uri)
	item = {}
	if ( string.match(uri, "^[a-zA-z]:/") ~= nil ) then
		item.path = "file:///" .. uri
	else
		item.path = "file://" .. uri
	end
	vlc.playlist.add({item})
	vlc.playlist.move(vlc.playlist.current(), id) --does not work
	vlc.deactivate()
end


function activate()
	local inputitem = vlc.input.item()
	uri = inputitem:uri()
	uri = string.gsub(uri, "^file:///", "")
	if ( string.match(uri, "^[a-zA-z]:/") == nil ) then
		uri = "/" .. uri
	end
	uri = vlc.strings.decode_uri(uri)
	local oldname = string.match(uri, '[^/]+$')
	local oldpath = string.gsub(uri, '[^/]+$', "")
	extension = string.match(uri, '%.[^%.]+$')
	oldname = string.gsub(oldname, '%.[^%.]+$', "")
	wa = vlc.dialog("VLC Rename")
	wa:add_label("File to rename:", 1, 1, 1, 1)
	wa1 = wa:add_text_input( oldname, 1, 2, 3, 1 )
	wa:add_label(extension, 4, 2, 1, 1)
	wa2 = wa:add_text_input( oldpath, 1, 3, 3, 1 )
	wa:add_label(" - path", 4, 3, 1, 1)
	wa:add_button("Apply", click_Apply, 2, 4, 1, 1)
	wa:add_button("Cancel", click_Cancel, 3, 4, 1, 1)
end

function click_Apply()
	wa:update()
	local newname = wa1:get_text()
	local newpath = wa2:get_text()
	wa:delete()
	if (newname == nil or newpath == nil) then
		vlc.deactivate()
	end
	local newuri = newpath .. newname .. extension
	vlc.msg.info("[vlc-rename] renaming: \"" .. uri .. "\" to \"" .. newuri .. "\"")
	local playlistid = vlc.playlist.current()
	removeItem(playlistid)
	if (package.config:sub(1, 1) == "/") then -- not windows
		retval, err = os.execute("mv --help > /dev/null")
		if (retval ~= nil) then
			retval, err = os.execute("mv \"" .. uri .. "\" \"" .. newuri .. "\"")
		end
	else -- windows
		retval, err = windowsRename(uri, newuri, 3, 1)
	end
	
	if (retval == nil) then
		restoreItem(playlistid, uri)
		vlc.msg.info("[vlc-rename] error: " .. err)
		d = vlc.dialog("VLC Rename")
		d:add_label("Could not rename \"" .. uri .. "\"", 1, 1, 1, 1)
		d:add_label(err, 1, 2, 1, 1)
		d:add_button("OK", click_ok, 1, 3, 1, 1)
	else
		restoreItem(playlistid, newuri)
	end
end

function click_Cancel()
	wa:delete()
	vlc.deactivate()
end

function click_ok()
	d:delete()
	vlc.deactivate()
end

function deactivate()
	vlc.deactivate()
end

function close()
	deactivate()
end

function meta_changed()
end
