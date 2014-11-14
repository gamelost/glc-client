local histogram = {}
local histogram_total = 0.0
local max_iterations = 10

function mandelbrot_load()
  width, height = love.graphics.getDimensions()

  -- prep the histogram
  for i=0,max_iterations,1 do
    histogram[i] = 0
  end

  -- first pass
  for i=0,width,1 do
    for j=0,height,1 do
      local x0 = ((i / width) * 3.5) - 2.5 -- scale to -2.5, 1
      local y0 = ((j / height) * 2.0) - 1.0 -- scale to -1, 1
      local x = 0.0
      local y = 0.0
      local iteration = 0
      while x*x + y*y < 4 and iteration < max_iterations do
        local xtemp = x*x - y*y + x0
        y = 2*x*y + y0
        x = xtemp
        iteration = iteration + 1
      end

      value = histogram[iteration] + 1
      histogram[iteration] = value
    end
  end

  -- histogram total
  for i=0,max_iterations,1 do
    histogram_total = histogram_total + histogram[i]
  end

  -- set up the loading font
  loading_font = love.graphics.newFont("assets/Krungthep.ttf", 32)
end

function mandelbrot_update()
end

function mandelbrot_print(str, x, y)
  love.graphics.setColor(0, 0, 255)
  love.graphics.print(str, x, y)
  love.graphics.setColor(255, 255, 128)
  love.graphics.print(str, x - 2, y - 2)
end

function mandelbrot_draw()
  local previous_font = love.graphics.getFont()
  love.graphics.setBackgroundColor(0, 0, 0, 0)

  -- draw the mandelbrot fractal (second pass)
  for i=0,width,1 do
    for j=0,height,1 do
      local x0 = ((i / width) * 3.5) - 2.5 -- scale to -2.5, 1
      local y0 = ((j / height) * 2.0) - 1.0 -- scale to -1, 1
      local x = 0.0
      local y = 0.0
      local iteration = 0
      local max_iteration = 10
      while x*x + y*y < 4 and iteration < max_iteration do
        local xtemp = x*x - y*y + x0
        y = 2*x*y + y0
        x = xtemp
        iteration = iteration + 1
      end

      local hue = 0.0
      for i=0,iteration,1 do
        hue = hue + (histogram[i] / histogram_total)
      end

      hue = hue * 255.0
      love.graphics.setColor(hue, hue, 128)
      love.graphics.point(i + 0.5, j + 0.5)
    end
  end

  love.graphics.setFont(loading_font)
  mandelbrot_print("game lost crash", 26, height - 100)
  mandelbrot_print("v. 0.6", 26, height - 60)

  love.graphics.setFont(previous_font)
end

return { load=mandelbrot_load,
         update=mandelbrot_update,
         draw=mandelbrot_draw }
