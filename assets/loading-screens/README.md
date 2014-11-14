This directory holds unique loading animations for `glc-client`. The purpose of these loading screens is to visually distinguish between releases, which come after every hack day. Thus, it is extremely quick and easy to tell if someone has an outdated or stale client.

Currently there are two loading screens. The first, `0.1` is the simplest, and just shows an arbitrary (non-official) game lost crash logo. The second, implemented for `0.4`, animates an unbearably cute, line-drawn cat. I believe the [cat loading screen](0.4/cat.lua) is the first usage of [lua coroutines](http://www.lua.org/pil/9.1.html) in the code, so it is worth checking out, if only for that reason alone.

To implement a loading screen, you need to offer three functions:

1. `load` (which may or may not do anything)
2. `update` which is called every frame (this may change in the future)
3. `draw` which draws the loading screen