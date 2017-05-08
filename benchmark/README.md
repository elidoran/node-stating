# Benchmarking

Only playing around so far.

Made a [JSON parser example](../examples/strings/json) to compare against `JSON.parse()`, a JSON parser implemented with [chevrotain](https://github.com/SAP/chevrotain), and a JSON parser implemented with [parsimmon](https://github.com/jneen/parsimmon).

Plan to add JSON parser implemented with [myna](https://github.com/cdiggins/myna-parser). Haven't figured out Myna enough yet.

Note the `stating` package's main goal is to accept input in **chunks** to support streaming. When it doesn't have enough input to continue it will wait to continue where it left off. The other parsers above must have all the input given to them at once.

Another goal is to allow dynamic state changes based on the input received. A node tells it where to go next so it can change its mind based on input. Parsimmon has a dynamic component to allow choosing what to do next, but, that's not quite the same thing. For example, `stating` can read from the input the name of a node or nodes to run next and use that.

So far, I've found `stating` isn't as slow as I was worried it may be. It is a lot longer than writing tokens and a grammar. Parsimmon's JSON parser is less than 100 lines of code. The nodes for the `stating` version are 500 plus the lines for configuring the context and setting up the "parser".
