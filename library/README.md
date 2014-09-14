This library directory contains all the core `lua` modules for `glc`.

console.lua
===========

This file implements the console dropdown that we see on `glc-client`. Currently the console can be used to send chat messages, but not much else.

The console will eventually have its own font, drawable area, and `REPL` but that is still in progress.

debug.lua
=========

Not used at present.

fs.lua
======

This file is used to set up a poor man's asset server (an insecure VM that everyone has `sshfs` access to). If the VM is not reachable via `sshfs` then the default fallback is the user's own `asset/` directory.

(Since we did not have time to design a proper asset server, it was determined that we could all share the same online folder for asset collaboration, as long as we were careful to communicate what we were modifying and when.)

`refresh` checks the asset directory and returns any updated zone files. The intent is to re-load zones every time a file is modified, so that the user/programmer can get direct feedback on his or her zone changes.

This module will probably be superseded with the advent of a proper asset server.

glcd.lua
========

This module is the only means of communication with [glcd](https://github.com/gamelost/glcd) and exposes the ability to `send` messages to and `poll` for messages from the `glcd` server. These functions internally maintain threads/channels for communication with `glcd` (see the [scripts/](../scripts) directory for more detail). Hence, these functions are non-blocking.

It is also possible to set an handler to process any `NSQ` message type. It is important to note that if a handler subscribes to a `"foobar"` message type, the handler will get only the `Data` associated with the message.

Currently all `glcd` handlers are hard-coded in [glcd-handlers.lua](../glcd-handlers.lua).

If you want to add a new message type, you will have to add the new message type on the `glcd` server too. This is a severe limitation that we hope to have solved in the near future.

http.lua
========

A helper module for `NSQ` http communication. This module is straightforward but a bit clunky, since it uses an outdated `source` and `sink` technique to process responses. For more information, see [Filter Sources and Sinks](http://lua-users.org/wiki/FiltersSourcesAndSinks).

inspect.lua
===========

From [github.com/kikito/inspect.lua](http://github.com/kikito/inspect.lua), this module provides "human-readable representations of tables." We have found this module to be invaluable in debugging, as `lua` does not provide a built-in or easy way to print nested tables.

json.lua
========

From [json.luaforge.net](http://json.luaforge.net/), this module adds JSON encoding and decoding support. Used in the `nsq` http interface.

nsq.lua
=======

Uses both [library/http.lua](http.lua) and [library/json.lua](json.lua) to interface with the `NSQ` http interface. Note that the `NSQ` http interface may be deprecated in the near future, so it is best to use the binary interface whenever possible.

Currently the most useful functions in this module are `NsqHttp:publish`, `NsqHttp:createTopic`, `NsqHttp:createChannel`.

For an overview of `NSQ` in general, please visit this `NSQ` [blog post](http://word.bitly.com/post/33232969144/nsq). The Wikipedia article on [message queues](http://en.wikipedia.org/wiki/Message_queue) may also be of interest.

nsqc.lua
========

From [github.com/cw-lua](https://github.com/catwell/cw-lua/tree/master/nsqc), this module adds binary support for `NSQ` -- somewhat, as this only supports reading from `NSQ` channels.

Because of the limitations of [library/nsqc.lua](nsqc.lua) and [library/nsq.lua](nsq.lua) a full `NSQ` binary protocol implementation is in process.

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

underscore.lua
==============

From [github.io/underscore.lua](http://mirven.github.io/underscore.lua/), this module is a set of utility functions for dealing with iterators, arrays, tables, and functions. Essentially a `lua` clone of [underscore.js](http://documentcloud.github.io/underscore/).

zone.lua
========

This module implements sandboxing of zones.

A zone is a distinct 2d region that contains its own rules, graphics, and other assets. Essentially, a zone is its own "game" area. Currently zones are hard-coded to make up a space of 25x25 tiles, with each tile being 16x16 pixels.

Zones are drawn right-to-left. We overload the zone id to also represent its position within the `glc` universe.

Zones have three main functions: `init`, `data`, and `update`. `init` is self-explanatory; `data` is used to set zone data from outside (currently only `glcd` can update zone data: see `updateZone` in [glcd-handlers.lua](../glcd-handlers.lua)); and `update` is called every frame.