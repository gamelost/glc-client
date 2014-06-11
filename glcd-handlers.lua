local inspect = require("library/inspect")

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
  chat=onChat,
  updateZone=updateZone,
  error=onError
}
