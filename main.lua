require "conf"

local events = require("library/loveevents")
local player = require("library/player")
local fs = require "library/fs"
local glcd = require("library/glcd")
local console = require("library/console")
local handlers = require("glcd-handlers")
local inspect = require("library/inspect")

local pSpeed = 75

px = -32
py = -32

local function onLoad()
  console.log("** starting game lost crash client")
  console.show()

  pressedKey = {value = nil, dirtyKey = false}
  keymode = "game"

  -- set up the canvas
  bgCanvas = love.graphics.newCanvas(settings.tiles_per_row * settings.tile_width,
                                   settings.tiles_per_column * settings.tile_height)
  bgCanvas:setFilter("nearest", "nearest") -- linear interpolation
  scaleX, scaleY = win.width / bgCanvas:getWidth(), win.height / bgCanvas:getHeight()

  textCanvas = love.graphics.newCanvas(win.width, win.height)
  textCanvas:setFilter("nearest", "nearest") -- linear interpolation

  -- set up the font
  local font = love.graphics.newFont("assets/Krungthep.ttf", 14)
  love.graphics.setFont(font)

  -- load the splash screen
  splash = true
  splash_time = love.timer.getTime()
  glc = love.graphics.newImage("assets/gamelostcrash.png")
  glc_w, glc_h = glc:getDimensions()
  width, height = love.graphics.getDimensions()

  -- Viewport Offset. Since we want positions relative to the center of the
  -- screen, vpoffsetx and vpoffsety are added to everything on _render_ only.
  vpoffsetx = bgCanvas:getWidth() / 2
  vpoffsety = bgCanvas:getHeight() / 2

  -- world physics.
  love.physics.setMeter(16)
  world = love.physics.newWorld(0, 0, true)

  -- monitor filesystem changes
  fs = love.thread.newThread("scripts/monitor-fs.lua")
  wadq = love.thread.newChannel("wads")
  fs:start(wadq)

  -- add callback handlers to receive server notifications
  glcd.addHandler("chat", player.onChat)
  glcd.addHandler("error", handlers.error)
  glcd.addHandler("updateZone", handlers.updateZone)

  -- Add console handlers.
  console.defaultHandler = player.chat

  -- initialize zones
  zones = {}
  wads = wadq:demand()
  for wad, _ in pairs(wads) do
    local zone = require("library/zone")
    table.insert(zones, zone.new(wad))
    console.log("loaded zone from " .. wad)
  end

  for k, zone in pairs(zones) do
    print(string.format("zone[%d]: %s", k, inspect(zone.name)))
    zone.init()
  end
end

events.addHandler('load', 'main', onLoad)

-- Get current zone.
--  wx - number: World x-coordinate.
--  wy - number: World y-coordinate.
--  return - zone offset number, its transformed coordinates, and the selected zone object itself.
function getZoneOffset(wx, wy)
  local zpoint = nil
  local zIndex = nil
  local mZone = nil
  local xOffset = 0 

-- Assume 1-D horizontal zones for now.
--  for _, zone in pairs(zones) do
  for idx = 1, #zones do
    local zId = zones[idx].state.data.id
    -- local zoneWidth = zone.state.tileset.width * zone.state.tileset.tilewidth
    local zoneWidth = settings.zone_width * settings.tile_width -- For now until the server passes the sorted zones table from left to right
    local zoneHeight = settings.zone_height * settings.tile_height -- For now until the server passes the sorted zones table from left to right
    local wxMin = -1 * zId *  zoneWidth
    local wyMin = -1 * zId *  zoneHeight
    local wxMax = wxMin - zoneWidth
    local wyMax = wyMin - zoneHeight
    --print(string.format("getZoneOffset: idx=%d, wxy=(%d,%d), zId=%d, zoneDimen=(%d,%d), wxyMin=(%d,%d), wxyMax=(%d,%d)", idx, wx, wy, zId, zoneWidth, zoneHeight, wxMin, wyMin, wxMax, wyMax))

    if wx <= wxMin and wx >= wxMax and wy <= wyMin and wy >= wyMax then
      --print("getZoneOffset: Found! zId=", zId)
      zpoint = {x = zId * wx, y = wy}
      zIndex = idx;
      mZone = zone
      break
    else
      --print("getZoneOffset: Not found! zId=", zId)
      xOffset = xOffset + zoneWidth
    end

    idx = idx + 1
  end

  return zIndex, zpoint, mZone
