inspect = require("library/inspect")
require "settings"
glcd = require "library/glcd"
console = require("library/console")
local font = love.graphics.newFont("assets/Krungthep.ttf", 14)
love.graphics.setFont(font)

otherPlayers = {}

function onWall(v)
  console.log("WALL: " .. v.name .. ': ' .. v.data.message)
end

function onPong(v)
  print("PONG: " .. v.data)
end

function chat(text)
  glcd.send("wall", {message=text})
end

function onPlayerGone(v)
  if v == nil then
    -- error from the server? we shouldn't see this
    print("error: onplayergone information was empty")
  else
    otherPlayers[v] = nil
  end
end

function onPlayerState(v)
  -- testing
  print(inspect(v))
  if v.data == nil or v.client == nil then
    -- error from the server? we shouldn't see this
    print("error: onplayerstate information was empty")
  elseif v.data and v.client ~= glcd.clientid then
    print(v.client)
    print(glcd.clientid)
    otherPlayers[v.client] = v.data
  end
end

function updateZone(z)
  for _, zone in pairs(zones) do
    --print("trying " .. z.zone .. " against " .. zone.name)
    if zone.name == z.zone then
      zone.data(z)
    end
  end
end

-- Called only once when the game is started.
function love.load()
  console.log("** starting game lost crash client")
  console.show()

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
    love.graphics.draw(p0, player_quad, 0, 0, 0, 1, 1, poffsetx, poffsety)
    -- draw other players
    for client, p in pairs(otherPlayers) do
      local rpx = math.floor(px - p.data.px)
      local rpy = math.floor(py - p.data.py)
      love.graphics.draw(p1, player_quad, rpx, rpy, 0, 1, 1, poffsetx, poffsety)
    end
    -- set target canvas back to screen and scale
    love.graphics.setCanvas()
    love.graphics.draw(canvas, 0, 0, 0, scaleX, scaleY)

    -- Write name above avatar --
    local MAX_WIDTH_OF_NAME = 200
    local name_length = string.len(glcd.name) * 10
    local background_offset = (width - name_length)/2
    local name_offset = (width - MAX_WIDTH_OF_NAME)/2

    -- Set background color to black and fill in background
    love.graphics.setColor(16, 16, 16)
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

local keymode = "game"

-- Keyboard key released.
function love.textinput(text)
  if keymode == "console" then
    console.input.text(text)
  end
end

function love.keyreleased(key)
  if keymode == "game" then
    if key == "escape" then
      love.event.quit()
    elseif key == "return" then
      console.input.start()
      keymode = "console"
    else
      pressedKey.value = key
      pressedKey.dirtyKey = false
    end
  elseif keymode == "console" then
    if key == "escape" then
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
