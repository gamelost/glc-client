state = {}

function init()
  print("initializing desert-zone")
  -- TODO: should be self.assets[...]
  tileset = require("assets/zone-test2/desert-caverns")
  loader = require("library/tileset")
  loader.init(tileset)
end

function update()
  loader.draw_tiles(state.id)
end

function data(d)
  state = d
end
