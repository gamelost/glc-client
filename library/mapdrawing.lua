-- mapdrawing.lua
--
-- drawing sprites and text relative to the world map.

local events = require("library/loveevents")
local glcd = require("library/glcd")

-- drawText is for drawing text with a black border on the map,
-- at a given x, y location relative to the map, not the screen.
local function drawText(x, y, str, r, g, b)
  -- Draw Name
  local MAX_WIDTH_OF_TEXT = 200
  local str_length = string.len(str) * 10
  local background_offset = str_length / 2
  local str_offset = MAX_WIDTH_OF_TEXT / 2

  -- lpx is the position of the text relative to viewport offset,
  -- since px and py are the center of the screen.
  local lpx = (px - x) + vpoffsetx
  local lpy = (py - y) + vpoffsety

  -- Since the text is scaled differently than the main map, rx+ry are
  -- conversions of lpx and lpy to the scaled locations relative to
  -- the screen.
  local rx = lpx * scaleX
  local ry = lpy * scaleY

  love.graphics.setCanvas(textCanvas)
  love.graphics.setColor(0, 0, 0, 255)
  love.graphics.printf(str, rx - str_offset - 2, ry - 2, MAX_WIDTH_OF_TEXT, "center")
  love.graphics.printf(str, rx - str_offset - 2, ry, MAX_WIDTH_OF_TEXT, "center")
  love.graphics.printf(str, rx - str_offset - 2, ry + 2, MAX_WIDTH_OF_TEXT, "center")

  love.graphics.printf(str, rx - str_offset, ry - 2, MAX_WIDTH_OF_TEXT, "center")
  love.graphics.printf(str, rx - str_offset, ry + 2, MAX_WIDTH_OF_TEXT, "center")

  love.graphics.printf(str, rx - str_offset + 2, ry - 2, MAX_WIDTH_OF_TEXT, "center")
  love.graphics.printf(str, rx - str_offset + 2, ry, MAX_WIDTH_OF_TEXT, "center")
  love.graphics.printf(str, rx - str_offset + 2, ry + 2, MAX_WIDTH_OF_TEXT, "center")

  -- Set color of text and fill in.
  love.graphics.setColor(r, g, b)
  love.graphics.printf(str, rx - str_offset, ry, MAX_WIDTH_OF_TEXT, "center")

  love.graphics.setColor(255, 255, 255)
end

local function drawImageQuad(image, quad, x, y, ...)
  -- lpx and lpy: Position relative to viewport (top-left of screen)
  -- For current player, rpx and rpy are 0, so vpoffestx+y offset to the center
  -- of screen.
  love.graphics.setCanvas(bgCanvas)
  local lpx = (px - x) + vpoffsetx
  local lpy = (py - y) + vpoffsety
  love.graphics.draw(image, quad, lpx, lpy, unpack({...}))
end

return {
  drawText = drawText,
  drawImageQuad = drawImageQuad
}
