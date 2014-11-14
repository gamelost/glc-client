
function original_load()
  glc = love.graphics.newImage("assets/loading/original/gamelostcrash.png")
  glc_w, glc_h = glc:getDimensions()
  width, height = love.graphics.getDimensions()
end

function original_update(dt)
  -- no-op.
end

function original_draw()
  local x = width/2 - glc_w/2
  local y = height/2 - glc_h/2
  love.graphics.draw(glc, x, y)
  love.graphics.setBackgroundColor(0x62, 0x36, 0xb3)
end

return { load=original_load,
         update=original_update,
         draw=original_draw }
