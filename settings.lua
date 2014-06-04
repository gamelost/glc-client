settings = {}
settings.url_prefix = "http://lethalcode.net:4151"
settings.assets_dir = "assets"

-- currently only works in the ohl office
settings.asset_vm_dir = "assets/vm"
settings.asset_vm_userhost = "vagrant@assets.ohl"
settings.asset_vm_remotedir = "."
settings.asset_vm_keypath = "keys/insecure_private_key"

function mount_vm_command(keypath, userhost, remotedir)
  os = require "os"
  local str = 'sshfs -o ssh_command="ssh -i ' ..
    keypath .. '" ' ..
    userhost .. ':' ..
    remotedir
  print('attempting to mount asset vm: "' .. str .. '"')
  return os.execute(str) == 0
end
settings.mount_asset_vm_command = mount_vm_command
