require "conf"
require "util/fs"
require "net/json"
require "geometry/collision"

_ = require("util/underscore")
clock = require("util/clock")
inspect = require("util/inspect")
layer = require("graphics/layer")
console = require("graphics/console")
glcd = require("net/glcd")
handlers = require("net/glcd-handlers")

Gamelost = {}
Gamelost.splash_screen = require("assets/loading-screens/current")
Gamelost.game_keys     = require("input/game_keys")
Gamelost.randomQuote   = require("util/random_quote")
Gamelost.Bullet        = require("graphics/sprites/bullet")
Gamelost.Player        = require("graphics/sprites/player")
Gamelost.spriteList    = {}

-- TODO: Should not be global, but bullet, game_keys, and avatar are using
-- updateMyState.
function updateMyState(opts)
  for k, v in pairs(opts) do
    myPlayerState[k] = v
  end
  Gamelost.spriteList[glcd.clientid]:updateState(myPlayerState)
  stateChanged = true
end

-- Called only once when the game is started.
function love.load()
  math.randomseed(os.time())

  -- start communication with the server.
  glcd.init()
  glcd.setPlayerStatus("ACTIVE")

  -- introduction and random quote.
  console.log("** starting game lost crash client")
  console.log(Gamelost.randomQuote())
  console.show()

  stateChanged = true

  myPlayerState = {
    direction = "right",
    name = glcd.name,
    height = 16,
    width = 16,
    radius_w = 8,
    radius_h = 8,
    hitPoint = settings.player.default_hitpoint,
    zoneid = 0,
    name = glcd.name,
    AvatarId="assets/avatars/ava1.png",
    AvatarState=0
  }

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
  Gamelost.splash_screen.load()
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
  clock.every(1/16, Gamelost.splash_screen.update, "updateSplash")

  -- load player asset
  avatars = {}
  traverse("assets/avatars", Gamelost.Player.setAvatar)

  -- default player speed
  pSpeed = 50

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
    local zone = require("zone/zone")
    table.insert(zones, zone.new(wad))
    console.log("loaded zone from " .. wad)
  end

  for k, zone in pairs(zones) do
    print(string.format("zone[%d]: %s", k, inspect(zone.name)))
    zone.init()
  end

  px, py = randomZoneLocation()

  glcd.send("connected")
  glcd.send("broadcast", {request = "playerState"})

  -- Put current client into the spriteList
  Gamelost.spriteList[glcd.clientid] = Gamelost.Player.new(myPlayerState)

  updateMyState({X=px,
                 Y=py})

  local updateState = function()
    if stateChanged then
      glcd.send("playerState", myPlayerState)
      stateChanged = false
    end
  end

  -- 10 times per second.
  clock.every(1/10, updateState, "updateState")
end

-- Runs continuously. Good idea to put all the computations here. 'dt'
-- is the time difference since the last update.
function love.update(dt)
  clock.update()
  world:update(dt)

  glcd.poll()

  -----------------------------------------------------------------------------
  -- BEGIN Code to check movement keys and broadcasting of location
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
    radius_h = myPlayerState.radius_h,
    radius_w = myPlayerState.radius_w,
    direction = direction,
    name = myPlayerState.name,
    width = myPlayerState.width,
    height = myPlayerState.height,
  }

  if dx ~= 0 or dy ~= 0 then
    local oldPxy = {x = px, y = py}
    py = py + dy
    px = px + dx
    playerCoords.x = px
    playerCoords.y = py

    local currZoneId, currZone  = getZoneOffset(playerCoords.x, playerCoords.y)

    if hasCollision(zones[currZoneId], playerCoords.x, playerCoords.y) then
      -- revert to old coordinates
      playerCoords.x = oldPxy.x
      playerCoords.y = oldPxy.y
    end

    updateMyState({X=playerCoords.x,
                   Y=playerCoords.y,
                   direction=direction,
                   zoneid=currZoneId})
  end

  for name, sprite in pairs(Gamelost.spriteList) do
    sprite:update()
    if sprite.remove == true then
      Gamelost.spriteList[name] = nil
    end
  end

  -- Counter to count the number of global variables.
  -- Feel free to delete. Not deleted since 2014-11-14
  -- myUniqueCounter = myUniqueCounter or 0
  -- if myUniqueCounter < 1 then
  --   l = io.open("list_of_global_vars", "w")
  --   for k,v in pairs(_G) do
  --     l:write(k, "\n")
  --   end
  --   l.close()
  --   myUniqueCounter = myUniqueCounter + 1
  -- end
end

-- Where all the drawings happen, also runs continuously.
function love.draw()
  -- on the start of each frame, clear all layers.
  _.invoke(all_layers, "clear")

  -- draw console layer first.
  layers.console:draw(console.draw)

  -- set background layer transform coordinates. we do this so that
  -- we can have our avatar in the middle of the screen.
  local mx, my = layers.background:midpoint()
  local bx = mx - myPlayerState.X
  local by = my - myPlayerState.Y

  if splash then
    layers.splash:draw(Gamelost.splash_screen.draw)
    layers.splash:background(255, 255, 255, 0)
  else
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

    for _, sprite in pairs(Gamelost.spriteList) do
      sprite:draw()
    end

  end

  -- and at the end of the frame, render all layers.
  _.invoke(all_layers, "render")
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
    glcd.sendSynchronous("chat", {Sender=glcd.name, Message="Player has left the Game!"})
    love.event.quit()
  end
  if keymode == "game" then
    return Gamelost.game_keys[key] and Gamelost.game_keys[key]()
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
