inspect = require("library/inspect")

function onWall(v)
  console.log("WALL: " .. v.name .. ': ' .. v.data.message)
  if otherPlayers[v.name] then
    otherPlayers[v.name].msg = v.data.message
    otherPlayers[v.name].msgtime = love.timer.getTime()
  end
end

function chat(text)
  glcd.send("wall", {message=text})
  myPlayer.msg = text
  myPlayer.msgtime = love.timer.getTime()
end

function onPlayerGone(v)
  if v == nil then
    -- error from the server? we shouldn't see this
    print("error: onplayergone information was empty")
  else
    otherPlayers[v] = nil
  end
end

function onPlayerState(v)
  -- testing
  if v.ClientId == nil then
    -- error from the server? we shouldn't see this
    print("error: onplayerstate information was empty")
  elseif v.name ~= glcd.name then
    if otherPlayers[v.name] == nil then
      otherPlayers[v.name] = {name=v.name}
    end
    otherPlayers[v.ClientId].state = v.data
  end
end

function updateZone(z)
  for _, zone in pairs(zones) do
    if zone.name == z.zone then
      zone.data(z)
    end
  end
end

function onError(err)
  print("error: " .. err)
end

return {
  default=chat,
  wall=onWall,
  playerGone=onPlayerGone,
  playerState=onPlayerState,
  updateZone=updateZone,
  error=onError
}
