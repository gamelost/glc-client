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

function init()
  -- attempt to sshfs mount the vm. if this fails, just fall back to
  -- the regular assets directory.
  love.filesystem.createDirectory(settings.asset_vm_dir)
  -- key path must be absolute
  local cwd = love.filesystem.getWorkingDirectory()
  local keypath = cwd .. "/" .. settings.asset_vm_keypath
  local result = settings.mount_asset_vm_command(keypath,
                                                 settings.asset_vm_userhost,
                                                 settings.asset_vm_remotedir)
  if result == 0 then
    current.assets_dir = settings.asset_vm_dir
    print("using asset vm")
  else
    current.assets_dir = settings.assets_dir
    print("using regular assets")
  end
end

function refresh()
  traverse(current.assets_dir, checkForModifications)
end

function loadWad(filename)
  -- to be implemented!
end

function loadAsset(filename)
  current[filename], err = love.filesystem.getLastModified(filename)
  print("loaded asset " .. filename)
end

monitor_fs.init = init
monitor_fs.refresh = refresh
return monitor_fs
