# Example: buffers/json

Decodes buffers into length headers and JSON content.

Uses three nodes:

1. **header** - reads 4 bytes as an int and stores it as the content length to get
2. **content** - gathers buffer content until it has at least the content length read by **header**
3. **parse** - parses the JSON into a value
4. **report** - reports the parsed value to the console

Shows features:

1. building a buffer processing "executor"
2. using `control.next()` to move between nodes
3. showing `control.next()` receiving more than one node
4. showing `control.next()` called without any args
5. accessing and changing values in the context
6. using `control.wait()` to wait for more input
7. no `executor.process(null)` or with empty string required because we know exactly how many bytes we need each time.
8. using default context
9. providing input in chunks repeatedly to `executor.process()`

Also, note **content** queue's both **parse** and **header** next. Then, **parse** queue's **report** next. So, **report** runs and then when it does `control.next()` without specifying anything next it moves on to **header** which was queue'd by **content**.


```sh
npm run json
```
