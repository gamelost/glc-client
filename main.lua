require "settings"

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

  -- thread/queue for nsq processing
  nsqt = love.thread.newThread("test/test-nsq.lua")
  nsqq = love.thread.newChannel("nsq")
  nsqt:start(nsqq)

  -- monitor filesystem changes
  fs = love.thread.newThread("scripts/monitor.lua")
  wadq = love.thread.newChannel("wads")
  fs:start(wadq)

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
end

-- Runs continuously. Good idea to put all the computations here. 'dt'
-- is the time difference since the last update.
function love.update(dt)
  if splash then
    elapsed = love.timer.getTime() - splash_time
    if elapsed > 1.0 then
      splash = false
    end
  end
  if pressedKey.value ~= nil and not pressedKey.dirtyKey then
    --logging.log("Button released:"..pressedKey.value)

    local speed = 300 * dt
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
