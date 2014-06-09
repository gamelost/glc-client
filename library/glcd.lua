require "library/nsq"
require "settings"
require "socket"
require "json"

underscore = require("library/underscore")
inspect = require("library/inspect")
nsq = require("library/nsqc")

-- generate users' client ID
s = socket.udp()
s:setpeername("8.8.8.8", 51)
ip, _ = s:getsockname()
playername = os.getenv("USER")
clientid = ip .. "-" .. playername
fullclientid = settings.nsq_host .. ":" .. settings.nsq_port .. ":" .. settings.nsq_daemon_topic

-- poll glcd (the server)
glcd = love.thread.newThread("scripts/poll-glcd.lua")
glcdrecv = love.thread.newChannel()
glcd:start(clientid:sub(1,30), glcdrecv)

-- nsq publishing connection
pub = NsqHttp:new()

-- heartbeat
lastheartbeat = love.timer.getTime()

-- handlers
handlers = {}

function addHandler(command, handler)
  assert(handler ~= nil)
  handlers[command] = handler
end

function send(command, msg)
  local val = {
    -- ClientId = fullclientid,
    ClientId = playername,
    Type = command,
    Data = msg
  }
  local data = json.encode(val)
  local result = pub:publish(settings.nsq_daemon_topic, data)
  print("NSQ: Sending '" .. data .. "': ", result)
  lastheartbeat = love.timer.getTime()
end

function table.contains(table, element)
  for _, value in pairs(table) do
    if value == element then
      return table[element]
    end
  end
  return nil
end

function poll()
  -- heartbeat
  local elapsed = love.timer.getTime() - lastheartbeat
  if elapsed > 5.0 then
    send('heartbeat', { beat = "ba-dum"})
  end

  -- Incoming
  incoming = glcdrecv:pop()
  while incoming do
    msg = json.decode(incoming)
    --print("incoming: " .. inspect(msg))

    assert(#msg==0)

    -- todo: better way of doing this, kthxbai
    if msg.Type=="updateZone" and handlers["updateZone"] then
      handlers["updateZone"](msg.Data)
    end
    if msg.Type=="playerState" and handlers["playerState"] then
      handlers["playerState"](msg.Data)
    end
    if msg.playerGone and handlers["playerGone"] then
      handlers["playerGone"](msg.playerGone)
    end
    -- todo: implement this
    if msg.error and handlers["error"] then
      handlers["error"](msg.error)
    end

    -- wall still uses this
    if handlers[msg.command] then
      handlers[msg.command](msg)
    end
    incoming = glcdrecv:pop()
  end
end

return {
  send = send,
  poll = poll,
  addHandler = addHandler,
  clientid = fullclientid,
  name = playername
}
