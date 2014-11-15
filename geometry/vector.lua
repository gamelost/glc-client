Vector = {}
Vector.mt = {} -- metatable
Vector.mt.__index = Vector

function Vector.add(v1, v2)
  if getmetatable(v1) ~= Vector.mt or
     getmetatable(v2) ~= Vector.mt then
    error("attempt to `add' a vector with a non-vector value", 2)
  end
  return Vector.new(v1.x + v2.x, v1.y + v2.y)
end

function Vector.sub(v1, v2)
  if getmetatable(v1) ~= Vector.mt or
     getmetatable(v2) ~= Vector.mt then
    error("attempt to `sub' a vector with a non-vector value", 2)
  end
  return Vector.new(v1.x - v2.x, v1.y - v2.y)
end

function Vector.mul(x, y)
  -- two cases here.
  -- vector * float.
  if getmetatable(x) == Vector.mt and type(y) == "number" then
    return Vector.new(x.x * y, x.y * y)
  end
  -- float * vector
  if type(x) == "number" and getmetatable(y) == Vector.mt then
    return Vector.new(x * y.x, x * y.y)
  end
  error("attempt to `mul' a vector with incompatible values", 2)
end

function Vector.unm(v1)
  if getmetatable(v1) ~= Vector.mt then
    error("attempt to `negate' a vector with a non-vector value", 2)
  end
  return Vector.new(- v1.x, - v1.y)
end

function Vector:distance(v1)
  if getmetatable(v1) ~= Vector.mt then
    error("attempt to get distance with non-vectors", 2)
  end
  local first = self.x - v1.x
  local second = self.y - v1.y
  return math.sqrt(first * first + second * second)
end

-- used for comparison purposes only. slightly faster.
function Vector:nonsqrt_distance(v1)
  if getmetatable(v1) ~= Vector.mt then
    error("attempt to get distance with non-vectors", 2)
  end
  local first = self.x - v1.x
  local second = self.y - v1.y
  return first * first + second * second
end

function Vector:dot(v1)
  if getmetatable(v1) ~= Vector.mt then
    error("attempt to `dot' a vector with a non-vector value", 2)
  end
  return self.x * v1.x + self.y * v1.y
end

-- built-ins.
Vector.mt.__add = Vector.add
Vector.mt.__sub = Vector.sub
Vector.mt.__mul = Vector.mul
Vector.mt.__unm = Vector.unm

function Vector.new(x, y)
  local self = setmetatable({}, Vector.mt)
  self.x = x or 0.0
  self.y = y or 0.0
  return self
end

return Vector
