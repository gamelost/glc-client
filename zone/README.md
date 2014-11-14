
This module implements sandboxing of zones.

zone.lua
========

A zone is a distinct 2d region that contains its own rules, graphics, and other assets. Essentially, a zone is its own "game" area. Currently zones are hard-coded to make up a space of 25x25 tiles, with each tile being 16x16 pixels.

Zones are drawn right-to-left. We overload the zone id to also represent its position within the `glc` universe.

Zones have three main functions: `init`, `data`, and `update`. `init` is self-explanatory; `data` is used to set zone data from outside (currently only `glcd` can update zone data: see `updateZone` in [glcd-handlers.lua](../glcd-handlers.lua)); and `update` is called every frame.