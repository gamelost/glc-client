require "settings"
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

  myState = {}
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
  px = 0
  py = 0
  -- default player speed
  pSpeed = 50
  -- default player avatar
  AvatarId = "assets/avatars/ava1.png"
  -- get the middle of the screen
  poffsetx = - bgCanvas:getWidth() / 2
  poffsety = - bgCanvas:getHeight() / 2
  -- adjust for the middle of the sprite itself
  poffsetx = poffsetx + 8
  poffsety = poffsety + 8
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
  glcd.addHandler("wall", handlers.wall)
  glcd.addHandler("error", handlers.error)
  glcd.addHandler("updateZone", handlers.updateZone)
  glcd.addHandler("playerGone", handlers.playerGone)
  glcd.addHandler("playerState", handlers.playerState)

  -- Add console handlers.
  console.defaultHandler = chat

  -- initialize zones
  zones = {}
  wads = wadq:demand()
  for wad, _ in pairs(wads) do
    local zone = require("library/zone")
    table.insert(zones, zone.new(wad))
    console.log("loaded zone from " .. wad)
  end
  for _, zone in pairs(zones) do
    zone.init()
  end

  glcd.send("connected")
  updateMyState({Y=0, X=0, AvatarId="assets/avatars/ava1.png", AvatarState=0})
end

-- runs a set amount (`updateFixedInterval`) per second.
function love.fixed(dt)
  if stateChanged then
    print(inspect(myState))
    glcd.send("playerState", myState)
    stateChanged = false
  end
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
      glcd.send("wall", {Message="Player has entered the Game!"})
    end
  end
  if pressedKey.value ~= nil and not pressedKey.dirtyKey then
    --console.log("Button released:"..pressedKey.value)
    if pressedKey.value == "0" then
      px = 0
      py = 0
      updateMyState({Y = py, X = px})
    end

    local speed = pSpeed * dt
    if pressedKey.value == "up" then
      py = py + speed
      updateMyState({Y = py})
    end
    if pressedKey.value == "down" then
      py = py - speed
      updateMyState({Y = py})
    end
    if pressedKey.value == "left" then
      px = px + speed
      updateMyState({X = px})
    end
    if pressedKey.value == "right" then
      px = px - speed
      updateMyState({X = px})
    end

    if pressedKey.value == "v" then
      AvatarId = changeAvatar(AvatarId, avatars)
      updateMyState({AvatarId = AvatarId})
    end
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
    -- draw player
    drawPlayer(glcd.name, myPlayer)

    -- draw other players
    for name, p in pairs(otherPlayers) do
      drawPlayer(name, p)
    end
  end

  -- set target canvas back to screen and scale
  love.graphics.setCanvas()
  love.graphics.draw(bgCanvas, 0, 0, 0, scaleX, scaleY)
  love.graphics.draw(textCanvas, 0, 0, 0, 1, 1)

  console.draw()
end

function drawText(rpx, rpy, str, r, g, b)
  -- Draw Name
  local MAX_WIDTH_OF_TEXT = 200
  local str_length = string.len(str) * 10
  local background_offset = str_length / 2
  local str_offset = MAX_WIDTH_OF_TEXT / 2

  local rx = (width / 2) + (rpx * scaleX)
  local ry = (height / 2) + (rpy * scaleY)

  love.graphics.setCanvas(textCanvas)
  love.graphics.setColor(0, 0, 0, 255)
  love.graphics.printf(str, rx - str_offset - 2, ry - 2, MAX_WIDTH_OF_TEXT, "center")
  love.graphics.printf(str, rx - str_offset - 2, ry, MAX_WIDTH_OF_TEXT, "center")
  love.graphics.printf(str, rx - str_offset - 2, ry + 2, MAX_WIDTH_OF_TEXT, "center")

  love.graphics.printf(str, rx - str_offset, ry - 2, MAX_WIDTH_OF_TEXT, "center")
  love.graphics.printf(str, rx - str_offset, ry, MAX_WIDTH_OF_TEXT, "center")
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
  if not p then
    print("Can't figure out state of player:")
    print(inspect(player))
    return
  end
  local frame = math.floor(love.timer.getTime() * 3) % 2
  local rpx = math.floor(px - p.X)
  local rpy = math.floor(py - p.Y)

  -- Draw Avatar
  image = avatars[p.AvatarId]
  if image == nil then
    image = defaultAvatar
  end

  love.graphics.setCanvas(bgCanvas)
  local quad = love.graphics.newQuad(frame*16, 0, 16, 16, image:getWidth(), image:getHeight())
  love.graphics.draw(image, quad, rpx, rpy, 0, 1, 1, poffsetx, poffsety)

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
  if string.sub(file, -4) == ".png" then
    avatars[file] = love.graphics.newImage(file)
    if defaultAvatar == nil then
      defaultAvatar = avatars[file]
    end
  end
end

function changeAvatar(id, avatars)
  local keys = {}
  local n    = 0
  for k,v in pairs(table.sort(avatars)) do
    n = n + 1
    keys[n] = k
  end
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
    else
      pressedKey.value = key
      pressedKey.dirtyKey = false
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
