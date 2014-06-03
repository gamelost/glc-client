win = {}

-- Overrides the default LOVE configuration file. 't' contains a table with the default values.
function love.conf(t)
	t.console = true

	t.window.title = "Game Lost Crash"
	t.window.icon = nil
	t.window.width = 1024
	t.window.height = 768
	t.window.borderless = false
	t.window.fullscreen = false
	t.window.fullscreentype = "normal"
	t.window.fsaa = 0
	t.window.vsync = true
	t.window.highdpi = false

	win = t.window
end
