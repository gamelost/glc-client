require "settings"

glcd = require("library/glcd")
console = require("library/console")
handlers = require("glcd-handlers")

-- Called only once when the game is started.
function love.load()
  console.log("** starting game lost crash client")
  console.show()

  pressedKey = {value = nil, dirtyKey = false}
  keymode = "game"

  -- set up the canvas
  canvas = love.graphics.newCanvas(settings.tiles_per_row * settings.tile_width,
                                   settings.tiles_per_column * settings.tile_height)
  canvas:setFilter("nearest", "nearest") -- linear interpolation
  scaleX, scaleY = win.width / canvas:getWidth(), win.height / canvas:getHeight()

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
  -- initialize other player data
  otherPlayers = {}

  -- generate a table of avatars from the first row of sprite image
  avatars = {}
  local quad_width, quad_height = p0:getWidth(), p0:getHeight()
  for i=0,quad_width/16 do
    avatars[i+1] = love.graphics.newQuad(i*16, 0, 16, 16, quad_width, quad_height)
  end

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
  glcd.send("playerState", {py=0, px=0})
end

-- Runs continuously. Good idea to put all the computations here. 'dt'
-- is the time difference since the last update.
function love.update(dt)
  world:update(dt)

  glcd.poll()
  if splash then
    elapsed = love.timer.getTime() - splash_time
    if elapsed > 1.0 then
      splash = false
      glcd.send("wall", {message="Player has entered the Game!"})
    end
  end
  if pressedKey.value ~= nil and not pressedKey.dirtyKey then
    --console.log("Button released:"..pressedKey.value)
    if pressedKey.value == "0" then
      px = 0
      py = 0
    end

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

    glcd.send("playerState", {py=py, px=px})

    pressedKey.dirtyKey = true
  end
end

function hashPlayerName(name)
  return #name % 8 + 1
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
      console.log("No zones found.")
    end
    for _, zone in pairs(zones) do
      zone.update()
    end
    -- draw player
    love.graphics.draw(p0, avatars[hashPlayerName(glcd.name)], 0, 0, 0, 1, 1, poffsetx, poffsety)
    -- draw other players
    for client, p in pairs(otherPlayers) do
      local rpx = math.floor(px - p.px)
      local rpy = math.floor(py - p.py)
      love.graphics.draw(p1, avatars[hashPlayerName(client)], rpx, rpy, 0, 1, 1, poffsetx, poffsety)
    end
    -- set target canvas back to screen and scale
    love.graphics.setCanvas()
    love.graphics.draw(canvas, 0, 0, 0, scaleX, scaleY)

    -- Write name above avatar --
    local MAX_WIDTH_OF_NAME = 200
    for client, p in pairs(otherPlayers) do
      if client ~= glcd.name then
        local rpx = math.floor(px - p.px)
        local rpy = math.floor(py - p.py)

        local name_length = string.len(client) * 10
        local background_offset = name_length / 2
        local name_offset = MAX_WIDTH_OF_NAME / 2

        love.graphics.setColor(0, 0, 0, 128)
        love.graphics.rectangle("fill", width/2-background_offset+rpx*scaleX, height/2-60+rpy*scaleY, name_length, 18)

        -- Set color of name to white and fill in name
        love.graphics.setColor(0, 255, 128)
        love.graphics.printf(client, width/2-name_offset+rpx*scaleX, height/2-60+rpy*scaleY, MAX_WIDTH_OF_NAME, "center")

        -- Reset color back to white
        love.graphics.setColor(255, 255, 255)
      end
    end

    local name_length = string.len(glcd.name) * 10
    local background_offset = (width - name_length)/2
    local name_offset = (width - MAX_WIDTH_OF_NAME)/2

    -- Set background color to black and fill in background
    love.graphics.setColor(0, 0, 0, 128)
    love.graphics.rectangle("fill", background_offset, height/2 - 16*scaleY, name_length, 18)

    -- Set color of name to white and fill in name
    love.graphics.setColor(255, 255, 255)
    love.graphics.printf(glcd.name, name_offset, height/2 - 16*scaleY, MAX_WIDTH_OF_NAME, "center")

    -- Reset color back to white
    love.graphics.setColor(255, 255, 255)
  end

  console.draw()
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
function love.textinput(text)
  if keymode == "console" then
    console.input.text(text)
  end
end

function love.keyreleased(key)
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
