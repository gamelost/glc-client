vector = require('geometry/vector')

-- axis aligned bounding boxes.
Aabb = {}
Aabb.__index = Aabb

function Aabb.new(v1, v2)
  local self = setmetatable({}, Aabb)
  self.v1 = v1 or vector.new()
  self.v2 = v2 or vector.new()
  if getmetatable(self.v1) ~= vector.mt or
     getmetatable(self.v2) ~= vector.mt then
    error("attempt to build an axis-aligned box with non-vector values", 2)
  end
  return self
end

-- fit sprite(s)
-- intersection (a1, a2)
-- distance (a, v)

return Aabb
