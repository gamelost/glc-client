local inspect = require("util/inspect")

local function onChat(v, m)
  if not v.Sender then
    v.Sender = "ANNOUNCE"
  end
  console.log(v.Sender .. ': ' .. v.Message)
  if Gamelost.spriteList[m.ClientId] then
    Gamelost.spriteList[m.ClientId].msg = v.Message
    Gamelost.spriteList[m.ClientId].msgtime = love.timer.getTime()
  end
end

local function chat(text)
  glcd.send("chat", {Message=text, Sender = glcd.name})
  myPlayer.msg = text
  myPlayer.msgtime = love.timer.getTime()
end

local function onBroadcast(msg)
  if msg.request == "playerState" then
    glcd.send("playerState", myState)
  elseif msg.request == "fireBullet" then
    table.insert(Gamelost.spriteList, Gamelost.Bullet.new(msg.bullet))
  elseif msg.request == "metadata_hit" then
    if msg.properties.action == "toggle_next_layer" then
      local currZone = nil
      -- ugh.
      for _, zone in pairs(zones) do
        if zone.state.data.id == msg.zoneid then
          currZone = zone
          break
        end
      end
      if currZone then
        currZone.state.toggle_next_layer(currZone.state.tiles)
      end
    else
      console.log("metadata hit: " .. inspect(msg.properties))
    end
  end
end

local function onPlayerGone(v)
  if v == nil then
    -- error from the server? we shouldn't see this
    print("error: onplayergone information was empty")
  else
    Gamelost.spriteList[v] = nil
  end
end

local function onPlayerState(v)
  -- testing
  local clientid = v.ClientId
  if clientid == nil then
    -- error from the server? we shouldn't see this
    print("error: onplayerstate information was empty")
  elseif clientid ~= glcd.clientid then
    if Gamelost.spriteList[clientid] == nil then
      Gamelost.spriteList[clientid] = {name=clientid}
      if v.Name then
        Gamelost.spriteList[clientid].name = v.Name
      else
        local tokens = string.gmatch(clientid, "-")
        Gamelost.spriteList[clientid].name = tokens[2]
      end
    end
    Gamelost.spriteList[clientid].state = v
  end
end

-- If the heartbeat is from other players, then go forth and update the status
-- otherwise go forth and update.
local function onPlayerHeartbeat(obj)
  if ClientId ~= glcd.clientid then
    if Gamelost.spriteList[obj.ClientId] ~= nil then
      Gamelost.spriteList[obj.ClientId].status = obj.Status
    end
    if obj.Status == "QUIT" then
      Gamelost.spriteList[obj.ClientId] = nil
    end
  end
end

local function updateZone(z)
  for _, zone in pairs(zones) do
    if zone.name == z.zone then
      zone.data(z)
    end
  end
end

local function onError(err)
  print("error: " .. err)
end

return {
  sendChat=chat,
  chat=onChat,
  playerGone=onPlayerGone,
  playerState=onPlayerState,
  updateZone=updateZone,
  playerHeartbeat=onPlayerHeartbeat,
  broadcast=onBroadcast,
  error=onError
}
