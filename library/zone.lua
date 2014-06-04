-- interface for zones.

Zone = {}

function Zone:new(name)
  setmetatable({}, self)
  self.__index = self
  self.name = name
  return self
end

function stub(...)
end

Zone.init = stub
Zone.update = stub
Zone.key_pressed = stub
Zone.key_released = stub
Zone.mouse_pressed = stub
Zone.mouse_released = stub
Zone.assets = {}
Zone.code = {}

return Zone
