This directory contains lua files that are intended to be run as [threads](http://love2d.org/wiki/love.thread). Because each lua file runs in its own contained environment, communication needs to be done through [channels](http://love2d.org/wiki/Channel). Thus, a channel is usually the first thing passed to the script.

You will often see a variable assigned to `...` in these files. This lua expression allows the variable to capture the parameters passed to the script.

A general design guideline is that thread code should be fairly simple in terms of functionality. Concurrency issues are no fun to debug!

monitor-fs.lua
==============

This thread checks to see if any zone file has been updated on the local filesystem (in `assets/`) in the last five seconds. Most of the heavy lifting is already implemented in [library/fs.lua](../library/fs.lua), so this thread simply exercises such functionality. (Incidentally, this is a poor man's [inotify](http://en.wikipedia.org/wiki/Inotify) -- a good improvement would be to add a platform independent filesystem notification system here.)

In any case, if there are any changes to zone data, the new zone data is passed back to the main thread through the given channel. Currently [main.lua](main.lua) only retrieves the local zones once, on start-up.

Eventually, we want to add support for arbitrary zone changes at any time so that zone files can be edited interactively for any given `glc-client` session.

poll-glcd.lua
=============

This thread, true to its name, polls the `glcd` server. We use [NSQ](https://github.com/bitly/nsq) for communication.

A `NSQ` connection is established, and the client is subscribed to a topic. For every `NSQ` message broadcast on that topic, this thread sends it back to the main thread.

This file is used in [library/glcd.lua](../library/glcd.lua) which sets up a series of handlers for `NSQ` messages. If a given handler is set up for a `NSQ` message type, [library/glcd.lua](../library/glcd.lua) will execute that handler with the contents of the message. For example,

	glcd.addHandler("chat", random_function)

will set up an handler such that `random_function` gets subsequent `NSQ` messages with the `Type` matching `chat`. Only the part marked as `Data` in the message is passed in, though.

Here is an example of a full `NSQ` chat message:

	{
	  ClientId = "10.0.0.133-james",
	  Data = {
	    Message = "greetings and salutations",
	    Sender = "james"
	  },
	  Type = "chat"
	}

The chat handler would only receive the subset:

	{
	    Message = "greetings and salutations",
	    Sender = "james"
	}

(The format of this `NSQ` message is subject to change)

With all this in mind, the purpose of this thread is simply to push subscription notifications back to [library/glcd.lua](../library/glcd.lua), which in turn executes the relevant handler (if set) with the `Data` of that message.

send-glcd.lua
=============

This thread, again, lives up to its namesake: sending messages to `glcd` through `NSQ`.

Due to hysterical raisins (historical reasons) we actually have two interfaces to `NSQ` in `glc-client`: a partially-working binary interface and a partially-working HTTP interface. We will eventually have a better and robust binary interface to `NSQ`, because the HTTP interface seems to be on the verge of being deprecated.

This file is used in [library/glcd.lua](../library/glcd.lua), as well. Specifically, the `send` function uses the channel set up with this thread. `glcd.send` is available there for any one who wants to send messages to `glcd`. Example usage:

	glcd.send("chat", {Sender=glcd.name, Message="Player has entered the Game!"})

Any messages to `glcd` are automatically converted to JSON.