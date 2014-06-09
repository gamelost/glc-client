local function populate_metadata(metas, tileset)
  for k, tile in ipairs(tileset.tiles) do
    local i = tileset.firstgid + tile.id
    metas.properties = {}
    metas.properties[i] = tile.properties
  end
end

local function extract_metadata_layers(metas, tilesets)
end

local function load_metadatas(tilesets)
  tilesets.metadatas = {}

  for k, v in ipairs(tilesets.tilesets) do
    local counter = 1

    if v.properties.metadata then
      populate_metadata(tilesets.metadatas, v)
    end
  end
end

local function load_tiles(tilesets)
  tilesets.all_tiles = {}

  for k, v in ipairs(tilesets.tilesets) do
    io.write("Loading tileset: " .. v.image)
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
    print(" ... [tile #" .. v.firstgid .. " - " .. (v.lastgid) .. "]  DONE!")
  end
  print("Done loading tilesets.")
  return tilesets
end

local function draw_tiles(tilesets, id)

  if id == nil then
    -- zone is not yet active
    return
  end

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

    local zone_offset = (id * settings.zone_width * settings.tile_width)
    local opacity = layer.opacity
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
        local tile_data = tilesets.all_tiles[v]
        if tile_data ~= nil then
          local tilewidth = tile_data.tilewidth
          local tileheight = tile_data.tileheight
          local x = layer.x + (posx * tile_data.tilewidth)
          local y = layer.y + (posy * tile_data.tileheight)
          love.graphics.draw(tile_data.tileset, tile_data.quads[v], zone_offset + math.floor(x + px), math.floor(y + py))
        end
        posx = posx + 1
      end

    end
  end
end

glc_tileset = {}
glc_tileset.load_tiles = load_tiles
glc_tileset.load_metadata = load_metadata
glc_tileset.draw_tiles = draw_tiles

return glc_tileset
