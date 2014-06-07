require("library/tileset")
state = {}

function init()
  print("initializing dungeon-zone")
  -- -- TODO: should be self.assets[...]
  tileset2 = require("assets/zone-test/Dungeon_sans_npcs")
  state.tileset = glc_tileset.load_tiles(tileset2)
end

function update()
  local data = state.data or {}
  glc_tileset.draw_tiles(state.tileset, data.id)
end

function data(d)
  state.data = d
end
