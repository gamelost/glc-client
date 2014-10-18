require "conf"
require "library/fs"
require "library/json"
require "library/collision"

_ = require("library/underscore")
clock = require("library/clock")
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
    Name = glcd.name,
    direction = "right"
  }
  stateChanged = true

  killVerbs = {"killed", "murdered", "smashed", "exploded", "dispatched", "neutralized", "X'd"}

  myPlayer = {
    state = myState,
    name = glcd.name,
    height = 16,
    width = 16,
    radius_w = 8,
    radius_h = 8,
    hitPoint = 1,
  }

  defaultAvatar = nil

  pressedKey = {value = nil, dirtyKey = false}
  keymode = "game"

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
  layers.splash:activate()

  -- set up splash screen to display for one second.
  local splash_cb = function()
    splash = false
    -- swap layers.
    layers.splash:deactivate()
    layers.background:activate()
    layers.text:activate()
    clock.cancel("updateSplash")
    -- send message to everyone!
    glcd.send("chat", {Sender=glcd.name, Message="Player has entered the Game!"})
  end
  clock.schedule(1, splash_cb, "setSplash")
  clock.every(1/16, splash_screen.update, "updateSplash")

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

  -- initialize bulletList
  bulletList = {}

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
  glcd.addHandler("broadcast", handlers.broadcast)

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
  glcd.send("broadcast", {request= "playerState"})
  updateMyState({X = px, Y = py, AvatarId = "assets/avatars/ava1.png", AvatarState = AvatarState})

  local updateTimer = function()
    if stateChanged then
      glcd.send("playerState", myState)
      stateChanged = false
    end
  end
  -- 20 times per second.
  clock.every(1/20, updateTimer, "updateState")
end

