-- inspired by xscreensaver hacks:
-- from https://github.com/danfuzz/xscreensaver/blob/master/hacks/halo.c

local color = require 'graphics/color'

Circle = {}
Circle.mt = {} -- metatable
Circle.mt.__index = Circle

local palette = {
  {24,221,0},
  {225,200,41},
  {47,181,243},
  {252,130,195},
  {30,2,63}
}

local circles = {}
local global_count = 25
local global_inc = 0.5

function Circle.new(x, y, r)
  local self = setmetatable({}, Circle.mt)
  self.x = x or 0
  self.y = y or 0
  self.r = r or 0
  self.increment = 0
  self.rgb = palette[love.math.random(1,#palette)]
  return self
end

function circle_load()
  width, height = love.graphics.getDimensions()

  for i = 1, global_count do
    local x = love.math.random(10, width - 10)
    local y = love.math.random(10, height - 10)
    local r = love.math.random(1, 10)
    local v = Circle.new(x, y, r)
    v.increment = v.increment + global_inc
    table.insert(circles, v)
  end

  -- set up the loading font
  loading_font = love.graphics.newFont("assets/Krungthep.ttf", 32)
end

function circle_update()
end

function circle_print(str, x, y)
  love.graphics.setColor(0, 0, 255)
  love.graphics.print(str, x, y)
  love.graphics.setColor(255, 255, 0)
  love.graphics.print(str, x - 2, y - 2)
end

function circle_draw()
  local previous_font = love.graphics.getFont()
  love.graphics.setBackgroundColor(0, 0, 0, 0)

  for i = 1, #circles do
    local c = circles[i]
    local x = c.x - c.r
    local y = c.y - c.r
    local h, s, l = color.rgb_to_hsl(c.rgb[1], c.rgb[2], c.rgb[3])
    local radius = c.r * 4
    for _ = 1, 5 do
      l = l * 0.95
      radius = radius * 0.85
      local r, g, b = color.hsl_to_rgb(h, s, l)
      love.graphics.setColor(r, g, b)
      love.graphics.circle('fill', x, y, radius, 64)
    end
    c.r = c.r + c.increment
  end

  -- randomly add up to global_count/2
  for i = 1, love.math.random(1, global_count/2) do
    local x = love.math.random(10, width - 10)
    local y = love.math.random(10, height - 10)
    local r = love.math.random(1, 10)
    local v = Circle.new(x, y, r)
    v.increment = v.increment + global_inc
    table.insert(circles, v)
  end

  love.graphics.setFont(loading_font)
  circle_print("here's to 2015!", 50, (height / 2) - 60)
  circle_print("game lost crash", 50, height / 2)
  circle_print("v. 0.7", 50, (height / 2) + 60)

  love.graphics.setFont(previous_font)
end

return {
  load = circle_load,
  update = circle_update,
  draw = circle_draw
}
