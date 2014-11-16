aabb = require('geometry/aabb')
vector = require('geometry/vector')

-- generic sprite class.
Sprite = {}
Sprite.__index = Sprite

-- each sprite must implement:
--   updateState = function(self, data)
--   update = function(self, playerCoords)
--   draw = function(self)

function Sprite:update(i, coords)
  assert(false, "base sprite `update' function called.")
end

function Sprite:draw()
  assert(false, "base sprite `draw' function called.")
end

-- each sprite has the following attributes:
--   world coordinates (x, y)
--   width, height
--   zone id
--   direction (can be nil)
--   axis-aligned bounding box (automatically calculated)

function Sprite:updateState(data)
  self.x = data.x or self.x
  self.y = data.y or self.y
  self.width = data.width or self.width
  self.height = data.height or self.height
  self.direction = data.direction or self.direction
  self.zoneid = data.zoneid or self.zoneid
end

function Sprite.new(args)
  self = setmetatable({}, Sprite)

  -- required
  self.width = args.width
  self.height = args.height
  assert(self.width ~= nil)
  assert(self.height ~= nil)
  assert(self.width > 0)
  assert(self.height > 0)
  self.zoneid = args.zoneid
  assert(self.zoneid ~= nil)

  -- optional
  self.x = args.x or 0
  self.y = args.y or 0
  self.direction = args.direction -- can be nil
  self.aabb = aabb.new(vector.new(self.x, self.y),
                       vector.new(self.x + self.width, self.y + self.height))

  return self
end

return Sprite
