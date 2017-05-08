# Example: JSON parser

Parses JSON string like `JSON.parse()`.

Uses nodes:

1. **start** - the start node understands the main goal: parse a value, send it, go back to start.
2. **value** - the big "get any kind of valid JSON value" node.
3. **number** - gets the number content after the first digit or sign which is found in **value**.
4. **string** - expects a double quote and then passed on to the "not quote" node
5. **!"** - (not quote) gathers input until another double quote is found
6. **stringValue** - a follow-up used by **value** node to use the gathered string as *the* value to send
7. **true**, **false**, **null** - simple "match the string" nodes. the **value* node attempts to short circuit these when enough input is available,
8. **pair** - gets the first key/value pair for of an object
9. **pair ,** - checks for a comma to get more pairs for the object. handles assigning the value into the object using the string key.
10. **key** - stores the gathered string as a "key" to use after its value is available.
11. **:** - (colon) matches a colon after an object's key. Only used if there isn't enough input available in the **key** node
12. **element** - gets the first value in an array
13. **element ,** - checks for a comma to get another element for the array. handles pushing the value into the array.
14. **send** - a node which uses the current `value` as a result to return. (only to support a synchronous return so it works like `JSON.parse()` and others. the real advantage of `stating` is it can handle waiting for more streamed chunks to process).

Shows features:

1. **todo**

Try providing your own input. For example:

```sh
npm run json -- --input '"some string"'
npm run json -- --input '{"some":"object"}'
npm run json -- --input '[1, 2, 3, "array"]'
# put a newline, or some space, after a simple
# number so it knows that's the end of it.
# otherwise, it waits for more digits...
npm run json -- --input '123\n'
```
