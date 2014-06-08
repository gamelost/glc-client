function onWall(v)
  console.log("WALL: " .. v.name .. ': ' .. v.data.message)
end

function chat(text)
  glcd.send("wall", {message=text})
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
  if v.data == nil or v.client == nil then
    -- error from the server? we shouldn't see this
    print("error: onplayerstate information was empty")
  elseif v.name ~= glcd.name then
    otherPlayers[v.name] = v.data
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
