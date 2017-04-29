# Example: character counter

Counts characters repeated in sequence and reports it to the console.

Uses three nodes:

1. **counter** - counts a character until a different character is encountered, then, moves to **use**. If `input` is null or zero length then it moves to **stop**.
2. **use** - reports the character and how many times it was counted.
3. **stop** - when `input` is null **or** zero length then **stop** waits, otherwise it moves to **count** to startup again.

Shows features:

1. building a string processing "executor"
2. using `control.next()` to move between nodes
3. accessing and changing values in the context
4. using `control.wait()` to wait for more input
5. providing a `null` value to flush that last count info.
6. using a "stop node" to hold until more input is provided.
7. providing a custom `context` via options
8. providing input in chunks repeatedly to `executor.process()`
9. shows using `trim` from `string-input` (not an appropriate use, thrown in there to show it works and get code coverage)
10. purposely avoids processing the whole input before waiting so the reset has to combine inputs


Try providing your own input. For example:

```sh
npm run counter -- --input 'abbcccddddeeeeeffffffggggggg'
```
