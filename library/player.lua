-- players.lua
--
-- Dealing with and rendering players, including current player.

require "conf"
local fs = require "library/fs"
local events = require("library/loveevents")
local glcd = require("library/glcd")
local inspect = require("library/inspect")
local mapdrawing = require("library/mapdrawing")
local console = require("library/console")

local myclientid = glcd.clientid

-- Current player information.
local myState = {
  Name = glcd.name
}

local myPlayer = {
  state = myState,
  name = glcd.name
}

-- Avatar images and information for love
local defaultAvatar = nil
local defaultAvatarId = nil
local avatars = {}

-- Updating player state
local stateChanged = true
local function updateMyState(opts)
  for k, v in pairs(opts) do
    myState[k] = v
  end
  myPlayer.state = myState
  stateChanged = true
end

local function sendPlayerState()
  if stateChanged then
    glcd.send("playerState", myState)
    stateChanged = false
  end
end

events.callEvery((1/10), sendPlayerState)

-- And handling other players in this world.
local otherPlayers = {}

local function onPlayerState(v)
  local clientid = v.ClientId
  if clientid ~= myclientid then
    if otherPlayers[clientid] == nil then
      otherPlayers[clientid] = {name=clientid}
    end
    if v.Name then
      otherPlayers[clientid].name = v.Name
    end
    otherPlayers[clientid].state = v
  end
end

local function onPlayerGone(v)
  local clientid = v.ClientId
  if clientid then
    otherPlayers[clientid] = nil
  end
end

-- Avatar related functions
local function setAvatar(file)
  print("setAvatar('" .. file .. "')")
  if string.sub(file, -4) == ".png" then
    print(" ... loading")
    avatars[file] = love.graphics.newImage(file)
    if defaultAvatar == nil then
      defaultAvatar = avatars[file]
      defaultAvatarId = file
    end
  end
end

-- Called only once when the game is started.
local function loadPlayerData()
  defaultAvatar = nil

  -- Load in avatar images, and set default.
  fs.traverse("assets/avatars", setAvatar)

  -- add callback handlers to receive server notifications
  glcd.addHandler("playerGone", onPlayerGone)
  glcd.addHandler("playerState", onPlayerState)

  glcd.send("connected")
  updateMyState({Y=px, X=px, AvatarId=defaultAvatarId, AvatarState=0})
end

events.addHandler('load', 'player', loadPlayerData)

local function drawPlayer(name, player)
  local p = player.state
  if not p or not p.X then
    return
  end
  local frame = math.floor(love.timer.getTime() * 3) % 2

  -- Draw Avatar
  local image = avatars[p.AvatarId]
  if image == nil then
    image = defaultAvatar
  end

  local frameOffset = frame * 16
  if frameOffset >= image:getWidth() then
    frameOffset = 0
  end

  if p.AvatarState == nil then
    p.AvatarState = 0
  end
  local stateOffset = p.AvatarState * 16
  if stateOffset >= image:getHeight() then
    stateOffset = 0
  end

  love.graphics.setCanvas(bgCanvas)
  local quad = love.graphics.newQuad(frameOffset, stateOffset, 16, 16, image:getWidth(), image:getHeight())

  mapdrawing.drawImageQuad(image, quad, p.X, p.Y, 0, 1, 1, 8, 8)

  if p == myState then
    mapdrawing.drawText(p.X, p.Y + 12, name, 255, 255, 255)
  else
    mapdrawing.drawText(p.X, p.Y + 12, name, 0, 255, 128)
  end

  -- Text shows for 5 seconds.
  local exp = love.timer.getTime() - 3
  if player.msg and player.msgtime > exp then
    mapdrawing.drawText(p.X, p.Y + 25, player.msg, 0, 255, 255)
  end
end

-- Where all the drawings happen, also runs continuously.
local function drawPlayers()
  -- draw other players
  for name, p in pairs(otherPlayers) do
    drawPlayer(name, p)
  end

  -- draw player
  drawPlayer(glcd.name, myPlayer)
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

function doChat(text)
  glcd.send("chat", {Message = text, Sender = glcd.name})
  myPlayer.msg = text
  myPlayer.msgtime = love.timer.getTime()
end

function onOtherChat(v)
  if not v.Sender then
    v.Sender = 'ANNOUNCE:'
  end
  console.log(v.Sender .. ': ' .. v.Message)
  if otherPlayers[v.Sender] then
    otherPlayers[v.Sender].msg = v.Message
    otherPlayers[v.Sender].msgtime = love.timer.getTime()
  end
end

return {
  drawPlayers = drawPlayers,
  changeAvatar = changeAvater,
  updateState = updateMyState,
  chat = doChat,
  onChat = onOtherChat
}
