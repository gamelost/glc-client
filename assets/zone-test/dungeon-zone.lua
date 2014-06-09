function init()
  print("initializing dungeon-zone")
  -- -- TODO: should be self.assets[...]
  --tileset = require("assets/zone-test/Dungeon_sans_npcs")
  glc_tileset = require("library/tileset")
  tileset = require("assets/zone-test/farmer-map")
  inspect = require("library/inspect")
  state.tileset = glc_tileset.load_tiles(tileset)
end

function update()
  local data = state.data or {}
  glc_tileset.draw_tiles(state.tileset, data.id)
end

function data(d)
  state.data = d
end
