require "library/nsq"
require "socket"
require "json"
require "conf"

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
  print("NSQ: Sending '" .. command .. "': ", result)
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
    lastheartbeat = love.timer.getTime()
  end

  -- Incoming
  incoming = glcdrecv:pop()
  while incoming do
    msg = json.decode(incoming)
    --print("incoming: " .. inspect(msg))

    assert(#msg==0)

    if handlers[msg.Type] then
      handlers[msg.Type](msg.Data, msg)
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
