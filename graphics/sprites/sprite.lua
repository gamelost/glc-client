local aabb = require('geometry/aabb')
local vector = require('geometry/vector')
local _ = require('util/underscore')

-- generic sprite class.
local prototype = {
  -- each sprite must implement:
  --   updateState = function(self, data)
  --   update = function(self)
  --   draw = function(self)
  updateState = function(self, data)
    -- each sprite has the following attributes:
    --   world coordinates (x, y)
    --   width, height
    --   zone id
    --   direction (can be nil)
    --   axis-aligned bounding box (automatically calculated)
    self.x = data.x or self.x
    self.y = data.y or self.y
    self.width = data.width or self.width
    self.height = data.height or self.height
    self.direction = data.direction or self.direction
    self.zoneid = data.zoneid or self.zoneid
  end,
  update = function (self)
  end,
  draw = function (self)
  end,
}

local new = function(args)
  local self = setmetatable(args, {__index = prototype})

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

  -- aabb is set in the player coordinate system
  self.aabb = aabb.new(vector.new(),
                       vector.new(self.width, self.height))

  return self
end

local inherit

inherit = function(args)
  extension = _.extend(args, prototype)
  return {
    new = new,
    __base = prototype,
    __index = extension,
    inherit = inherit,
    fn = extension,
  }
end

return {
  inherit = inherit,
  fn = prototype,
  new = new,
}
