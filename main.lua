require "conf"
require "library/fs"
require "library/json"
require "library/collision"

_ = require("library/underscore")
glcd = require("library/glcd")
layer = require("library/layer")
console = require("library/console")
handlers = require("glcd-handlers")
inspect = require("library/inspect")
splash_screen = require("loading/current")

function updateMyState(opts)
  for k, v in pairs(opts) do
    myState[k] = v
  end
  myPlayer.state = myState
  stateChanged = true
end

function randomQuote()
  local f = io.open("assets/loading/quotes.json", "rb")
  local quotes = json.decode(f:read("*all"))
  f:close()
  local index = math.random(#quotes.quotes)
  return '"' .. quotes.quotes[index] .. '"'
end

-- Called only once when the game is started.
function love.load()
  math.randomseed(os.time())

  -- start communication with the server.
  glcd.init()
  glcd.setPlayerStatus("ACTIVE")

  -- introduction and random quote.
  console.log("** starting game lost crash client")
  console.log(randomQuote())
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

  -- set up layers
  layers = {
    background = layer:new{width = settings.tiles_per_row * settings.tile_width,
                           height = settings.tiles_per_column * settings.tile_height,
                           priority = 5},
    parallax = layer:new{priority = 3},
    splash = layer:new{priority = 1},
    console = layer:new{priority = 10,
                        drawable = true},
    text = layer:new{priority = 9},
  }

  -- for ease of use
  all_layers = _.sort(_.values(layers), function(f, s) return f.priority < s.priority end)


  -- set up the font
  local font = love.graphics.newFont("assets/Krungthep.ttf", 14)
  love.graphics.setFont(font)

  -- load the splash screen
  splash = true
  splash_screen.load()
  splash_time = love.timer.getTime()
  layers.splash:activate()

  -- load player asset
  avatars = {}
  traverse("assets/avatars", setAvatar)

  -- default player speed
  pSpeed = 50
  -- default player avatar
  AvatarId = "assets/avatars/ava1.png"
  AvatarState = 0

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
  glcd.addHandler("playerHeartbeat",  handlers.playerHeartbeat)
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

  px, py = randomZoneLocation()

  glcd.send("connected")
  updateMyState({X = px, Y = py, AvatarId = "assets/avatars/ava1.png", AvatarState = AvatarState})
end

-- runs a set amount (`updateFixedInterval`) per second.
function love.fixed(dt)
  if stateChanged then
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
    splash_screen.update(elapsed)
    if elapsed > 1.0 then
      splash = false
      -- swap layers.
      layers.splash:deactivate()
      layers.background:activate()
      layers.text:activate()
      -- send message to everyone!
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
  
  if dy > 0 then
    dy = math.ceil(dy)
  elseif dy < 0 then
    dy = math.floor(dy)
  end
  
  if dx > 0 then
    dx = math.ceil(dx)
  elseif dx < 0 then
    dx = math.floor(dx)
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
    updateMyState({X = px, Y = py})
  end
end

-- Where all the drawings happen, also runs continuously.
function love.draw()
  -- on the start of each frame, clear all layers.
  _.invoke(all_layers, "clear")

  -- draw console layer first.
  layers.console:draw(console.draw)

  if splash then
    layers.splash:draw(splash_screen.draw)
    layers.splash:background(255, 255, 255, 0)
  else
    -- draw zones
    if #zones == 0 then
      console.log("No zones found.")
    end
    for _, zone in pairs(zones) do
      layers.background:draw(zone.update)
    end

    -- draw other players
    for name, p in pairs(otherPlayers) do
      layers.background:draw(drawPlayer, {p.name, p})
      layers.text:draw(drawPlayerAttributes, {p.name, p})
    end

    layers.background:draw(drawPlayer, {glcd.name, myPlayer})
    layers.text:draw(drawPlayerAttributes, {glcd.name, myPlayer})
  end

  -- and at the end of the frame, render all layers.
  _.invoke(all_layers, "render")
end

function drawPlayerAttributes(name, player)
  local p = player.state
  if not p or not p.X then
    return
  end
  local rpx = math.floor(px - p.X)
  local rpy = math.floor(py - p.Y)
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

-- drawText is for drawing text with a black border on the map,
-- at a given x, y location relative to the map, not the screen.
function drawText(x, y, str, r, g, b)
  -- Draw Name
  local MAX_WIDTH_OF_TEXT = 200
  local str_offset = MAX_WIDTH_OF_TEXT / 2

  local mx, my = layers.background:midpoint()
  local rx, ry = layers.background:coordinates(mx + x, my + y)

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

function drawPlayer(name, player)
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

  local mx, my = layers.background:midpoint()
  love.graphics.translate(mx, my)

  local rpx = math.floor(px - p.X)
  local rpy = math.floor(py - p.Y)
  love.graphics.translate(rpx, rpy)

  local quad = love.graphics.newQuad(frameOffset, stateOffset, 16, 16, image:getWidth(), image:getHeight())
  love.graphics.draw(image, quad, 0, 0, 0, 1, 1, 8, 8)
end

-- Avatar related functions
function setAvatar(file)
  --print("setAvatar('" .. file .. "')")
  if string.sub(file, -4) == ".png" then
    --print(" ... loading")
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
    elseif key == "x" then
      px, py = randomZoneLocation()
      updateMyState({X = px, Y = py})
    elseif key == "l" then
      local currZoneId, currZoneCoords, currZone = getZoneOffset(px, py)
      if currZone then
        currZone.state.toggle_next_layer(currZone.state.tiles)
      end
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
  glcd.setPlayerStatus("QUIT")
end

function love.threaderror(thread, errorstr)
  print("Thread error!\n" .. errorstr)
end
