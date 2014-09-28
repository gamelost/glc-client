inspect = require("library/inspect")

function reload_layer(tilesets)
  for _, batch in ipairs(tilesets.sprite_batches) do
    batch:clear()
  end

  for index, layer in ipairs(tilesets.layers) do
    if layer.visible or layer.properties.visible == "always" then
      if not layer.properties.metadata and not settings.show_metadata_layer then
        tilesets.current_layer = layer
        load_layer(layer, tilesets.sprite_info)
      end
    end
  end
end

function toggle_next_layer(tilesets)
  local hit = 0
  local counter = 0
  for index, layer in ipairs(tilesets.layers) do
    counter = counter + 1
    if layer.name == tilesets.current_layer.name then
      layer.visible = false
      hit = counter
    end
  end
  hit = hit % #tilesets.layers
  counter = 0
  for index, layer in ipairs(tilesets.layers) do
    if not layer.properties.metadata then
      if counter == hit then
        layer.visible = true
        break
      end
    end
    counter = counter + 1
  end

  reload_layer(tilesets)
end

function load_layer(layer, sprite_info)
  local posx = 0
  local posy = 0

  -- "eat" the rest of the layer data if needed
  local consume = 0
  local width = math.min(layer.width, settings.zone_width)
  local left = math.max(layer.width - settings.zone_width, 0)

  for k, v in ipairs(layer.data) do
    if posx >= width then
      posx = 0
      posy = posy + 1
      consume = left
    end
    if posy >= settings.zone_height then
      break
    end

    if consume > 0 then
      consume = consume - 1
    else
      local tile_data = sprite_info[v]
      if tile_data ~= nil then
        local x = posx * tile_data.width
        local y = posy * tile_data.height
        tile_data.sprite:add(tile_data.quad, x, y)
      end
      posx = posx + 1
    end
  end
end

local function load_batched_tiles(tilesets)

  tilesets.sprite_info = {}
  tilesets.sprite_batches = {}
  tilesets.current_layer = nil

  -- obtain the metadata tiles and their properties.
  tilesets.metadata = {}
  for _, tileset in ipairs(tilesets.tilesets) do
    if tileset.properties.metadata then
      for _, tile in ipairs(tileset.tiles) do
        local i = tileset.firstgid + tile.id
        tilesets.metadata[i] = {}
        tilesets.metadata[i].properties = tile.properties
      end
    end
  end

  -- obtain the metadata layer(s) that tell us where the metadata tiles are.
  tilesets.metadata.layers = {}
  for _, layer in ipairs(tilesets.layers) do
    if layer.properties.metadata then
      table.insert(tilesets.metadata.layers, layer)
    end
  end

  local limit = tilesets.width * tilesets.height

  for k, v in ipairs(tilesets.tilesets) do
    if love.filesystem.isFile(v.image) then
      image = love.graphics.newImage(v.image)
    else
      print("Warning: cannot find tile file " .. v.image)
    end

    local sprite = love.graphics.newSpriteBatch(image, limit, "static")
    table.insert(tilesets.sprite_batches, sprite)

    local num_tile_rows = (v.imageheight / v.tileheight) - 1
    local num_tile_cols = (v.imagewidth / v.tilewidth) - 1
    local counter = 0
    for ty = 0, num_tile_rows do
      for tx = 0, num_tile_cols do
        quad = love.graphics.newQuad(tx * v.tilewidth,
                                     ty * v.tileheight,
                                     v.tilewidth,
                                     v.tileheight,
                                     v.imagewidth,
                                     v.imageheight)

        tilesets.sprite_info[v.firstgid + counter] = {
          width = v.tilewidth,
          height = v.tileheight,
          sprite = sprite,
          quad = quad
        }

        counter = counter + 1
        tx = tx + v.tilewidth
      end
      ty = ty + v.tileheight
    end
  end

  reload_layer(tilesets)

  return tilesets
end

local function draw_tiles(tilesets, id)

  if id == nil then
    -- zone is not yet active
    return
  end

  love.graphics.push()
  local mx, my = layers.background:midpoint()
  local zone_offset = (id * settings.zone_width * settings.tile_width)
  love.graphics.translate(mx, my)
  love.graphics.translate(zone_offset, 0)
  love.graphics.translate(math.floor(px), math.floor(py))

  for index, layer in ipairs(tilesets.layers) do
    if layer.visible or layer.properties.visible == "always" then
      for _, batch in ipairs(tilesets.sprite_batches) do
        love.graphics.draw(batch, layer.x, layer.y)
      end
    end
  end
  love.graphics.pop()
end

glc_tileset = {}
glc_tileset.load_batched_tiles = load_batched_tiles
glc_tileset.toggle_next_layer = toggle_next_layer
glc_tileset.draw_tiles = draw_tiles

return glc_tileset
