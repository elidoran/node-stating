var build, context, nodes, states, executor

// build a nodes instace
build   = require('../../../lib')
context = require('./context.coffee')
nodes   = require('./nodes.coffee')

states  = build()

// add all the nodes as "init" nodes
states.addAll(nodes, true)

// ensure we start at 'start'
states.start('start')

// create a strings executor with our custom context
executor = states.strings({
  context: context
})

module.exports = function parse(input) {
  return executor.process(input)
}
