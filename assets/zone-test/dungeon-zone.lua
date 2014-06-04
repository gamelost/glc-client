require "library/zone"

function init()
  -- TODO: should be self.assets[...]
  tileset = require("assets/zone-test/Dungeon_sans_npcs")
  loader = require("library/tileset")
  loader.init(tileset)
end

function update()
  loader.draw_tiles()
end

Dungeon = Zone:new("test")
