Utility files for `glc`.

clock.lua
=========

Sets up timers with callbacks. You can either `schedule` a timer to run `x` seconds from now, or you can set up a periodic timer with `every`. Both require a function to be passed in. Once the given time period has elapsed, the passed-in function will be called.

debug.lua
=========

Not used at present.

fs.lua
======

This file is used to set up a poor man's asset server (an insecure VM that everyone has `sshfs` access to). If the VM is not reachable via `sshfs` then the default fallback is the user's own `asset/` directory.

(Since we did not have time to design a proper asset server, it was determined that we could all share the same online folder for asset collaboration, as long as we were careful to communicate what we were modifying and when.)

`refresh` checks the asset directory and returns any updated zone files. The intent is to re-load zones every time a file is modified, so that the user/programmer can get direct feedback on his or her zone changes.

This module will probably be superseded with the advent of a proper asset server.

inspect.lua
===========

From [github.com/kikito/inspect.lua](http://github.com/kikito/inspect.lua), this module provides "human-readable representations of tables." We have found this module to be invaluable in debugging, as `lua` does not provide a built-in or easy way to print nested tables.

random_quote.lua
================

Emits a random quote from [quotes.json](../assets/loading/quotes.json).

underscore.lua
==============

From [github.io/underscore.lua](http://mirven.github.io/underscore.lua/), this module is a set of utility functions for dealing with iterators, arrays, tables, and functions. Essentially a `lua` clone of [underscore.js](http://documentcloud.github.io/underscore/).
