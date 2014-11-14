function init()
  -- TODO: should be self.assets[...]
  tileset = require("assets/shooter/shooter")
  glc_tileset = require("graphics/tileset")
  inspect = require("util/inspect")
  state.tiles = glc_tileset.load_batched_tiles(tileset)
  state.data = {}
  state.toggle_next_layer = glc_tileset.toggle_next_layer -- TODO hack
end

function update()
  local data = state.data or {}
  glc_tileset.draw_tiles(state.tiles, data.id)
end

function data(d)
  state.data = d
end