end

function hasCollision(mZone, x, y)
  local isCollidable = false

  if mZone then
    --print("hasCollision: ", inspect(mZone.state.tileset.metadatas))
    local metadatas = mZone.state.tileset.metadatas
    local metalayer = metadatas.layers[1]
    local tileId = 0

    x = math.abs(x)
    y = math.abs(y)
    
    -- use 'settings' global variable for now.
    local gridx = math.ceil(x / settings.tile_width)
    local gridy = math.ceil(y / settings.tile_height)
    local metaIndex = (gridy - 1) * settings.zone_width + gridx
    local metadata = nil

    --print(string.format("[%d](%d,%d): ", metaIndex, gridx, gridy, inspect(metalayer.data[metaIndex])))
    if metalayer then
      metadata = metadatas[metalayer.data[metaIndex]]
      --print("metadata:", inspect(metadata))
    end
    if metadata then
      isCollidable = metadata.properties.collidable
    end
  end

  return isCollidable
end

-- Runs continuously. Good idea to put all the computations here. 'dt'
-- is the time difference since the last update.
local function onGameUpdate(dt)
  world:update(dt)

  local speed = pSpeed * dt
  dx = 0
  dy = 0
  if love.keyboard.isDown("up") then
    dy = dy + speed
  end
  if love.keyboard.isDown("down") then
    dy = dy - speed
  end
  if love.keyboard.isDown("left") then
    dx = dx + speed
  end
  if love.keyboard.isDown("right") then
    dx = dx - speed
  end

  if dx ~= 0 or dy ~= 0 then
    local oldPxy = {x = px, y = py}
    py = py + dy
    px = px + dx
    playerCoords = {x = (px), y = (py)}
    local currZoneId, currZoneCoords, currZone  = getZoneOffset(playerCoords.x, playerCoords.y)

    if hasCollision(zones[currZoneId], playerCoords.x, playerCoords.y) then
      -- revert to old coordinates
      px = oldPxy.x
      py = oldPxy.y
    end
    player.updateState({Y = py, X = px})
  end
end

-- Where all the drawings happen, also runs continuously.
local function drawSplash()
  -- draw splash screen
  love.graphics.setCanvas()
  x = width/2 - glc_w/2
  y = height/2 - glc_h/2
  love.graphics.draw(glc, x, y)
  love.graphics.setBackgroundColor(0x62, 0x36, 0xb3)
end

events.setDrawHandler(drawSplash)

local function drawGame()
  -- Clear canvases.
  bgCanvas:clear(0x62, 0x36, 0xb3)
  textCanvas:clear(0, 0, 0, 0)

  love.graphics.setCanvas(bgCanvas) -- draw to this canvas
  -- draw zones
  if #zones == 0 then
    console.log("No zones found.")
  end
  for _, zone in pairs(zones) do
    zone.update()
  end

  player.drawPlayers()

  -- set target canvas back to screen and scale
  love.graphics.setCanvas()
  love.graphics.draw(bgCanvas, 0, 0, 0, scaleX, scaleY)
  love.graphics.draw(textCanvas, 0, 0, 0, 1, 1)

  console.draw()
end

local function endSplash()
  events.setDrawHandler(drawGame)
  player.chat("Player has entered the Game!")
  events.addHandler('update', 'game', onGameUpdate)
end

events.callIn(1.5, endSplash)

local function onKeyRelease(key)
  if pressedKey.value == key then
    pressedKey = {value = nil, dirtyKey = false}
  end
end

events.addHandler('keyreleased', 'main', onKeyRelease)

-- Keyboard key released.
local function onTextInput(text)
  if keymode == "console" then
    console.input.text(text)
  end
end

events.addHandler('textinput', 'main', onTextInput)

local function onKeyPress(key)
  if key == "escape" then
    love.event.quit()
  end
  if keymode == "game" then
    if key == "tab" then
      console.input.start()
      keymode = "console"
    elseif key == "v" then
      player.changeAvatar()
    elseif key == "s" then
      player.changeAvatarState()
    end
  elseif keymode == "console" then
    if key == "tab" then
      console.input.cancel()
      keymode = "game"
    elseif #key > 1 then
      console.input.key(key)
    end
  end
end

events.addHandler('keypressed', 'main', onKeyPress)
