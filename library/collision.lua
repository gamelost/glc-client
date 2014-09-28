
function randomZoneLocation()

  -- up to 10 attempts.
  local successful = false
  local this_zone = zones[3]
  local x = 0
  local y = 0

  --for i = 1, 10000000 do
  while true do
    x = - math.random(1, settings.zone_width * settings.tile_width)
    y = - math.random(1, settings.zone_width * settings.tile_width)

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
    x = -32
    y = -32
  end

  return x, y
end

-- Get current zone.
--  wx - number: World x-coordinate.
--  wy - number: World y-coordinate.
--  return - zone offset number, its transformed coordinates, and the selected zone object itself.
function getZoneOffset(wx, wy)
  local zpoint = nil
  local zIndex = nil
  local mZone = nil
  local xOffset = 0

-- Assume 1-D horizontal zones for now.
--  for _, zone in pairs(zones) do
  for idx = 1, #zones do
    if zones[idx].state.data then
      local zId = zones[idx].state.data.id
      -- local zoneWidth = zone.state.tileset.width * zone.state.tileset.tilewidth
      local zoneWidth = settings.zone_width * settings.tile_width -- For now until the server passes the sorted zones table from left to right
      local zoneHeight = settings.zone_height * settings.tile_height -- For now until the server passes the sorted zones table from left to right
      local wxMin = -1 * zId *  zoneWidth
      local wyMin = -1 * zId *  zoneHeight
      local wxMax = wxMin - zoneWidth
      local wyMax = wyMin - zoneHeight
      --print(string.format("getZoneOffset: idx=%d, wxy=(%d,%d), zId=%d, zoneDimen=(%d,%d), wxyMin=(%d,%d), wxyMax=(%d,%d)", idx, wx, wy, zId, zoneWidth, zoneHeight, wxMin, wyMin, wxMax, wyMax))

      if wx <= wxMin and wx >= wxMax and wy <= wyMin and wy >= wyMax then
        --print("getZoneOffset: Found! zId=", zId)
        zpoint = {x = zId * wx, y = wy}
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
  return zIndex, zpoint, mZone
end

function hasCollision(mZone, x, y)
  local isCollidable = false

  if mZone then
    --print("hasCollision: ", inspect(mZone.state.tileset.metadatas))
    local metadatas = mZone.state.tiles.metadatas
    local metalayer = metadatas.layers[1]
    local tileId = 0

    x = math.abs(x)
    y = math.abs(y)

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
    end
    -- print(string.format("got %d, %d and ended up with [%d](%d,%d): %s", x, y, metaIndex, gridx, gridy, coll))
  end

  return isCollidable
end
