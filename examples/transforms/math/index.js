// replace with require('stating')
var nodes = require('../../../lib/')()

console.log('example transforms/math')

nodes.addAll({

  start: function start(control) {
    if (!this.input) {
      control.wait()
    }

    else if (this.input.op) {
      control.next('op')
    }

    else if (this.input.value) {
      control.next('value')
    }

    else {
      this.error = 'unknown input'
      control.next('error')
    }
  },

  isOverwrite: function isOverwrite(control) {
    if (this.op) {
      this.error = 'overwriting op'
      control.next('error')
    } else {
      control.next()
    }
  },

  op: function op(control) {
    this.op = this.input.op
    this.input = null
    control.next()
  },

  value: function value(control) {
    this.values = this.values || []
    this.values.push(this.input.value)
    this.input = null
    control.next()
  },

  'ready?': function isReady(control) {
    if (this.op && this.values && this.values.length > 1) {
      control.next('calculate')
    } else {
      control.next('start')
    }
  },

  calculate: function calculate(control, context) {
    var result = this.values.reduce(function(acc, el) {
      if (acc) {
        return context.op(acc, el)
      } else {
        return el
      }
    })
    context.$push('result = ' + result + '\n')
    control.next('start')
  },

  reset: function reset(control) {
    this.input  = null
    this.op     = null
    this.values = null
    control.next()
  },

  error: function error(control) {
    control.fail(this.error)
    control.next()
  }

})

// ensure we start at 'count'
nodes.start('start')

// before setting the op, ensure we aren't overwriting the current op.
nodes.before('op').run('isOverwrite')

// after we get the op or value then check if we're ready to calculate.
nodes.after('op', 'value').run('ready?')

// after calculating a result or dealing with an error do reset.
nodes.after('calculate', 'error').run('reset')

// objects in and strings out...
var transform = nodes.transform({
  transform: {
    writableObjectMode: true,
    readableObjectMode: false,
  },
})

// show error in console...
transform.on('error', function errorHandler(error) {
  console.log('transform error:', error)
})

// show results in console
transform.pipe(process.stdout)

// prefix: sum 1 2
transform.write({ op: function sum(a, b) { return a + b } })
transform.write({ value: 1 })
transform.write({ value: 2 })

// suffix: 1 2 sum
transform.write({ value: 1 })
transform.write({ value: 2 })
transform.write({ op: function sum(a, b) { return a + b } })

// middle?: 1 plus 2
transform.write({ value: 1 })
transform.write({ op: function plus(a, b) { return a + b } })
transform.write({ value: 2 })

// more than 2 in suffix mode
transform.write({ value: 1 })
transform.write({ value: 2 })
transform.write({ value: 3 })
transform.write({ value: 4 })
transform.write({ value: 5 })
transform.write({ value: 6 })
transform.write({ value: 7 })
transform.write({ op: function sum(a, b) { return a + b } })


transform.end()
