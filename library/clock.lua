-- clock.lua
--
-- For timers, tweening, scheduling, etc.

local timers = {}
local nextTimer = love.timer.getTime() + 1000000.0

local function runTimers(now)
  nextTimer = now + 100000.0
  for k, v in pairs(timers) do
    if v.time <= now then
      v.cb()
      if v.freq == 1 then
        timers[k] = nil
      else
        if v.freq > 0 then
          v.freq = v.freq - 1
        end
        v.time = now + v.step
        if v.time < nextTimer then
          nextTimer = v.time
        end
      end
    else
      -- make sure that slower-speed timers keep on ticking. probably
      -- best to have a priority queue here.
      local nextInterval = v.time - now
      if nextInterval < nextTimer then
        nextTimer = v.time
      end
    end
  end
end

local function update()
  local now = love.timer.getTime()
  if nextTimer and nextTimer <= now then
    runTimers(now)
  end
end

local function addTimer(t)
  if t.time < nextTimer then
    nextTimer = t.time
  end
  timers[t.name] = t
end

local timerCounter = 0
local function schedule(secs, cb, name)
  if not name then
    name = 'auto.' .. timerCounter
    timerCounter = timerCounter + 1
  end
  local t = {
    time = love.timer.getTime() + secs,
    cb = cb,
    freq = 1,
    name = name
  }
  addTimer(t)
end

local function every(secs, cb, name)
  assert(name)
  local t = {
    time = love.timer.getTime(), -- start an iteration now
    cb = cb,
    step = secs,
    freq = -1,
    name = name
  }
  addTimer(t)
end

local function cancel(name)
  timers[name] = nil
end

return {
  update = update,
  schedule = schedule,
  every = every,
  cancel = cancel
}
