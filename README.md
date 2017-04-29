# stating
[![Build Status](https://travis-ci.org/elidoran/node-stating.svg?branch=master)](https://travis-ci.org/elidoran/node-stating)
[![Dependency Status](https://gemnasium.com/elidoran/node-stating.png)](https://gemnasium.com/elidoran/node-stating)
[![npm version](https://badge.fury.io/js/stating.svg)](http://badge.fury.io/js/stating)

Build a state machine with simple function nodes.

Each node is a function so it's also an action for the "state".

Each node specifies the next node, or nodes, which allows for dynamically specifying state transitions.

It's a malleable state machine. Others may add new nodes at any time, and, it's also possible to add nodes both "before" and "after" other nodes which may override a node or alter where it transitions to.


## Install

```sh
npm install stating --save
```


## Usage

```javascript
// get the module, which is a builder function to build the nodes builder
var buildNodes = require('stating')

// build a builder for use here
  , nodes = buildNodes()

// add a "node", which is a function with an id
nodes.add('some-id', function (control, context) {

  // do something with the @input / context.input
  // it's the object provided to process()

  if // things are okay, move to the next node
    control.next('next-id')
  else
    control.fail('there was a problem')
})

nodes.add('next-id', function (control, context) {
  // do something ... and then move back to the first node
  control.next('some-id')
})

// Alternate way to add nodes as an object:
nodes.addAll({
  someId: function (control, context) {
    // same as the function used above
  },

  nextId: function (control, context) {
    // same as the function used above
  }
})

// first added node is the 'start' node by default.
//   OR:
// set it explicitly:
nodes.start('some-id')

// Alter flow with before/after nodes by specifying which nodes should
// be targeted and which nodes should be applied. works as it reads.
nodes.before('some id', 'another id').run('blah1', 'blah2', 'blah3')
nodes.after('diff id', 'id2', 'id3').run('blah4', 'blah5', 'blah6')

// A. For Object inputs:
var executor = nodes.objects()
executor.process({some:'input object'})

// B. For String inputs:
var executor = nodes.strings()
executor.process('some input')

// C. For Transforms:
// default transform has string input and object output
var transform = nodes.transform()

// control input/output with options:
  , transform = nodes.transform({
    // use Buffer instead of string
    decodeStrings: true,
    // allow string/buffer output instead
    readableObjectMode: false
  })

someSource.pipe(transform).pipe(someTarget);

// A2 / B2  Adding event system:
//   for these, the `control` will have an `events` property.
//
// set options' `events` to true to use the events.EventEmitter
var options = {events:true}
// or, set your own event emitter instance:
  , options = { events: yourEventEmitter }
// then create the usual executor with the options...  
  , executor = nodes.objects(options)
  , executor = nodes.strings(options)
```

## Example

A totally contrived example just to see some of the stuff working. It counts the repeated occurrences of characters.

```javascript
var nodes = require('stating')()

nodes.addAll({
  count: function (control) {

    // if we don't have any more input, then wait()
    if (this.index >= this.input.length) {
      return control.wait()
    }

    // continue where we left off, or, get the new character to count
    var ch = this.value ? this.value.ch : this.input[this.index]

    // count the occurrences of this character
    for (var index = this.index ; index < this.input.length; this.input[++index] == ch)
      ;

    // store our value, combine with where we left off, if it exists
    this.value = {
      type: ch,
      count: this.value ? this.value.count + (index - this.index) : (index - this.index)
    }

    // if we ran into the end of the input then wait for more.
    // otherwise, move to the 'use' node
    if (index == this.input.length) {
      control.wait()
    } else {
      control.next('use')
    }
  },

  use: function (control) {

    // use our value and then nullify it
    if (this.value) {
      console.log(this.value.type, '->', this.value.count)
      this.value = null
    }

    // go back to count another character
    control.next('count')
  }
})

var executor = nodes.strings()

// provide input in parts
executor.process('abc')
executor.process('cddeee')
executor.process('eefggghh')
executor.process('hhhhh')

// the same thing would happen if we passed it all as a single input:
executor.process('abccddeeeeefggghhhhh')

/* the result is the following output to the console:
a -> 1
b -> 1
c -> 2
d -> 2
e -> 5
f -> 1
g -> 3
h -> 7
*/
```

## MIT License
