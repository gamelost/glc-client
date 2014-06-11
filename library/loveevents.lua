-- loveevents.lua
local loveHandlers = {}

local function addHandler(evt, name, cb)
  if not loveHandlers[evt] then
    loveHandlers[evt] = {}
  end
  assert(cb ~= nil)
  loveHandlers[evt][name] = cb
end

love.draw = nil

local function setDrawHandler(cb)
  love.draw = cb
end

local function clearHandler(evt, name)
  if loveHandlers[evt] then
    print("Clearing callback for '" .. evt .. "'.'" .. name .. "'")
    loveHandlers[evt][name] = nil
  end
end

local function callHandler(evt, ...)
  if loveHandlers[evt] then
    for k, v in pairs(loveHandlers[evt]) do
      if evt == 'draw' then
        print("draw? calling " .. k)
      end
      v(unpack({...}))
    end
  end
end

local timers = {}

local accumulatedTime = 0.0

local callEvery = function(secs, cb)
  local td = {
    lastTime = accumulatedTime,
    nextTime = accumulatedTime + secs,
    step = secs,
    cb = cb
  }
  table.insert(timers, td)
end

local timeouts = {}

local callIn = function(secs, cb)
  local td = {
    at = accumulatedTime + secs,
    cb = cb
  }
  table.insert(timeouts, td)
end

-- Called only once when the game is started.
function love.load()
  callHandler('load')
end

-- Runs continuously. Good idea to put all the computations here. 'dt'
-- is the time difference since the last update.
function love.update(dt)
  accumulatedTime = accumulatedTime + dt
  callHandler('update', dt)

  for _, v in pairs(timers) do
    if accumulatedTime >= v.nextTime then
      v.cb(accumulatedTime - v.lastTime)
      v.lastTime = accumulatedTime
      v.nextTime = v.nextTime + v.step
    end
  end

  if #timeouts > 0 then
    local sub = 0
    for idx, v in pairs(timeouts) do
      if accumulatedTime >= v.at then
        v.cb()
        table.remove(timeouts, idx - sub)
        sub = sub + 1
      end
    end
  end
end

-- Where all the drawings happen, also runs continuously.
function love.draw()
  drawHandler()
end

function love.mousepressed(x, y, button)
  callHandler('mousepressed', x, y, button)
end

-- Mouse released.
function love.mousereleased(x, y, button)
  callHandler('mousereleased', x, y, button)
end

-- Keyboard key pressed.
function love.keyreleased(key)
  callHandler('keyreleased', key)
end

-- Keyboard key released.
function love.textinput(text)
  callHandler('textinput', text)
end

function love.keypressed(key)
  callHandler('keypressed', key)
end

-- When user clicks off or on the LOVE window.
function love.focus(f)
  callHandler('focus', f)
end

-- Self-explanatory.
function love.quit()
  callHandler('quit')
end

function love.threaderror(thread, errorstr)
  print("Thread error!\n" .. errorstr)
  os.exit()
end

return {
  addHandler = addHandler,
  clearHandler = clearHandler,
  setDrawHandler = setDrawHandler,
  callEvery = callEvery,
  callIn = callIn
}
