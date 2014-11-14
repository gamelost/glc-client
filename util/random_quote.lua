return function ()
  local f = io.open("assets/loading/quotes.json", "rb")
  local quotes = json.decode(f:read("*all"))
  f:close()
  local index = math.random(#quotes.quotes)
  return '"' .. quotes.quotes[index] .. '"'
end
