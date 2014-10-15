
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

function endless_smbw_frames(n)
  -- load cat animations
  local smbw_path = "assets/loading/smbw/grande-%.2d.png"
  local smbw_steps = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14 }
  -- for i=0, 14 do
  --   smbw_steps[i] = nil
  -- end
  local smbw_animation = animation(smbw_steps, smbw_path)

  -- return an endlessly animated loop
  return coroutine.wrap(function()
      while true do
        for i = 0,n do
          for _, image in ipairs(smbw_animation) do
            coroutine.yield(image)
          end
        end
      end
  end)
end

function smbw_load()
  -- prep smbw animation
  smbw_frames = endless_smbw_frames(0)
  current_frame = smbw_frames()

  -- set up the loading font
  loading_font = love.graphics.newFont("assets/loading/smbw/SuperMario256.ttf", 42)

  -- store dimensions
  width, height = love.graphics.getDimensions()
end

function smbw_update()
  current_frame = smbw_frames()
end

function smbw_print(str, x, y)
  love.graphics.print(str, x, y)
  love.graphics.setColor(252, 205, 41)
  love.graphics.print(str, x - 6, y - 6)
  love.graphics.setColor(250, 57, 60)
end

function smbw_draw()
  local previous_font = love.graphics.getFont()
  love.graphics.scale(2.1, 2.0)
  love.graphics.setBackgroundColor(255, 255, 255, 0)
  love.graphics.setColor(255, 255, 255)
  love.graphics.draw(current_frame, 0, 0)
  love.graphics.setFont(loading_font)
  love.graphics.setColor(250, 57, 60)
  smbw_print("game lost crash", 26, 82)
  smbw_print("0.5", (width/2.1/2) - 34, 150)
  love.graphics.setFont(previous_font)
end

return { load=smbw_load,
         update=smbw_update,
         draw=smbw_draw }
