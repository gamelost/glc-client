require("library/tileset")
state = {}

function init()
  print("initializing desert-zone")
  -- TODO: should be self.assets[...]
  tileset = require("assets/zone-test2/desert-caverns")
  state.tileset = glc_tileset.load_tiles(tileset)
end

function update()
  glc_tileset.draw_tiles(state.tileset, state.data.id)
end

function data(d)
  state.data = d
end
