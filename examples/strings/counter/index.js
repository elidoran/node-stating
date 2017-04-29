// replace with require('stating')
var nodes = require('../../../lib/')()

console.log('example strings/counter')

// add our two nodes
nodes.addAll({

  count: function count(control) {

    if (!this.input || this.input.length < 1) {
      return control.next(this.value.count > 0 ? 'use' : 'stop')
    } else {
      this.input = this.trim(0, this.input.length - 1)
    }

    // if we don't have any more input, then wait()
    if (this.index >= this.input.length) {
      return control.wait()
    }

    // continue where we left off, or, get the new character to count
    var ch = this.value.ch ? this.value.ch : this.input[this.index]

    // count the occurrences of this character
    for (var index = 1 + this.index; index < this.input.length && this.input[index] === ch; index += 1)
      /* all work is defined in the for-loop */ ;

    // store our value, combine with where we left off, if it exists
    this.value.ch = ch
    this.value.count += (index - this.index)

    this.index = index

    // if we ran into the end of the input then wait for more.
    // otherwise, move to the 'use' node
    if (index >= this.input.length) {
      control.wait()
    } else {
      control.next('use')
    }
  },

  use: function use(control, context) {

    // use our value
    console.log(context.value.ch, '->', context.value.count)

    // then reset it
    this.value.ch = null
    this.value.count = 0

    // go back to count another character
    control.next('count')
  },

  stop: function stop(control) {

    if (this.input && this.input.length > 0) {
      control.next('count')
    } else {
      control.wait()
    }
  }

})

// ensure we start at 'count'
nodes.start('count')

// build an "executor" which will accept strings
// and use the specified context.
// the context has a custom `reset` function,
// and default values for the properties used.
var executor = nodes.strings({
  context: Object.create(
    { // prototype for the context has reset()
      reset: function reset(input) {
        this.input = input
        this.index = 0
      },
      trim: require('../../../lib/string-input').trim
    },
    { // provide properties we'll use
      index: {
        value: 0,
        writable: true,
        enumerable: true,
        configurable: false,
      },
      input: {
        value: null,
        writable: true,
        enumerable: true,
        configurable: false,
      },
      value: {
        value: { ch: null, count: 0 },
        writable: false,
        enumerable: true,
        configurable: false,
      }
    }
  )
})

var input = (function() {
  var index = process.argv.indexOf('--input')
  if (index > -1 && index + 1 < process.argv.length) {
    return process.argv[index + 1]
  }
})()

if (input) {

  executor.process(input)

} else {

  // process multiple strings provided separately
  executor.process(' abc')
  executor.process('cddeee ')
  executor.process(' eefggghh ')
  executor.process('hhhhh')
  // it's waiting for more input before reporting
  // the count of 'h'.
  // so, tell it to finish up:
  executor.process(null)

  console.log('')

  // do the same thing again all as one string.
  // it will move back to 'count' from 'stop'
  // and begin counting.
  executor.process('abccddeeeeefggghhhhhhh')
  executor.process(null)

  // both of the first series and the last all-in-one produce:
  /*
  a -> 1
  b -> 1
  c -> 2
  d -> 2
  e -> 5
  f -> 1
  g -> 3
  h -> 7
  */

}
