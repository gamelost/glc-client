require "settings"
glcd = require "library/glcd"

otherPlayers = {}

function onWall(v)
  print("WALL: " .. v.name .. ': ' .. v.data.message)
end

function onPong(v)
  print("PONG: " .. v.data)
end

function onPlayerGone(v)
  if v.data.client ~= glcd.clientid then
    otherPlayers[v.data.client] = nil
  end
end

function onPlayerState(v)
  if v.data.client ~= glcd.clientid then
    logging.log(v.data.client)
    otherPlayers[v.data.client] = v.data
  end
end

function updateZone(z)
  for _, zone in pairs(zones) do
    --print("trying " .. z.data.data.zone .. " against " .. zone.name)
    if zone.name == z.data.data.zone then
      zone.data(z.data.data)
    end
  end
end

-- Called only once when the game is started.
function love.load()
  logging = require("library/logging")
  logging.log("** starting game lost crash client")
  logging.do_show = true

  pressedKey = {value = nil, dirtyKey = false}

  -- set up the canvas
  canvas = love.graphics.newCanvas(settings.tiles_per_row * settings.tile_width,
                                   settings.tiles_per_column * settings.tile_height)
  canvas:setFilter("nearest", "nearest") -- linear interpolation
  scaleX, scaleY = win.width / canvas:getWidth(), win.height / canvas:getHeight()

  -- load the splash screen
  splash = true
  splash_time = love.timer.getTime()
  glc = love.graphics.newImage("assets/gamelostcrash.png")
  glc_w, glc_h = glc:getDimensions()
  width, height = love.graphics.getDimensions()

  -- load player asset
  p0 = love.graphics.newImage("assets/Player0.png")
  p1 = love.graphics.newImage("assets/Player1.png")
  px = 0
  py = 0
  -- get the middle of the screen
  poffsetx = - canvas:getWidth() / 2
  poffsety = - canvas:getHeight() / 2
  -- adjust for the middle of the sprite itself
  poffsetx = poffsetx + 8
  poffsety = poffsety + 8
  player_quad = love.graphics.newQuad(0, 0, 16, 16, p0:getWidth(), p0:getHeight())

  -- monitor filesystem changes
  fs = love.thread.newThread("scripts/monitor-fs.lua")
  wadq = love.thread.newChannel("wads")
  fs:start(wadq)

  -- add callback handlers to receive server notifications
  glcd.addHandler("wall", onWall)
  glcd.addHandler("pong", onPong)
  glcd.addHandler("updateZone", updateZone)
  glcd.addHandler("playerGone", onPlayerGone)
  glcd.addHandler("playerState", onPlayerState)

  -- initialize zones
  zones = {}
  wads = wadq:demand()
  for wad, _ in pairs(wads) do
    local zone = require("library/zone")
    table.insert(zones, zone.new(wad))
    logging.log("loaded zone from " .. wad)
  end
  for _, zone in pairs(zones) do
    zone.init()
  end

  glcd.send("connected")
  glcd.send("playerState", {py=0, px=0})
end

-- Runs continuously. Good idea to put all the computations here. 'dt'
-- is the time difference since the last update.
function love.update(dt)
  glcd.poll()
  if splash then
    elapsed = love.timer.getTime() - splash_time
    if elapsed > 1.0 then
      splash = false
      glcd.send("wall", {message="Player has entered the Game!"})
    end
  end
  if pressedKey.value ~= nil and not pressedKey.dirtyKey then
    --logging.log("Button released:"..pressedKey.value)

    local speed = 300 * dt
    -- if pressedKey.value >= "a" and pressedKey.value <= "z" then
    --   glcd.send("wall", {message=pressedKey.value})
    -- end
    if pressedKey.value == "up" then
      py = py + speed
    end
    if pressedKey.value == "down" then
      py = py - speed
    end
    if pressedKey.value == "left" then
      px = px + speed
    end
    if pressedKey.value == "right" then
      px = px - speed
    end

    glcd.send("playerState", {py=py, px=px})

    pressedKey.dirtyKey = true
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
    canvas:clear(0x62, 0x36, 0xb3)
    love.graphics.setCanvas(canvas) -- draw to this canvas
    -- draw zones
    if #zones == 0 then
      logging.log("No zones found.")
    end
    for _, zone in pairs(zones) do
      zone.update()
    end
    -- draw player
    love.graphics.draw(p0, player_quad, 0, 0, 0, 1, 1, poffsetx, poffsety)
    -- draw other players
    for client, p in pairs(otherPlayers) do
      local rpx = p.data.px - px
      local rpy = p.data.py - py
      if rpx > 0 and rpy > 0 and rpx < width and rpy < width then
        love.graphics.draw(p1, player_quad, rpx, rpy, 0, 1, 1, poffsetx, poffsety)
      end
    end
    -- set target canvas back to screen and scale
    love.graphics.setCanvas()
    love.graphics.draw(canvas, 0, 0, 0, scaleX, scaleY)
  end

  logging.display_log()
end

-- Mouse pressed.
function love.mousepressed(x, y, button)
end

-- Mouse released.
function love.mousereleased(x, y, button)
end

-- Keyboard key pressed.
function love.keypressed(key)
end

-- Keyboard key released.
function love.keyreleased(key)
  splash = false
  pressedKey.value = key
  pressedKey.dirtyKey = false
  if key == "escape" then
    love.event.quit()
  elseif key == "ralt" then
    logging.do_show = not logging.do_show
  elseif key == "0" then
    px = 0
    py = 0
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
