local function load_tilesets(tilesets)
  tilesets.all_tiles = {}
  for k, v in ipairs(tilesets.tilesets) do
    v.tileset = love.graphics.newImage(v.image)
    v.num_tile_rows = v.imageheight / v.tileheight
    v.num_tile_cols = v.imagewidth / v.tilewidth
    v.num_tiles = v.num_tile_rows * v.num_tile_cols
    v.lastgid = v.firstgid
    local counter = 1

    for ty = 0, (v.num_tile_rows - 1) do
      for tx = 0, (v.num_tile_cols - 1) do
        v.tiles[v.firstgid + counter - 1] = love.graphics.newQuad(tx * v.tilewidth, ty * v.tileheight, v.tilewidth, v.tileheight, v.imagewidth, v.imageheight)
        tilesets.all_tiles[v.firstgid + counter - 1] = v -- TODO: Need to improve on this.
        v.lastgid = v.firstgid + counter - 1
        tx = tx + v.tilewidth
        counter = counter + 1
      end
      ty = ty + v.tileheight
    end
    --print(v.image .. ": Loaded tiles #" .. v.firstgid .. " - " .. (v.lastgid))
  end
  --print("Done loading tiles")
end

local function init(data)
  tileset_data = data
  load_tilesets(data)
end

local function draw_tiles(id)

  if id == nil then
    -- zone is not yet active
    return
  end

  for index, layer in ipairs(tileset_data.layers) do -- paint tiles layer by layer
    --print("Painting "..layer.name.." layer")
    if not layer.visible then
      --print("Layer is not visible, painting canceled.")
      break
    end

    local x = layer.x
    local y = layer.y
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
        local tile_data = tileset_data.all_tiles[v]
        if tile_data ~= nil then
          local tilewidth = tile_data.tilewidth
          local tileheight = tile_data.tileheight
          local x = (posx * tile_data.tilewidth)
          local y = (posy * tile_data.tileheight)
          love.graphics.draw(tile_data.tileset, tile_data.tiles[v], math.floor(x + px), math.floor(y + py))
        end
        posx = posx + 1
      end

    end
  end
end

glc_tileset = {}
glc_tileset.init = init
glc_tileset.draw_tiles = draw_tiles
return glc_tileset
