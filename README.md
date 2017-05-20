# stating
[![Build Status](https://travis-ci.org/elidoran/node-stating.svg?branch=master)](https://travis-ci.org/elidoran/node-stating)
[![Dependency Status](https://gemnasium.com/elidoran/node-stating.png)](https://gemnasium.com/elidoran/node-stating)
[![npm version](https://badge.fury.io/js/stating.svg)](http://badge.fury.io/js/stating)
[![Coverage Status](https://coveralls.io/repos/github/elidoran/node-stating/badge.svg?branch=master)](https://coveralls.io/github/elidoran/node-stating?branch=master)

Build a state machine with simple function nodes.

Each node is a function so it's also an action for the "state".

Each node specifies the next node, or nodes, which allows for dynamically specifying state transitions.

It's a malleable state machine. Others may add new nodes at any time, and, it's also possible to add nodes both "before" and "after" other nodes which may override a node or alter where it transitions to.

You may supply a node to run next which hasn't been added to the `stating` instance. Or, provide a function you just generated.


## Install

```sh
npm install stating --save
```


## Examples

See [/examples](examples) for some runnable examples.

1. [strings/counter](examples/strings/counter)
2. [strings/counter-direct](examples/strings/counter-direct)
3. [buffers/json](examples/buffers/json)
4. [transforms/math](examples/transforms/math)
5. ~~[objects/messages](examples/objects/messages)~~
6. [strings/json](examples/strings/json)


## Usage

```javascript
// returns a builder function
var buildNodes = require('stating')

// build a new nodes for us to configure
var nodes = buildNodes()

// add a "node", which is a function with an id
nodes.add('someId', function (control, N) {

  // do something with the @input / context.input
  // it's the object provided to process()

  if (/* things are okay, move to the next node */)
    control.next(n.nextId)
  else
    control.fail('there was a problem')
})

nodes.add('nextId', function (control, N) {
  // do something ... and then tell it to move back to the first node
  control.next(N.someId)
})

// Alternate way to add nodes as an object:
nodes.addAll({
  someId: function (control, N) {
    // same as the function used above
  },

  nextId: function (control, N) {
    // same as the function used above
  }
})

// first added node is the 'start' node by default.
//   OR:
// set it explicitly:
nodes.start('someId')

// Alter flow with before/after nodes by specifying which nodes should
// be targeted and which nodes should be applied. works as it reads.
// simple examples, do one before, or after, the specified one:

// will configure 'valid' to run before 'assign' does.
// this means any time any node says to switch to 'assign'
// then the 'valid' node will be run.
nodes.before('assign').run('valid')

// will configure 'some' to run after 'change'.
// this will configure 'some' to run after the 'change' node.
// any time any node says to run 'change' then 'some'
// will be run after it.
nodes.after('change').run('some')

// these mean the same except they target more functions at once.
// these are convenience functions to easily target many nodes.

// this will make all three "blah" nodes run before 'id1' and 'id2'.
// so, any time any node says to run either 'id1' or 'id2'
// it will run all three "blah" nodes *first*.
nodes.before('id1', 'id2').run('blah1', 'blah2', 'blah3')

// same as the before, except, run them after.
nodes.after('diff id', 'id2', 'id3').run('blah4', 'blah5', 'blah6')

// A. For Object inputs:
// create an executor prepared to process objects.
var executor = nodes.objects()

// then provide objects via process()
executor.process({some:'input object'})

// B. For String inputs:
// create an executor prepared to process string.
var executor = nodes.strings()

// then provide strings via process()
executor.process('some input')

// C. For Transforms:
// default transform has string input and object output.
// so, writableObjectMode is false and,
// readableObjectMode is true.
var transform = nodes.transform()

// change from the default with options:
var transform = nodes.transform({
  // example of changing to string/buffer output
  readableObjectMode: false

  // example: enforce Buffer instead of string.
  decodeStrings: true,
})

someSource.pipe(transform).pipe(someTarget);


// Add an event emitter to the `control` each node
// will receive when called.

// set options' `events` to true to use the events.EventEmitter
var options = { events:true }

// or, set your own event emitter instance:
var options = { events: yourEventEmitter }

// then create the usual executor with the options...
var executor = nodes.objects(options)
var executor = nodes.strings(options)
```


## Future

First, finalize how Stating/Control handle nodes and the internal execution queue.

Then, it's all about adding builders/helpers to create the nodes supplied to a Stating instance. See [@stating/builder](https://www.npmjs.com/package/@stating/builder) for a start.

For example, look at the [JSON example nodes](examples/strings/json/nodes.coffee) for `true`, `false`, and `null`. All that for a static string. I'm sure I could make a builder to help make nodes like that. **I did**: [@stating/string-plugin](https://www.npmjs.com/package/@stating/string-plugin).

Also, nodes like the "element" and "element ," for reading an array, which work together as the first and the repeater, could be made via a helper by telling it what is wanted each time and what the separator is.

There's more. I plan to add those later as packages in the `stating` scope.

Feel free to suggest some or contribute some to the scope.

The hideous "initializer functions" thing is gone in 0.4.0. Yay.


# [MIT License](LICENSE)
