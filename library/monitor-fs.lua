require "love.filesystem"
require "settings"

current = {}

function traverse(folder, callback)
  local files = love.filesystem.getDirectoryItems(folder)
  for i, v in ipairs(files) do
    local file = folder .. "/" .. v
    if love.filesystem.isDirectory(file) then
      traverse(file, callback)
    else
      callback(file)
    end
  end
end

function checkForModifications(filename)
  if love.filesystem.isDirectory(filename) then
    print(filename .. " error: is a dictionary")
    return
  end
  local ts, err = love.filesystem.getLastModified(filename)
  if err then
    print(filename .. " error: " .. err)
    return
  end
  local last_ts = current[filename]
  if last_ts == nil or ts ~= last_ts then
    loadAsset(filename)
  end
end

monitor_fs = {}

function refresh()
  traverse(settings.assets_dir, checkForModifications)
end

function loadWad(filename)
  -- to be implemented!
end

function loadAsset(filename)
  current[filename], err = love.filesystem.getLastModified(filename)
  print("loaded asset " .. filename)
end

monitor_fs.refresh = refresh
return monitor_fs
