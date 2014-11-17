
-- was: from bullet.
--checkHitOnOtherPlayer(self)
--
-- local function checkHitOnOtherPlayer(bullet, playerCoords)
--   if not bullet.hitList[myPlayer.name] and isPlayerHitByBullet(playerCoords, bullet) then
--     bullet.hitList[myPlayer.name] = true
--     myPlayer.hitPoint = myPlayer.hitPoint - bullet.damage

--     -- TODO: Need to have players send currZoneId and currZone in their states.
--     local currZoneId, currZone = getZoneOffset(playerCoords.x, playerCoords.y)
--     if hasCollision(zones[currZoneId], bullet.X, bullet.Y) then
--       bullet.remove = true
--     end

--     if myPlayer.hitPoint <= 0 then
--       local randomVerb = killVerbs[math.random(1, #killVerbs)]
--       local killString = (myPlayer.name .. " was " .. randomVerb .. " by " .. bullet.name)
--       --print(killString)
--       -- TODO: Need a way to send a system event instead.
--       glcd.send("chat", {Sender=glcd.name, Message=killString})
--       -- Teleport to a random location after player dies.
--       px, py = randomZoneLocation()
--       updateMyState({X = px, Y = py})
--       myPlayer.hitPoint = settings.player.default_hitpoint
--     else
--       print(myPlayer.name .. " was hit by " .. bullet.name)
--     end
--   end
-- end
-- if hasCollision(zones[currZoneId], bullet.X, bullet.Y) then
--   bullet.remove = true
-- end

function randomZoneLocation()

  -- up to 10 attempts.
  local successful = false
  local this_zone = zones[3]
  local x = 0
  local y = 0

  for i = 1, 100 do
    x = math.random(1, settings.zone_width * settings.tile_width)
    y = math.random(1, settings.zone_width * settings.tile_width)

    -- test for collisions
    successful = not (hasCollision(this_zone, x, y) or
                        hasCollision(this_zone, x - 8, y) or
                        hasCollision(this_zone, x + 8, y) or
                        hasCollision(this_zone, x, y - 8) or
                        hasCollision(this_zone, x, y + 8))
    if successful then
      break
    end
  end

  if not successful then
    x = 32
    y = 32
  end

  return x, y
end

-- Get current zone.
--  wx - number: World x-coordinate.
--  wy - number: World y-coordinate.
--  return - zone offset number and the selected zone object itself.
function getZoneOffset(wx, wy)
  local zIndex = nil
  local mZone = nil
  local xOffset = 0

  local zoneWidth = settings.zone_width * settings.tile_width
  local zoneHeight = settings.zone_height * settings.tile_height

-- Assume 1-D horizontal zones for now.
--  for _, zone in pairs(zones) do
  for idx = 1, #zones do
    if zones[idx].state.data then
      local zId = zones[idx].state.data.id
      local wxMin = zId *  zoneWidth
      local wyMin = zId
      local wxMax = wxMin + zoneWidth
      local wyMax = wyMin + zoneHeight
      --print(string.format("getZoneOffset: idx=%d, wxy=(%d,%d), zId=%d, zoneDimen=(%d,%d), wxyMin=(%d,%d), wxyMax=(%d,%d)", idx, wx, wy, zId, zoneWidth, zoneHeight, wxMin, wyMin, wxMax, wyMax))

      if wx >= wxMin and wx <= wxMax and wy >= wyMin and wy <= wyMax then
        -- print("getZoneOffset: Found! zId=", zId)
        zIndex = idx;
        mZone = zones[idx]
        break
      else
        --print("getZoneOffset: Not found! zId=", zId)
        xOffset = xOffset + zoneWidth
      end
      idx = idx + 1
    end
  end
  return zIndex, mZone
end

function isPlayerHitByBullet(player, bullet)
  -- print("Player '" .. player.name .. "': {X=" .. player.x .. ",Y=" .. player.y .. "}")
  -- print("Bullet from '" .. bullet.name .. "': {X=" .. bullet.X .. ",Y=" .. bullet.Y .. "}")

  if (bullet.X >= (player.x - player.radius_w) and
      bullet.X <= (player.x + player.radius_w) and
      bullet.Y >= (player.y - player.radius_h) and
      bullet.Y <= (player.y + player.radius_h)) then
    return true
  end
  return false
end

function didPlayerBumpedIntoOtherPlayer(player, otherPlayer)
  if math.abs((player.x - player.radius_w) - (otherPlayer.X - otherPlayer.radius_w)) * 2 < (player.width + otherPlayer.width) and
      math.abs((player.y - player.radius_h) - (otherPlayer.Y - otherPlayer.radius_h)) * 2 < (player.height + otherPlayer.height) then
    return true
  end
  return false
end

function hasCollision(mZone, x, y)
  local isCollidable = false

  if mZone then
    --print("hasCollision: ", inspect(mZone.state.tileset.metadatas))
    local metadatas = mZone.state.tiles.metadata

    -- select the metadata layer that corresponds with this layer. but
    -- by default (and for backwards compatibility) we choose the
    -- first metadata layer.
    local current = mZone.state.tiles.current_layer
    local metalayer = metadatas.layers[1]
    if current and current.name then
      for _, ml in ipairs(metadatas.layers) do
        if ml.properties.name == current.name then
          metalayer = ml
          break
        end
      end
    end

    -- pre-initialize metalayer triggers: these prevent repeatedly
    -- performing metadata triggers on the same tile. each meta tile
    -- type has a cooldown period before it can be triggered again.
    -- The default is 5s.
    if metalayer and not metalayer.triggers then
      metalayer.triggers = {}
    end

    -- use 'settings' global variable for now.
    local gridx = math.ceil(x / settings.tile_width)
    local gridy = math.ceil(y / settings.tile_height)

    local metaIndex = (gridy - 1) * settings.zone_width + gridx
    local metadata = nil

    if metalayer then
      metadata = metadatas[metalayer.data[metaIndex]]
      --print("metadata:", inspect(metadata))
    end

    if metadata then
      isCollidable = metadata.properties.collidable
      -- check for other kinds of metadata.
      if not isCollidable and metadata.properties then
        -- make sure we aren't hitting this trigger more than once/cooldown period.
        local now = love.timer.getTime()
        local last_hit = metalayer.triggers[metaIndex] and metalayer.triggers[metaIndex].last_hit
        local cooldown = metadata.properties.cooldown or 5
        local past_time = now > (last_hit or now) + cooldown
        if not last_hit or past_time then
          glcd.send("broadcast", {request="metadata_hit",
                                  x=gridx,
                                  y=gridy,
                                  properties=metadata.properties,
                                  zoneid=mZone.state.data.id})
          metalayer.triggers[metaIndex] = {}
          metalayer.triggers[metaIndex].last_hit = now
        end
      end
    end

    -- print(string.format("got %d, %d and ended up with [%d](%d,%d): %s", x, y, metaIndex, gridx, gridy, coll))
  end

  return isCollidable
end
