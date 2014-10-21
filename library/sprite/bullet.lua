local function bulletLocation(direction, X, Y)
  local shootOffset = -4
  if direction == "left" then
    return { X = X + shootOffset, Y = Y }
  elseif direction == "up" then
    return { X = X, Y = Y + shootOffset }
  elseif direction == "down" then
    return { X = X, Y = Y - shootOffset }
  else -- direction will always fire in the right if unset.
    return { X = X - shootOffset, Y = Y }
  end
end

local function drawBullet(x, y)
  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.setColor(0, 0, 0, 255)
  love.graphics.circle("fill", 0, 0, 2, 10)
  love.graphics.pop()
end


Bullet = {
  data = {},
  spriteType="Bullet",
  metatable = {
    __index = {
      update = function(self)
        print("Updating")
      end,
      draw = function(self)
        layers.background:draw(drawBullet, {self.X, self.Y})
      end,
    }
  }
}
function Bullet.new(obj)
  setmetatable(obj, Bullet.metatable)
  return obj
end
function Bullet.fireBullet(playerData)
  -- draw a layer containing the bullet and move it?
  local location = bulletLocation(playerData.state.direction, playerData.state.X, playerData.state.Y)
  -- print(myPlayer.name .. " fired a bullet to the " .. myState.direction .. ". " ..
  --     "Initial firing locaiton = (" .. location.X .. "," .. location.Y .. "), " ..
  --     "player's location: (" .. myState.X .. "," .. myState.Y .. ")")
  return {
    spriteType = "Bullet",
    name = playerData.player.name,
    direction = playerData.state.direction,
    X = location.X,
    Y = location.Y,
    hitList = {[""] = true}, -- json.lua is fubar! To hell with it. It'll crash if I leave an empty table {} here.
    damage = 1,
    startTime = love.timer.getTime(),
  }
end
local function updateBulletState()
  local time, direction, startTime, delta, X, Y
  for i, bullet in pairs(Gamelost.spriteList) do
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
      --print("bullet" .. i .. " from " .. bullet.name .. " didn't hit anything")
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
  for _, bullet in ipairs(Gamelost.spriteList or {}) do
    -- print(bullet.name .. "'s bullet is at " .. bullet.X .. "," .. bullet.Y)
    if not bullet.hitList[myPlayer.name] and isPlayerHitByBullet(playerCoords, bullet) then
      bullet.hitList[myPlayer.name] = true
      myPlayer.hitPoint = myPlayer.hitPoint - bullet.damage

      local currZoneId, currZone = getZoneOffset(playerCoords.x, playerCoords.y)
      if hasCollision(zones[currZoneId], bullet.X, bullet.Y) then
        bulletList[i] = nil
      end

      if myPlayer.hitPoint <= 0 then
        local randomVerb = killVerbs[math.random(1, #killVerbs)]
        local killString = (myPlayer.name .. " was " .. randomVerb .. " by " .. bullet.name)
        --print(killString)
        -- TODO: Need a way to send a system event instead.
        glcd.send("chat", {Sender=glcd.name, Message=killString})
        -- Teleport to a random location after player dies.
        px, py = randomZoneLocation()
        updateMyState({X = px, Y = py})
        myPlayer.hitPoint = settings.player.default_hitpoint
      else
        print(myPlayer.name .. " was hit by " .. bullet.name)
      end
    end
  end
