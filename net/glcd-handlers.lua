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
    glcd.send("playerState", myPlayerState)
  elseif msg.request == "fireBullet" then
    bullet = Gamelost.Bullet.new(msg.bullet)
    -- only one at a time
    Gamelost.spriteList["bullet"] = bullet
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
    error("onPlayerGone: information was empty", 1)
  end

  Gamelost.spriteList[v] = nil
end

local function onPlayerState(v)
  local clientid = v.ClientId

  if clientid == nil then
    error("onPlayerState: information was empty", 1)
  end
  if clientid == glcd.clientid then
    -- don't bother updating our own information
    return
  end

  if Gamelost.spriteList[clientid] == nil then
    -- we have a new player. initialize appropriately.
    Gamelost.spriteList[clientid] = Gamelost.Player.new(v.Data)
  else
    -- else update player values.
    Gamelost.spriteList[clientid]:updateState(v.Data)
  end
end

-- If the heartbeat is from other players, then go forth and update the status
-- otherwise go forth and update.
local function onPlayerHeartbeat(v)
  local clientid = v.ClientId

  if clientid == nil then
    error("onPlayerHeartbeat: information was empty", 1)
  end
  if clientid == glcd.clientid then
    -- don't bother updating our own information
    return
  end

  if v.Status == "QUIT" then
    Gamelost.spriteList[clientid] = nil
  else
    -- TODO disabled for now; v is null, so v.Status breaks
    --Gamelost.spriteList[clientid]:updateState{Status=v.Status}
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
