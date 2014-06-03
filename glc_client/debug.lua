--local _Debug table for holding all variables
local _Debug = {
	errors = {},
	prints = {},
	order = {},
	orderOffset = 0,
	longestOffset = 0,

	drawOverlay = false,
	tickTime = 0.5,
	tick = 0.5,
	drawTick = true,

	input = "",
	inputMarker = 0,

	lastH = nil,
	lastCut = nil,
	lastRows = 1,

	--Character Configuration
	allowed = "abcdefghijklmnopqrstuvwxyzåäö1234567890+´¨'-.,<§ !#¤%&/()=?`^*_:;½@£$€{[]}\\~|" .. '"',
	Font = love.graphics.newFont(12),
	BigFont = love.graphics.newFont(24),
}

--Settings
_DebugSettings = {
	MultipleErrors = false,
	OverlayColor = {0, 0, 0},
}


--Print all settings
_DebugSettings.Settings = function()
	print("Settings:")
	
	print("   _DebugSettings.MultipleErrors  [Boolean]  Controls if errors should appear multiple times")
	print("   _DebugSettings.OverlayColor  [{int, int, int}]  Sets the color of the overlay")
end




local super_print = print

--Override print and call super
_G["print"] = function(...)
	super_print(...)
	local str = ""
	local args = {...}
	for i,v in pairs(args) do
		str = str .. tostring(v)
		if i < #args then
			str = str .. "       "
		end
	end
	table.insert(_Debug.prints, str)
	table.insert(_Debug.order, "p" .. tostring(#_Debug.prints))
end


--Error catcher
_Debug.handleError = function(err)
	if _DebugSettings.MultipleErrors == false then
		for i,v in pairs(_Debug.errors) do
			if v == err then
				return --Don't print the same error multiple times!
			end
		end
	end
	table.insert(_Debug.errors, err)
	table.insert(_Debug.order, "e" .. tostring(#_Debug.errors))
end


--Get Linetype
_Debug.lineInfo = function(str)
	local prefix = string.sub(str, 1, 1)
	local err = (prefix == "e")
	local index = tonumber(string.sub(str, 2, string.len(str)))
	return err, index
end


--Overlay drawer
_Debug.overlay = function()
	local font = love.graphics.getFont()
	local r, g, b, a = love.graphics.getColor()
	
	local fontSize = _Debug.Font:getHeight()
	local w = love.graphics.getWidth()
	local h = love.graphics.getHeight()
	local R, G, B = unpack(_DebugSettings.OverlayColor)
	love.graphics.setColor(R, G, B, 220)
	love.graphics.rectangle("fill", 0, 0, w, h)
	love.graphics.setColor(255, 255, 255)
	love.graphics.setFont(_Debug.Font)
	local count = 0
	local cutY = 0
	if h ~= _Debug.lastH then --Did the height of the window change?
		local _cutY = h - 40
		cutY = _cutY
		local rows = 0
		while rows * (fontSize + 2) < _cutY do --Find out how long the scissor should be
			rows = rows + 1
			cutY = rows * (fontSize + 2)
		end
		_Debug.lastRows = rows
	else
		cutY = _Debug.lastCut --Use the last good value
	end
	love.graphics.setScissor(0, 0, w, cutY + 1)
	for i = 1 + _Debug.orderOffset, #_Debug.order do
		count = count + 1
		local v = _Debug.order[i]
		local x = 5
		local y = (fontSize + 2) * count
		local err, index = _Debug.lineInfo(v) --Obtain message and type
		local msg = err and _Debug.errors[index] or _Debug.prints[index]
		if err then --Add a red and fancy prefix
			love.graphics.setColor(255, 0, 0)
			love.graphics.print("[Error]", x, y)
			x = 50
		end
		love.graphics.setColor(255, 255, 255)
		love.graphics.print(msg, x, y)
	end
	love.graphics.setScissor()
	love.graphics.print(">", 6, h - 27)
	local str = _Debug.input
	if _Debug.drawTick then
		local totLen = string.len(_Debug.input)
		local len = 0
		if totLen > 0 then
			len = _Debug.Font:getWidth(string.sub(_Debug.input, 1, _Debug.inputMarker))
		end
		love.graphics.print("_", 20 + len, h - 27)
	end
	love.graphics.print(str, 20, h - 27)
	if (#_Debug.order - _Debug.longestOffset > _Debug.lastRows - 1) then
		love.graphics.setFont(_Debug.BigFont)
		love.graphics.print("...", w - 30, h - 30)
	end
	love.graphics.setColor(r, g, b, a)
	love.graphics.setFont(font)
	_Debug.lastCut = cutY
	_Debug.lastH = h
end

--Handle Mousepresses
_Debug.handleMouse = function(a, b, c)
	if c == "wd" and _Debug.orderOffset < #_Debug.order - _Debug.lastRows + 1 then
		_Debug.orderOffset = _Debug.orderOffset + 1
		if _Debug.orderOffset > _Debug.longestOffset then
			_Debug.longestOffset = _Debug.orderOffset
		end
	end
	if c == "wu" and _Debug.orderOffset > 0 then
		_Debug.orderOffset = _Debug.orderOffset - 1
	end
end

--Check if the key is allowed or just a function key
_Debug.keyAllowed = function(key)
	for i = 1, string.len(_Debug.allowed) do
		local k = string.sub(_Debug.allowed, i, i)
		if (k == key) then
			return true
		end
	end
	return false
end

--Process Keypresses
_Debug.keyConvert = function(key, unicode)
	if unicode ~= nil and unicode ~= 0 then
		local char = string.char(unicode)
		if _Debug.keyAllowed(char:lower()) then
			_Debug.inputMarker = _Debug.inputMarker + 1
			return char
		end
	end
	if key == "left" then
		_Debug.inputMarker = _Debug.inputMarker - 1
		if _Debug.inputMarker < 0 then
			_Debug.inputMarker = 0
		end
		return ""
	end
	if key == "right" then
		_Debug.inputMarker = _Debug.inputMarker + 1
		if _Debug.inputMarker > string.len(_Debug.input) then
			_Debug.inputMarker = string.len(_Debug.input)
		end
		return ""
	end
	if key == "backspace" then
		local suffix = string.sub(_Debug.input, _Debug.inputMarker + 1, string.len(_Debug.input))
		if _Debug.inputMarker == 0 then --Keep the input from copying itself
			suffix = ""
		end
		_Debug.input = string.sub(_Debug.input, 1, _Debug.inputMarker - 1) .. suffix
		_Debug.inputMarker = _Debug.inputMarker - 1
		if _Debug.inputMarker < 0 then
			_Debug.inputMarker = 0
		end
		return ""
	end
	if key == "return" then --Execute Script
		print("> " .. _Debug.input)
		xpcall(function() loadstring(_Debug.input)() end, _Debug.handleError)
		_Debug.input = ""
		_Debug.inputMarker = 0
		return ""
	end
end

--Handle Keypresses
_Debug.handleKey = function(a, b)
	if a == "f8" then
		if love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift") or love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl") then --Support for both Shift and CTRL
			_Debug.drawOverlay = not _Debug.drawOverlay --Toggle
		end
	elseif _Debug.drawOverlay then
		local add = _Debug.keyConvert(a, b) --Needed for backspace, do NOT optimize
		add = (add ~= nil) and add or ""
		local suffix = string.sub(_Debug.input, _Debug.inputMarker, (string.len(_Debug.input) >= _Debug.inputMarker) and string.len(_Debug.input) or _Debug.inputMarker + 1)
		if _Debug.inputMarker == 0 then --Keep the input from copying itself
			suffix = ""
		end
		_Debug.input = string.sub(_Debug.input, 0, _Debug.inputMarker - 1) .. add .. suffix
	end
end

--Modded version of original love.run
_G["love"].run = function()
    if love.load then xpcall(love.load, _Debug.handleError) end

    local dt = 0

    -- Main loop time.
    while true do
        if love.timer then
            love.timer.step()
            dt = love.timer.getDelta()
        end
		_Debug.tick = _Debug.tick - dt
		if _Debug.tick <= 0 then
			_Debug.tick = _Debug.tickTime + _Debug.tick
			_Debug.drawTick = not _Debug.drawTick
		end
        if love.update then xpcall(function() love.update(dt) end, _Debug.handleError) end -- will pass 0 if love.timer is disabled
        if love.graphics then
            love.graphics.clear()
            if love.draw then xpcall(love.draw, _Debug.handleError) end
			if _Debug.drawOverlay then _Debug.overlay() end
        end

        -- Process events.
        if love.event then
            for e,a,b,c in love.event.poll() do
                if e == "q" then
					local quit = false
					if not love.quit then
						xpcall(function() quit = love.quit() end, _Debug.handleError)
					end
                    if not quit then
                        if love.audio then
                            love.audio.stop()
                        end
                        return
                    end
                end
				local skipEvent = false
				if e == "kp" then --Keypress
					_Debug.handleKey(a, b)
				end
				if e == "mp" and _Debug.drawOverlay then --Mousepress
					_Debug.handleMouse(a, b, c)
				end
				if not _Debug.drawOverlay or e ~= "kp" then
					xpcall(function() love.handlers[e](a,b,c) end, _Debug.handleError)
				end
            end
        end

        if love.timer then love.timer.sleep(1) end
        if love.graphics then love.graphics.present() end

    end

end