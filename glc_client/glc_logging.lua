local glc_logging = {}

glc_logging.do_show = false
glc_logging.messages = {}
glc_logging.max_rows = 8 -- max rows to display
glc_logging.fade_after = 15 -- fades after 15 seconds. Set it to 0 to force it to be always on.
local inc = 12 -- TODO: get current text height instead


local function drawBackground()
	local r, g, b, a = love.graphics.getColor()
	love.graphics.setColor(128, 128, 128, 128) -- Hardcoded for now.
	love.graphics.rectangle("fill", 0, 0, win.width, (glc_logging.max_rows * inc) + 3)
	love.graphics.setColor(r, g, b, a)
end

local function log(msg)
	table.insert(glc_logging.messages, 1, msg)
	print("logged:", msg)
end
glc_logging.log = log

local function display_log()
	if not glc_logging.do_show then 
		return 
	end

	drawBackground()
	for i = 1, glc_logging.max_rows do
		local k = glc_logging.messages[i]
		--print("messages["..i.."]:", glc_logging.messages[i])
		if k ~= nil then
			love.graphics.print(k, 0, (i - 1) * inc)
		end
	end
end
glc_logging.display_log = display_log

return glc_logging
