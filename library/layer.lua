Layer = {}
Layer.__index = Layer

function Layer:new(args)
  args = args or {}
  local self = setmetatable({}, Layer)

  -- set defaults.
  self.width = args.width or win.width
  self.height = args.height or win.height
  self.x = self.x or 0
  self.y = self.y or 0
  self.r = self.r or 0
  self.sx = win.width / self.width
  self.sy = win.height / self.height
  self.drawable = false

  -- set up the canvas. we almost always want linear interpolation.
  self.canvas = love.graphics.newCanvas(self.width, self.height)
  self.canvas:setFilter("nearest", "nearest")

  return self
end

-- transform a coordinate system to this layer
-- TODO: account for self.r
function Layer:coordinates(x, y)
  return (x - self.x)*self.sx, (y - self.y)*self.sy
end

function Layer:midpoint()
  return self.width/2, self.height/2
end

function Layer:activate()
  self.drawable = true
end

function Layer:deactivate()
  self.drawable = false
end

function Layer:clear()
  if self.drawable then
    self.canvas:clear(0, 0, 0, 0)
  end
end

function Layer:render()
  if self.drawable then
    love.graphics.draw(self.canvas, self.x, self.y, self.r, self.sx, self.sy)
  end
end

-- Given a canvas and a function that does graphical operations, make
-- sure the function operates only within the given canvas.
function Layer:draw(fn, args)
  if self.drawable then
    local closure = function()
      fn(unpack(args or {}))
    end
    love.graphics.push()
    self.canvas:renderTo(closure)
    love.graphics.pop()
    -- reset all graphic attributes as to avoid side-effects
    love.graphics.reset()
  end
end

-- TODO this only applies to the last layer to be drawn.
function Layer:background(r, g, b, a)
  if self.drawable then
    love.graphics.setBackgroundColor(r or 0, g or 0, b or 0, a or 0)
  end
end

return Layer
