Herein are all the assets that we will be using in `glc`. Most of these are graphical in nature.

For maps, we use the excellent [Tiled](http://www.mapeditor.org/). Fortuitously for us, Tiled exports to `lua` directly.

The starting tileset is [DawnLike](http://opengameart.org/content/dawnlike-16x16-universal-rogue-like-tileset-v18) made by DawnBringer. This is currently the only tileset we use, but we plan to add more in the future.

The zones here are testing areas and are automatically loaded up when the game starts. A zone is defined by a directory with a `.wad` file: one asset file per line. Assets can be a `lua` file, a font, an image, or a sound asset, or anything else indeed. For example, [zone-test/test.wad](zone-test/test.wad) contains the following lines:

```
file://assets/zone-test/Dungeon_sans_npcs.lua
file://assets/zone-test/out-of-farm.lua
file://assets/zone-test/dungeon-zone.lua
```

Zones and their asset files are loaded on demand, and eventually will be re-loaded when any files in the zone directory are modified.

The upcoming asset server will eventually centralize zones so that everyone will have access to the same shared and mutable assets. For now, zones are a bit ad-hoc: they can access any file in `assets/`. This will change in the near future.