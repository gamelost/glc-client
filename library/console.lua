local visible = true

local function drawBackground(line_height)
  local r, g, b, a = love.graphics.getColor()
  love.graphics.setColor(128, 128, 128, 128) -- Hardcoded for now.
  love.graphics.rectangle("fill", 0, 0, win.width, (config.max_rows * line_height) + 3)
  love.graphics.setColor(r, g, b, a)
end

local messages = {}
local console_in = nil

local function log(msg)
  table.insert(messages, 1, msg)
  print("logged:", msg)
end

local function draw()
  if not visible then
    return
  end

  -- TODO: this module should manage its own font.
  local line_height = love.graphics.getFont():getHeight()

  drawBackground(line_height)

  for i = 1, config.max_rows do
    local k = messages[config.max_rows - i]
    --print("messages["..i.."]:", config.messages[i])
    if k ~= nil then
      love.graphics.print(k, 0, (i - 1) * line_height)
    end
  end

  if console_in ~= nil then
      love.graphics.print("> " .. console_in, 0, (config.max_rows - 1) * line_height)
  end
end

local function hide()
  -- todo with hide and show: Slide in and out instead of just vanish+appear
  visible = false
end

local function show()
  visible = true
end

local function toggle()
  visible = not visible
end

local function inputText(text)
  console_in = console_in .. text
end

local commands = {}

local function addCommand(cmd, func)
  commands[cmd] = func
end

local function handle(text)
  if string.sub(text, 1, 1) == "/" then
    local command = nil
    local args = nil
    local delim = string.find(text, " ")
    if delim ~= nil then
      command = string.sub(text, 2, delim - 1)
      args = string.sub(text, delim + 1)
    else
      command = string.sub(text, 2)
    end
    if commands[command] then
      commands[command](args)
    else
      log("No such command '" .. command .. "'")
    end
  else
    config.defaultHandler(text)
  end
end

local function inputKey(key)
  if key == "backspace" then
    console_in = string.sub(console_in, 1, #console_in - 1)
  elseif key == "return" then
    str = console_in
    console_in = ""
    handle(str)
  end
end

local function inputClear()
  console_in = nil
end

local function inputStart()
  console_in = ""
end

config = {
  hide = hide,
  show = show,
  log = log,
  draw = draw,
  defaultHandler = log,
  addCommand = addCommand,
  input = {
    start = inputStart,
    key = inputKey,
    text = inputText,
    cancel = inputClear
  },
  max_rows = 8
}

return config