-- Runs continuously. Good idea to put all the computations here. 'dt'
-- is the time difference since the last update.
function love.update(dt)
  clock.update()
  world:update(dt)

  glcd.poll()

  local speed = pSpeed * dt
  local dx = 0
  local dy = 0
  local direction = "right"
  if love.keyboard.isDown("up") then
    dy = dy - speed
    direction = "up"
  end
  if love.keyboard.isDown("down") then
    dy = dy + speed
    direction = "down"
  end
  if love.keyboard.isDown("right") then
    dx = dx + speed
    direction = "right"
  end
  if love.keyboard.isDown("left") then
    dx = dx - speed
    direction = "left"
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

  local playerCoords = {
    x = (px),
    y = (py),
    radius_h = myPlayer.radius_h,
    radius_w = myPlayer.radius_w,
    direction = direction,
    name = myPlayer.name,
    width = myPlayer.width,
    height = myPlayer.height,
  }

  if dx ~= 0 or dy ~= 0 then
    local oldPxy = {x = px, y = py}
    py = py + dy
    px = px + dx
    -- TODO: need to put 'px' and 'py' into myPlayer and then use myPlayer for all player states.
    playerCoords.x = px
    playerCoords.y = py

    local currZoneId, currZone  = getZoneOffset(playerCoords.x, playerCoords.y)

    if hasCollision(zones[currZoneId], playerCoords.x, playerCoords.y) then
      -- revert to old coordinates
      playerCoords.x = oldPxy.x
      playerCoords.y = oldPxy.y
    end

    for name, otherPlaya in pairs(otherPlayers) do
      -- UGLY piece of shit hack.
      print(otherPlaya.name .. ": {" .. otherPlaya.state.X .. "," .. otherPlaya.state.Y .. "}")
      otherPlaya.state['radius_w'] = myPlayer.radius_w
      otherPlaya.state['radius_h'] = myPlayer.radius_h
      otherPlaya.state['width'] = myPlayer.width
      otherPlaya.state['height'] = myPlayer.height
      if didPlayerBumpedIntoOtherPlayer(playerCoords, otherPlaya.state) then
        -- revert to old coordinates
        playerCoords.x = oldPxy.x
        playerCoords.y = oldPxy.y
      end
    end

    px = playerCoords.x
    py = playerCoords.y
    updateMyState({X = px, Y = py, direction = direction})
  end

  updateBulletState()

  for _, bullet in ipairs(bulletList) do
    print(bullet.name .. "'s bullet is at " .. bullet.X .. "," .. bullet.Y)
    if isPlayerHitByBullet(playerCoords, bullet) then
      myPlayer.hitPoint = myPlayer.hitPoint - bullet.damage

      local currZoneId, currZone = getZoneOffset(playerCoords.x, playerCoords.y)
      if hasCollision(zones[currZoneId], bullet.X, bullet.Y) then
        bulletList[i] = nil
      end

      if myPlayer.hitPoint <= 0 then
        local randomVerb = killVerbs[math.random(1, #killVerbs)]
        local killString = (myPlayer.name .. " was " .. randomVerb .. " by " .. bullet.name)
        print(killString)
        -- TODO: Need a way to send a system event instead.
        glcd.send("chat", {Sender=glcd.name, Message=killString})
      else
        print(myPlayer.name .. " was hit by " .. bullet.name)
      end
    end
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

    -- set background layer transform coordinates. we do this so that
    -- we can have our avatar in the middle of the screen.
    local mx, my = layers.background:midpoint()
    local bx = mx - myPlayer.state.X
    local by = my - myPlayer.state.Y
    layers.background:translate(bx, by)

    -- similarly with text, but in terms of the background coordinate
    -- system since it's scaled up.
    local rx, ry = layers.background:coordinates(bx, by)
    layers.text:translate(rx, ry)

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

    for i, bullet in pairs(bulletList) do
      layers.background:draw(drawBullet, {bullet.X, bullet.Y})
    end
  end

  -- and at the end of the frame, render all layers.
  _.invoke(all_layers, "render")
end

function updateBulletState()
  local time, direction, startTime, delta, X, Y
  for i, bullet in pairs(bulletList) do
    time = love.timer.getTime()
    direction = bullet.direction or "right"
    startTime = bullet.startTime
    delta = time - startTime
    X = bullet.X
    Y = bullet.Y

    -- Add check to ensure bullet stops (or bounces) at obstacles and at another
    -- player.

    -- if bullet hasn't hit an obstacle after two seconds, remove bullet.
    if time > bullet.startTime + 2 then
      print("bullet" .. i .. " from " .. bullet.name .. " didn't hit anything")
      bulletList[i] = nil
    else
      -- update bullet X to move to the direction based on time
      -- uses pSpeed to avoid the bullet being slower than player speed
      if direction == "right" then
        bullet.X = X + delta * pSpeed
      elseif direction == "left" then
        bullet.X = X - delta * pSpeed
      elseif direction == "down" then
        bullet.Y = Y + delta * pSpeed
      elseif direction == "up" then
        bullet.Y = Y - delta * pSpeed
      end
    end

    local currZoneId, currZone = getZoneOffset(bullet.X, bullet.Y)
    if hasCollision(zones[currZoneId], bullet.X, bullet.Y) then
      bulletList[i] = nil
    end
  end
end

function drawPlayerAttributes(name, player)
  local p = player.state
  if not p or not p.X or not p.Y then
    return
  end
  if p == myState then
    drawText(p.X, p.Y - 12, name, 255, 255, 255)
  else
    drawText(p.X, p.Y - 12, name, 0, 255, 128)
  end

  -- Text shows for 3 seconds.
  local exp = love.timer.getTime() - 3
  if player.msg and player.msgtime > exp then
    drawText(p.X, p.Y - 25, player.msg, 0, 255, 255)
  end
end

-- drawText is for drawing text with a black border on the map,
-- at a given x, y location relative to the map, not the screen.
function drawText(x, y, str, r, g, b)
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

function drawPlayer(name, player)
  local p = player.state
  if not p or not p.X or not p.Y then
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

  love.graphics.push()
  love.graphics.translate(p.X, p.Y)

  local quad = love.graphics.newQuad(frameOffset, stateOffset, 16, 16, image:getWidth(), image:getHeight())

  local direction = player.state.direction or "right"
  if direction == "right" then
    love.graphics.draw(image, quad, 0, 0, 0, -1, 1, 8, 8)
  else
    love.graphics.draw(image, quad, 0, 0, 0, 1, 1, 8, 8)
  end

  love.graphics.pop()
end

function drawBullet(x, y)
  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.setColor(0, 0, 0, 255)
  love.graphics.circle("fill", 0, 0, 2, 10)
  love.graphics.pop()
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

function bulletLocation(direction, X, Y)
  if direction == "left" then
    return { X = X + 10, Y = Y }
  elseif direction == "up" then
    return { X = X, Y = Y + 10 }
  elseif direction == "down" then
    return { X = X, Y = Y - 10 }
  else -- direction will always fire in the right if unset.
    return { X = X - 10, Y = Y }
  end
end

function fireBullet()
  print("firing bullet")
  -- draw a layer containing the bullet and move it?
  local location = bulletLocation(myState.direction, myState.X, myState.Y)
  return {
    name = myPlayer.name,
    direction = myState.direction,
    X = location.X,
    Y = location.Y,
    damage = 1,
    startTime = love.timer.getTime(),
  }
end

-- Game Mode Keys Table
local game_keys = {
  tab = function ()
    console.input.start()
    keymode = "console"
  end,
  v = function ()
    AvatarId = changeAvatar(AvatarId)
    updateMyState({AvatarId = AvatarId})
  end,
  s = function ()
    AvatarState = AvatarState + 1
    if AvatarState > 2 then
      AvatarState = 0
    end
    updateMyState({AvatarState = AvatarState})
  end,
  [" "] = function ()
    glcd.send("broadcast", {request = "fireBullet", bullet = fireBullet()})
  end,
  x = function ()
    px, py = randomZoneLocation()
    updateMyState({X = px, Y = py})
  end,
  l = function ()
    local currZoneId, currZone = getZoneOffset(px, py)
    if currZone then
      currZone.state.toggle_next_layer(currZone.state.tiles)
    end
  end,
  p = function()
    if love.keyboard.isDown("lctrl") then
      local screenshot = love.graphics.newScreenshot()
      screenshot:encode("screenshot" .. os.date("%d-%m-%Y-%H-%M-%S") .. ".png")
    end
  end,
}

function love.keypressed(key)
  if key == "escape" then
    glcd.sendSynchronous("chat", {Sender=glcd.name, Message="Player has left the Game!"})
    love.event.quit()
  end
  if keymode == "game" then
    return game_keys[key] and game_keys[key]()
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
