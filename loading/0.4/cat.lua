
function animation(frames, path_to_frame)
  -- given a list of frames and a string which identifies these frames
  -- as files, return an array of loaded images.
  local animations = {}
  for index, frame in ipairs(frames) do
    local file_name = string.format(path_to_frame, frame)
    animations[index] = love.graphics.newImage(file_name)
  end
  return animations
end

function endless_cat_frames(n)
  -- load cat animations
  local cat_path = "assets/loading/cat/cat-%.2d.png"
  local cat_step = { 0, 1, 2, 3, 4, 5, 6 }
  local cat_dance = { 26, 27, 28, 29, 30, 31, 32, 33 }
  local cat_animations = { step=animation(cat_step, cat_path),
                           dance=animation(cat_dance, cat_path) }

  -- return an endlessly animated loop
  return coroutine.wrap(function()
      while true do
        -- n iterations of step
        for i = 0,n do
          for _, image in ipairs(cat_animations.step) do
            coroutine.yield(image)
          end
        end
        -- n iterations of dance
        for i = 0,n do
          for _, image in ipairs(cat_animations.dance) do
            coroutine.yield(image)
          end
        end
      end
  end)
end

function cat_load()
  -- prep cat animation
  cat_frames = endless_cat_frames(0)
  current_frame = cat_frames()

  -- set up the loading font
  loading_font = love.graphics.newFont("assets/Krungthep.ttf", 18)

  -- store dimensions
  glc_w, glc_h = current_frame:getDimensions()
  width, height = love.graphics.getDimensions()

  -- track time
  latest = 0.0
end

function cat_update(dt)
  -- TODO: can be converted to fixed time step function.
  local animation_step = dt - latest
  if animation_step > 0.06 then
    latest = dt
    current_frame = cat_frames()
  end
end

function cat_draw()
  local x = width/2 - glc_w/2
  local y = height/2 - glc_h/2
  local previous_font = love.graphics.getFont()
  love.graphics.setBackgroundColor(255, 255, 255, 0)
  love.graphics.setFont(loading_font)
  love.graphics.setColor(255, 255, 255)
  love.graphics.draw(current_frame, x, y)
  love.graphics.setColor(0, 0, 0)
  love.graphics.print("game lost crash* client v0.4", x + 56, y + 32)
  love.graphics.print("* WARNING: may live up to its namesake.", 0, height-24)
  love.graphics.setFont(previous_font)
end

return { load=cat_load,
         update=cat_update,
         draw=cat_draw }
