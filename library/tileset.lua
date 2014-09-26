local function populate_metadata(metas, tileset)
  for k, tile in ipairs(tileset.tiles) do
    local i = tileset.firstgid + tile.id
    metas[i] = {}
    metas[i].properties = tile.properties
  end
end

local function load_metadatas(mTilesets)
  mTilesets.metadatas = {}

  for k, v in ipairs(mTilesets.tilesets) do
    local counter = 1

    if v.properties.metadata then
      populate_metadata(mTilesets.metadatas, v)
    end
  end
end

local function load_metalayers(mTilesets)
  -- Save metadata layer in the metadatas table
  mTilesets.metadatas.layers = {}
  for _, layer in ipairs(mTilesets.layers) do
    if layer.properties.metadata then
      table.insert(mTilesets.metadatas.layers, layer)
    end
  end
end

local function load_tiles(tilesets)
  tilesets.all_tiles = {}

  load_metadatas(tilesets)
  load_metalayers(tilesets)

  for k, v in ipairs(tilesets.tilesets) do
    --io.write("Loading tileset: " .. v.image)
    v.tileset = love.graphics.newImage(v.image)
    v.num_tile_rows = v.imageheight / v.tileheight
    v.num_tile_cols = v.imagewidth / v.tilewidth
    v.num_tiles = v.num_tile_rows * v.num_tile_cols
    v.lastgid = v.firstgid
    v.quads = {}
    local counter = 1

    for ty = 0, (v.num_tile_rows - 1) do
      for tx = 0, (v.num_tile_cols - 1) do
        v.quads[v.firstgid + counter - 1] = love.graphics.newQuad(tx * v.tilewidth, ty * v.tileheight,
                                                                  v.tilewidth, v.tileheight, v.imagewidth, v.imageheight)
        tilesets.all_tiles[v.firstgid + counter - 1] = v -- TODO: Need to improve on this.
        v.lastgid = v.firstgid + counter - 1
        tx = tx + v.tilewidth
        counter = counter + 1
      end
      ty = ty + v.tileheight
    end
    --print(" ... [tile #" .. v.firstgid .. " - " .. (v.lastgid) .. "]  DONE!")
  end
  print("Done loading tilesets.")
  return tilesets
end

local function draw_tiles(tilesets, id)

  if id == nil then
    -- zone is not yet active
    return
  end

  local mx, my = layers.background:midpoint()
  local zone_offset = (id * settings.zone_width * settings.tile_width)
  love.graphics.translate(mx, my)
  love.graphics.translate(zone_offset, 0)

  for index, layer in ipairs(tilesets.layers) do -- paint tiles layer by layer
    --print("Painting "..layer.name.." layer")
    if not layer.visible then
      local showLayer = settings.show_metadata_layer or false
      local isMetadata = layer.properties.metadata or false

      if not showLayer then
        --print("'" .. layer.name .. "' layer is not visible, painting canceled.")
        break
      end
    end

    local posx = 0
    local posy = 0

    -- "eat" the rest of the layer data if needed
    local consume = 0
    local width = math.min(layer.width, settings.zone_width)
    local left = math.max(layer.width - settings.zone_width, 0)

    love.graphics.push()
    love.graphics.translate(layer.x, layer.y)

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
        local tile_data = tilesets.all_tiles[v]
        if tile_data ~= nil then
          local x = posx * tile_data.tilewidth
          local y = posy * tile_data.tileheight
          love.graphics.draw(tile_data.tileset, tile_data.quads[v], math.floor(x + px), math.floor(y + py))
        end
        posx = posx + 1
      end

    end
    love.graphics.pop()

  end
end

glc_tileset = {}
glc_tileset.load_tiles = load_tiles
glc_tileset.load_metadata = load_metadata
glc_tileset.draw_tiles = draw_tiles

return glc_tileset
