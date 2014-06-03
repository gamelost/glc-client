local http = require("socket.http")
local ltn12 = require("ltn12")

Http = {}

function url_encode(str)
   if (str) then
      str = string.gsub (str, "\n", "\r\n")
      str = string.gsub (str, "([^%w %-%_%.%~])",
                         function (c) return string.format ("%%%02X", string.byte(c)) end)
      str = string.gsub (str, " ", "+")
   end
   return str
end

function Http:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

function Http:get(url, params, callback)
  -- set up the url query string
  local query = {}
  for k, v in pairs(params) do
     table.insert(query, url_encode(k) .. "=" .. url_encode(v))
  end
  if #query ~= 0 then
     url = url .. "?" .. table.concat(query, "&")
  end
  -- do the http request
  local chunks = {}
  local _, status = http.request{
    method = "GET",
    url = self.url_prefix .. url,
    sink = ltn12.sink.table(chunks)
  }
  -- construct and return response
  local response = table.concat(chunks)
  if callback ~= nil then
    return callback(status, response)
  end
  return response
end

function Http:post(url, params, body, callback)
  -- set up the url query string
  local query = {}
  for k, v in pairs(params) do
     table.insert(query, url_encode(k) .. "=" .. url_encode(v))
  end
  if #query ~= 0 then
     url = url .. "?" .. table.concat(query, "&")
  end
  -- do the http request
  local headers = {
    ["Content-Type"] = "application/x-www-form-urlencoded";
    ["Content-Length"] = #body;
  }
  local chunks = {}
  local _, status = http.request{
    method = "POST",
    url = self.url_prefix .. url,
    source = ltn12.source.string(body),
    sink = ltn12.sink.table(chunks),
    headers = headers
  }
  -- construct and return response
  local response = table.concat(chunks)
  if callback ~= nil then
    return callback(status, response)
  end
  return response
end
