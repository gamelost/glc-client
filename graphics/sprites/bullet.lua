local killVerbs = {"killed", "murdered", "smashed", "exploded", "dispatched", "neutralized", "X'd"}

-- sets the location of the bullet
local function bulletLocation(direction, X, Y)
  local shootOffset = -4
  direction = direction or "right"
  local getOffset = {
      left  = { X = X + shootOffset , Y = Y }
    , up    = { X = X               , Y = Y + shootOffset }
    , down  = { X = X               , Y = Y - shootOffset }
    , right = { X = X - shootOffset , Y = Y }
  }

  return getOffset[direction]
end

local function drawBullet(x, y)
  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.setColor(0, 0, 0, 255)
  love.graphics.circle("fill", 0, 0, 2, 10)
  love.graphics.pop()
end

-- update bullet X to move to the direction based on time
-- uses pSpeed to avoid the bullet being slower than player speed
local function updateBulletState(bullet, i)
  local time, direction, startTime, delta, X, Y, bullet_speed, currZoneId
  time       = love.timer.getTime()
  direction  = bullet.direction or "right"
  startTime  = bullet.startTime
  delta      = time - startTime
  X          = bullet.X
  Y          = bullet.Y
  bullet_speed = bullet.speed
  currZoneId = bullet.currZoneId

  local setBulletNewLocation = {
      right = function(bullet)
        bullet.X = X + delta * bullet_speed
      end
    , left = function(bullet)
        bullet.X = X - delta * bullet_speed
      end
    , down = function(bullet)
        bullet.Y = Y + delta * bullet_speed
      end
    , up = function(bullet)
        bullet.Y = Y - delta * bullet_speed
      end
  }

  -- if bullet hasn't hit an obstacle after two seconds, remove bullet.
  if time > bullet.startTime + 2 then
    bullet.remove = true
  else
    setBulletNewLocation[direction](bullet)
  end

  if hasCollision(zones[currZoneId], bullet.X, bullet.Y) then
    bullet.remove = true
  end
end

local function checkHitOnOtherPlayer(bullet, i, playerCoords)
  if not bullet.hitList[myPlayer.name] and isPlayerHitByBullet(playerCoords, bullet) then
    bullet.hitList[myPlayer.name] = true
    myPlayer.hitPoint = myPlayer.hitPoint - bullet.damage

    -- TODO: Need to have players send currZoneId and currZone in their states.
    local currZoneId, currZone = getZoneOffset(playerCoords.x, playerCoords.y)
    if hasCollision(zones[currZoneId], bullet.X, bullet.Y) then
      bullet.remove = true
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

-- fireBullet is triggered by pressing the spacebar and returns a message
-- containing all the important bulletData.
local function fireBullet(playerData)
  local location = bulletLocation(playerData.state.direction,
                                  playerData.state.X,
                                  playerData.state.Y)
  -- calculate currZoneId only once and pass it into playerData
  -- we don't use the second variable
  local currZoneId, currZone = getZoneOffset(location.X, location.Y)
  return { spriteType = "Bullet"
  , name = playerData.player.name
  , direction = playerData.state.direction
  , X = location.X
  , Y = location.Y
  , hitList = {[""] = true} -- json.lua is fubar! To hell with it. It'll crash if I leave an empty table {} here.
  , damage = 1
  , startTime = love.timer.getTime()
  , currZoneId = currZoneId
  , speed = playerData.speed
  }
end

local metaindex = {
  update = function(self, i, playerCoords)
    updateBulletState(self, i)
    checkHitOnOtherPlayer(self, i, playerCoords)
  end,
  draw = function(self)
    layers.background:draw(drawBullet, {self.X, self.Y})
  end,
}

local Bullet = { data = {}
  , spriteType="Bullet"
  , metatable = { __index = metaindex  }
  , fireBullet = fireBullet
}

function Bullet.new(obj)
  setmetatable(obj, Bullet.metatable)
  return obj
end

return Bullet
