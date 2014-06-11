require "conf"
require "library/fs"

glcd = require("library/glcd")
console = require("library/console")
handlers = require("glcd-handlers")
inspect = require("library/inspect")

function updateMyState(opts)
  for k, v in pairs(opts) do
    myState[k] = v
  end
  myPlayer.state = myState
  stateChanged = true
end

-- Called only once when the game is started.
function love.load()
  console.log("** starting game lost crash client")
  console.show()

  myState = {
    Name = glcd.name
  }
  stateChanged = true

  myPlayer = {
    state = myState,
    name = glcd.name
  }

  defaultAvatar = nil

  pressedKey = {value = nil, dirtyKey = false}
  keymode = "game"
  updateFrequency = 10 -- times per second
  updateFixedInterval = 1.0 / updateFrequency
  timeAccum = 0.0

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

  -- load player asset
  avatars = {}
  traverse("assets/avatars", setAvatar)
  px = -32
  py = -32
  -- default player speed
  pSpeed = 50
  -- default player avatar
  AvatarId = "assets/avatars/ava1.png"
  AvatarState = 0

  -- Viewport Offset. Since we want positions relative to the center of the
  -- screen, vpoffsetx and vpoffsety are added to everything on _render_ only.
  vpoffsetx = bgCanvas:getWidth() / 2
  vpoffsety = bgCanvas:getHeight() / 2

  -- initialize other player data
  otherPlayers = {}

  -- world physics.
  love.physics.setMeter(16)
  world = love.physics.newWorld(0, 0, true)

  -- monitor filesystem changes
  fs = love.thread.newThread("scripts/monitor-fs.lua")
  wadq = love.thread.newChannel("wads")
  fs:start(wadq)

  -- add callback handlers to receive server notifications
  glcd.addHandler("chat", handlers.chat)
  glcd.addHandler("error", handlers.error)
  glcd.addHandler("updateZone", handlers.updateZone)
  glcd.addHandler("playerGone", handlers.playerGone)
  glcd.addHandler("playerState", handlers.playerState)

  -- Add console handlers.
  console.defaultHandler = handlers.sendChat

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

  glcd.send("connected")
  updateMyState({Y=px, X=py, AvatarId="assets/avatars/ava1.png", AvatarState=AvatarState})
end

-- runs a set amount (`updateFixedInterval`) per second.
function love.fixed(dt)
  if stateChanged then
    glcd.send("playerState", myState)
    stateChanged = false
  end
end

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
function love.update(dt)
  world:update(dt)

  -- set a fixed interval so that we can update `updateFrequency`
  -- times per second. TODO: this is probably not accurate for low fps
  -- clients.
  timeAccum = timeAccum + dt
  if timeAccum > updateFixedInterval then
    love.fixed(timeAccum)
    timeAccum = timeAccum - updateFixedInterval
  end

  glcd.poll()
  if splash then
    elapsed = love.timer.getTime() - splash_time
    if elapsed > 1.0 then
      splash = false
      glcd.send("chat", {Sender=glcd.name, Message="Player has entered the Game!"})
    end
  end

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
    updateMyState({Y = py, X = px})
  end
end

-- Where all the drawings happen, also runs continuously.
function love.draw()

  if splash then
    -- draw splash screen
    x = width/2 - glc_w/2
    y = height/2 - glc_h/2
    love.graphics.draw(glc, x, y)
    love.graphics.setBackgroundColor(0x62, 0x36, 0xb3)
  else
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

    -- draw other players
    for name, p in pairs(otherPlayers) do
      drawPlayer(name, p)
    end

    -- draw player
    drawPlayer(glcd.name, myPlayer)
  end

  -- set target canvas back to screen and scale
  love.graphics.setCanvas()
  love.graphics.draw(bgCanvas, 0, 0, 0, scaleX, scaleY)
  love.graphics.draw(textCanvas, 0, 0, 0, 1, 1)

  console.draw()
end


-- drawText is for drawing text with a black border on the map,
-- at a given x, y location relative to the map, not the screen.
function drawText(x, y, str, r, g, b)
  -- Draw Name
  local MAX_WIDTH_OF_TEXT = 200
  local str_length = string.len(str) * 10
  local background_offset = str_length / 2
  local str_offset = MAX_WIDTH_OF_TEXT / 2

  -- lpx is the position of the text relative to viewport offset,
  -- since 0,0 is top-left corner.
  local lpx = x + vpoffsetx
  local lpy = y + vpoffsety

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

function drawPlayer(name, player)
  local p = player.state
  if not p or not p.X then
    return
  end
  local frame = math.floor(love.timer.getTime() * 3) % 2

  -- rpx and rpy - Position relative to current player. For current
  -- player, rpx+y will always be 0.
  local rpx = math.floor(px - p.X)
  local rpy = math.floor(py - p.Y)

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

  -- lpx and lpy: Position relative to viewport (top-left of screen)
  -- For current player, rpx and rpy are 0, so vpoffestx+y offset to the center
  -- of screen.
  local lpx = rpx + vpoffsetx
  local lpy = rpy + vpoffsety
  love.graphics.draw(image, quad, lpx, lpy, 0, 1, 1, 8, 8)

  if p == myState then
    drawText(rpx, rpy - 12, name, 255, 255, 255)
  else
    drawText(rpx, rpy - 12, name, 0, 255, 128)
  end

  -- Text shows for 5 seconds.
  local exp = love.timer.getTime() - 3
  if player.msg and player.msgtime > exp then
    drawText(rpx, rpy - 25, player.msg, 0, 255, 255)
  end
end

-- Avatar related functions
function setAvatar(file)
  print("setAvatar('" .. file .. "')")
  if string.sub(file, -4) == ".png" then
    print(" ... loading")
    avatars[file] = love.graphics.newImage(file)
    if defaultAvatar == nil then
      defaultAvatar = avatars[file]
    end
  end
end

function changeAvatar(id)
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

-- Mouse pressed.
function love.mousepressed(x, y, button)
end

-- Mouse released.
function love.mousereleased(x, y, button)
end

-- Keyboard key pressed.
function love.keyreleased(key)
  if pressedKey.value == key then
    pressedKey = {value = nil, dirtyKey = false}
  end
end

-- Keyboard key released.
function love.textinput(text)
  if keymode == "console" then
    console.input.text(text)
  end
end

function love.keypressed(key)
  if key == "escape" then
    love.event.quit()
  end
  if keymode == "game" then
    if key == "tab" then
      console.input.start()
      keymode = "console"
    elseif key == "v" then
      AvatarId = changeAvatar(AvatarId)
      updateMyState({AvatarId = AvatarId})
    elseif key == "s" then
      AvatarState = AvatarState + 1
      if AvatarState > 2 then
        AvatarState = 0
      end
      updateMyState({AvatarState = AvatarState})
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

-- When user clicks off or on the LOVE window.
function love.focus(f)
end

-- Self-explanatory.
function love.quit()
end

function love.threaderror(thread, errorstr)
  print("Thread error!\n" .. errorstr)
end
