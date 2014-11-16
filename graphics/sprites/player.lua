local sprite = require('graphics/sprites/sprite')

local defaultAvatar = nil

-- for name, otherPlaya in pairs(otherPlayers) do
--   -- UGLY piece of shit hack.
--   --print(otherPlaya.name .. ": {" .. otherPlaya.state.X .. "," .. otherPlaya.state.Y .. "}")
--   otherPlaya.state['radius_w'] = myPlayer.radius_w
--   otherPlaya.state['radius_h'] = myPlayer.radius_h
--   otherPlaya.state['width'] = myPlayer.width
--   otherPlaya.state['height'] = myPlayer.height
--   if didPlayerBumpedIntoOtherPlayer(playerCoords, otherPlaya.state) then
--     -- revert to old coordinates
--     playerCoords.x = oldPxy.x
--     playerCoords.y = oldPxy.y
--   end
-- end

-- drawText is for drawing text with a black border on the map,
-- at a given x, y location relative to the map, not the screen.
local function drawText(x, y, str, r, g, b)
  -- Draw Name
  local MAX_WIDTH_OF_TEXT = 200
  local str_offset = MAX_WIDTH_OF_TEXT / 2
  local rx, ry = layers.background:coordinates(x, y)

  love.graphics.push()
  love.graphics.translate(rx, ry)
  love.graphics.translate(- str_offset, 0)

  -- fake outlines
  love.graphics.setColor(0, 0, 0, 255)
  love.graphics.printf(str, -2, -2, MAX_WIDTH_OF_TEXT, "center")
  love.graphics.printf(str, -2,  0, MAX_WIDTH_OF_TEXT, "center")
  love.graphics.printf(str, -2,  2, MAX_WIDTH_OF_TEXT, "center")

  love.graphics.printf(str,  0, -2, MAX_WIDTH_OF_TEXT, "center")
  love.graphics.printf(str,  0,  2, MAX_WIDTH_OF_TEXT, "center")

  love.graphics.printf(str,  2, -2, MAX_WIDTH_OF_TEXT, "center")
  love.graphics.printf(str,  2,  0, MAX_WIDTH_OF_TEXT, "center")
  love.graphics.printf(str,  2,  2, MAX_WIDTH_OF_TEXT, "center")

  -- Set color of text and fill in.
  love.graphics.setColor(r, g, b)
  love.graphics.printf(str,  0,  0, MAX_WIDTH_OF_TEXT, "center")
  love.graphics.pop()
end

local function drawHealthBar(x, y, hp)
  local hp = 50
  local BAR_WIDTH = 40
  local BAR_HEIGHT = 4
  local BORDER_WIDTH = 2

  local overallHeight = BAR_HEIGHT + 2 * BORDER_WIDTH
  local overallWidth = BAR_WIDTH + 2 * BORDER_WIDTH

  local overallOffset = overallWidth / 2
  local rx, ry = layers.background:coordinates(x, y)

  love.graphics.push()

  love.graphics.translate(rx, ry)
  love.graphics.translate(- overallOffset, 0)

  -- draw border
  love.graphics.setColor(0, 0, 0, 255)
  love.graphics.rectangle("fill", 0, 0, overallWidth, overallHeight)

  love.graphics.translate(BORDER_WIDTH, BORDER_WIDTH)

  -- draw red part
  love.graphics.setColor(255, 0, 0, 255)
  love.graphics.rectangle("fill", 0, 0, BAR_WIDTH, BAR_HEIGHT)

  -- draw green part
  love.graphics.setColor(0, 255, 0, 255)
  love.graphics.rectangle("fill", 0, 0, (hp / settings.player.default_hitpoint) * BAR_WIDTH, BAR_HEIGHT)

  love.graphics.pop()
end

-- Attributes are Text and Health Bar
local function drawPlayerAttributes(info)

  if info.name == glcd.name then
    drawText(info.x, info.y - 15, info.name, 255, 255, 255)
  else
    drawText(info.x, info.y - 15, info.name, 0, 255, 128)
  end

  -- Text shows for 3 seconds.
  local exp = love.timer.getTime() - 3
  if info.msg and info.msgtime > exp then
    drawText(info.x, info.y - 25, info.msg, 0, 255, 255)
  end

  drawHealthBar(info.x, info.y - 10, info.hitPoint)
end

local function drawPlayer(info)

  local frame = math.floor(love.timer.getTime() * 3) % 2

  -- Draw Avatar
  local image = avatars[info.avatarid]
  if image == nil then
    image = defaultAvatar
  end

  local frameOffset = frame * 16
  if frameOffset >= image:getWidth() then
    frameOffset = 0
  end

  if info.avatarstate == nil then
    info.avatarstate = 0
  end
  local stateOffset = info.avatarstate * 16
  if stateOffset >= image:getHeight() then
    stateOffset = 0
  end

  love.graphics.push()
  love.graphics.translate(info.x, info.y)

  local quad = love.graphics.newQuad(frameOffset, stateOffset, info.width, info.height, image:getWidth(), image:getHeight())

  local direction = info.direction or "right"
  if direction == "right" then
    love.graphics.draw(image, quad, 0, 0, 0, -1, 1, info.width / 2, info.height / 2)
  else
    love.graphics.draw(image, quad, 0, 0, 0, 1, 1, info.width / 2, info.height / 2)
  end

  love.graphics.pop()
end

-- Avatar related functions
local function setAvatar(file)
  if string.sub(file, -4) == ".png" then
    avatars[file] = love.graphics.newImage(file)
    if defaultAvatar == nil then
      defaultAvatar = avatars[file]
    end
  end
end

local function changeAvatar(id)
  local keys = {}
  local n    = 0
  local first = nil
  local ret = false
  for k, v in pairs(avatars) do
    n = n + 1
    keys[n] = k
    if ret then
      return k
    end
    if k == id then
      ret = true
    end
    if not first then
      first = k
    end
  end
  return first
end

local Player =
  { data        = {}
  , spriteType  = "Player"
  , setAvatar   = setAvatar
  , changeAvatar = changeAvatar
  }

function Player:update(coords)
  -- no-op.
end

function Player:draw()
  layers.background:draw(drawPlayer, {self})
  layers.text:draw(drawPlayerAttributes, {self})
end

function Player:updateState(data)
  self.avatarid = data.AvatarId or self.avatarid
  self.avatarstate = data.AvatarState or self.avatarstate
  self.hitPoint = data.hitPoint or self.hitPoint
  self.name = data.name or self.name

  -- for now, until we get the whole capitalization mess sorted out, ugh
  baseData = {
    x = data.X,
    y = data.Y,
    direction = data.direction,
    zoneid = data.currZoneId
  }
  self:updateBaseData(baseData)
end

Player.__index = Player

-- TODO
-- current zone id -- needs to be checked universally (except for Player)
-- delete :update(playerCoords) -- should be self anyway

function Player.new(obj)

  inspect = require('util/inspect')
  print("*** in player.new")
  print(inspect(obj))

  -- for now, until we get the whole capitalization mess sorted out, ugh
  spriteData = {
    x = obj.X,
    y = obj.Y,
    width = obj.width,
    height = obj.width,
    direction = obj.direction,
    zoneid = obj.zoneid
  }
  self = sprite.new(spriteData)

  -- hacky way to set "inheritance"
  -- TODO: there must be a better way using __index
  local updateBaseData = self.updateState
  setmetatable(self, Player)
  self.updateBaseData = updateBaseData
  self:updateState(obj)
  return self
end

return Player
