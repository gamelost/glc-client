
Graphics operations for `glc`.

console.lua
===========

This file implements the console dropdown that we see on `glc-client`. Currently the console can be used to send chat messages, but not much else.

The console will eventually have its own font, drawable area, and `REPL` but that is still in progress.

tileset.lua
===========

This module takes in tilesets from [Tiled](http://www.mapeditor.org/) maps that have been exported to `lua` and processes them for drawing. In particular, this library also processes metadata, which is primarily used for collision detection between players and the map (see `hasCollision` in [main.lua](../main.lua)). The procedure for using this library is as follows:

First, import both this library and the `lua` tileset you want to display:

- `glc_tileset = require("library/tileset")`
- `random_tileset = require("your_tileset_here.lua")`

Load the tileset:

- `tilesets = glc_tileset.load_tiles(random_tileset)`

And draw the tiles at any point thereafter:

- `glc_tileset.draw_tiles`

The `draw_tiles` call will be improved in the future. Currently it takes the `tileset` and `id` as parameters.

The `tileset` parameter is the output from `load_tiles`. Strictly speaking, only the `layer`s and `tile`s are necessary, but for now we pass in the whole tileset data structure.

The `id` parameter is used to indicate the zone in which you want to draw the tileset. Currently zones are from left-to-right, so an `id` of `2` would draw the tileset for the third zone.
