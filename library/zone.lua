-- interface for zones.

Zone = {}

function stub(...)
end

Zone.init = stub
Zone.data = stub
Zone.update = stub
Zone.key_pressed = stub
Zone.key_released = stub
Zone.mouse_pressed = stub
Zone.mouse_released = stub

function load_wad(wad)
  local code = {}
  local assets = {}
  for line in love.filesystem.lines(wad) do
    if line ~= "\n" and string.find(line, "file://") == 1 then
      local path = string.gsub(line, "file://", "")
      local ext = string.match(path, ".([^.]+)$")
      -- we need to distinguish between other file types and also add
      -- error checking here
      if ext == "lua" then
        local env = setmetatable({}, {__index=_G})
        local mod = assert(loadfile(path))
        assert(pcall(setfenv(mod, env)))
        table.insert(code, env)
      else
        local image = love.graphics.newImage(path)
        table.insert(assets, image)
      end
    end
  end
  return assets, code
end

function Zone.new(wad)
  local self = setmetatable({}, Zone)
  self.__index = self
  self.state = {}
  self.name = wad
  self.assets, self.code = load_wad(wad)

  -- set up overrides
  for _, mod in pairs(self.code) do
    if type(mod) == "table" and mod.init then
      self.init = mod.init
    end
    if type(mod) == "table" and mod.data then
      self.data = mod.data
    end
    if type(mod) == "table" and mod.update then
      self.update = mod.update
    end
  end
  return self
end

return Zone
