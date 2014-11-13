
Networking related files for `glc`.

glcd.lua
========

This module is the only means of communication with [glcd](https://github.com/gamelost/glcd) and exposes the ability to `send` messages to and `poll` for messages from the `glcd` server. These functions internally maintain threads/channels for communication with `glcd` (see the [scripts/](../scripts) directory for more detail). Hence, these functions are non-blocking.

It is also possible to set an handler to process any `NSQ` message type. It is important to note that if a handler subscribes to a `"foobar"` message type, the handler will get only the `Data` associated with the message.

Currently all `glcd` handlers are hard-coded in [glcd-handlers.lua](../glcd-handlers.lua).

If you want to add a new message type, you will have to add the new message type on the `glcd` server too. This is a severe limitation that we hope to have solved in the near future.

http.lua
========

A helper module for `NSQ` http communication. This module is straightforward but a bit clunky, since it uses an outdated `source` and `sink` technique to process responses. For more information, see [Filter Sources and Sinks](http://lua-users.org/wiki/FiltersSourcesAndSinks).

json.lua
========

From [json.luaforge.net](http://json.luaforge.net/), this module adds JSON encoding and decoding support. Used in the `nsq` http interface.

nsqc.lua
========

From [github.com/cw-lua](https://github.com/catwell/cw-lua/tree/master/nsqc), this module adds binary support for `NSQ` -- somewhat, as this only supports reading from `NSQ` channels.

Because of the limitations of [library/nsqc.lua](nsqc.lua) and [library/nsq.lua](nsq.lua) a full `NSQ` binary protocol implementation is in process.

nsq.lua
=======

Uses both [library/http.lua](http.lua) and [library/json.lua](json.lua) to interface with the `NSQ` http interface. Note that the `NSQ` http interface may be deprecated in the near future, so it is best to use the binary interface whenever possible.

Currently the most useful functions in this module are `NsqHttp:publish`, `NsqHttp:createTopic`, `NsqHttp:createChannel`.

For an overview of `NSQ` in general, please visit this `NSQ` [blog post](http://word.bitly.com/post/33232969144/nsq). The Wikipedia article on [message queues](http://en.wikipedia.org/wiki/Message_queue) may also be of interest.
