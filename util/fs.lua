require "love.filesystem"
require "conf"

current = {}
wads = {}

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
    loadFile(filename)
  end
end

function init()
  if not settings.attempt_mount then
    current.assets_dir = settings.assets_dir
    return
  end

  -- attempt to sshfs mount the vm. if this fails, just fall back to
  -- the regular assets directory.
  local cwd = love.filesystem.getWorkingDirectory()
  local keypath = cwd .. "/" .. settings.asset_vm_keypath -- key path must be absolute
  local result = settings.mount_asset_vm_command(keypath,
                                                 settings.asset_vm_userhost,
                                                 settings.asset_vm_remotedir,
                                                 settings.asset_vm_dir)
  if result then
    current.assets_dir = settings.asset_vm_dir
    print("mounted asset vm successfully.")
  else
    current.assets_dir = settings.assets_dir
    print("failed to mount asset vm; falling back to regular assets.")
  end
end

function refresh()
  wads = {}
  traverse(current.assets_dir, checkForModifications)
  return wads
end

function loadFile(filename)
  local extension = string.match(filename, ".([^.]+)$")
  if extension == "wad" then
    wads[filename] = true
  end
  current[filename], err = love.filesystem.getLastModified(filename)
end

monitor_fs = {}
monitor_fs.init = init
monitor_fs.refresh = refresh
return monitor_fs
