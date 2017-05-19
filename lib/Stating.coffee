flatten = require '@flatten/array'

Control = require './Control'

module.exports = class Stating

  constructor: (options) ->

    @nodes = options?.nodes ? Object.create null
    @_start = options?.start


  start: (name) -> @_start = name


  add: (id, node) ->

    if typeof id is 'function'
      node = id
      id = node.id ? node.options?.id

    unless typeof node is 'function' then return error:'must specify a function'
    unless typeof id is 'string' then return error:'must specify an `id`'

    @nodes[id] = node
    node.id ?= id

    # first node added is the start by default...
    @_start ?= id

    return this


  addAll: (object) ->
    for own id, node of object
      unless typeof node is 'function'
        return error:'must specify a function', id:id
      @nodes[id] = node
      node.id ?= id
      @_start ?= id


  #   builder.before('a', 'b').run('c', 'd')
  before: ->
    # optimization friendly method (splats use slice which isn't)
    nodes = new Array arguments.length
    nodes[i] = @nodes[arguments[i]] for i in [0 ... arguments.length]
    run: @_before.bind this, flatten nodes


  #   builder.after('a', 'b').run('c', 'd')
  after : ->
    # optimization friendly method (splats use slice which isn't)
    nodes = new Array arguments.length
    for i in [0 ... arguments.length]
      nodes[i] = @nodes[arguments[i]]
    run: @_after.bind this, flatten nodes


  # helper used by before()
  _before: (nodes) ->
    beforeNodes = new Array arguments.length - 1
    # reverse them as we copy them into the array
    for i in [1 ... arguments.length]
      beforeNodes[arguments.length - 1 - i] = @nodes[arguments[i]]
    @_insert 'before', nodes, flatten beforeNodes


  # helper used by after()
  _after : (nodes) ->
    afterNodes = new Array arguments.length - 1
    # reverse them as we copy them into the array
    for i in [1 ... arguments.length]
      afterNodes[arguments.length - 1 - i] = @nodes[arguments[i]]
    @_insert 'after', nodes, flatten afterNodes


  # helper used by _before() and _after()
  _insert: (which, nodes, others) ->

    # NOTE: `others` has already been reversed.
    # they're specified forward so it's readable and makes sense.
    # they're reversed now so we push them on the stack in
    # the proper order: LIFO

    # for each node to add the 'others' to...
    for node in nodes

      unless typeof node is 'function'
        return error: 'invalid node', node: node

      # if the array exists already, splice these into the end
      array = node[which]

      if array? then array.push.apply array, others

      # otherwise, copy the array so it has its own
      else node[which] = others.slice(0, others.length)

    return


  # helper used by objects(), buffers(), and strings()
  _create: (opts, contexter) ->
    options = opts ? Object.create null

    unless options.context?
      options.baseContext ?= require(contexter).baseContext

    control = new Control this, options

    @_events control, options

    process: (input, done) -> control._process input, done
    control: control


  # only cares about `input`.
  objects: (opts) -> @_create opts, './object-input'

  # has both `input` and `index`
  buffers: (opts) -> @_create opts, './buffer-input'

  # has both `input` and `index`,
  # and, has trim() to get a trimmed string in one step.
  strings: (opts) -> @_create opts, './string-input'


  # creates a transform ready to process objects, strings, or buffers
  # depending on its options.
  transform: (opts) ->

    options = opts ? Object.create null

    transformOptions = options.transform ? Object.create null

    # default to data as strings and push()'ing objects?
    transformOptions.decodeStrings ?= false
    transformOptions.readableObjectMode ?= true

    # if we're dealing with strings, use some helpers
    if transformOptions.decodeStrings is false
      # if they set the context then it's on them.
      unless options.context?
        # otherwise, we can conditionally set the baseContext for them.
        options.baseContext ?= require('./string-input').baseContext

    # create the Control to use
    control = new Control this, options

    # define the transform() using the Control
    transformOptions.transform = (data, _, next) ->
      # don't pass on a `result` when wait() sends its wait reason...
      # only pass on an `error`
      control._process data, (error) -> next error

    # create the Transform
    transform = new require('stream').Transform transformOptions

    # whatever the context ended up being it must be able to
    # push to the transform. so, define a function.
    Object.defineProperty control._context, '$push',
      enumerable: false
      configurable: false
      writable: false
      value: (value) -> transform.push value

    return transform


  # helper used by _create to conditionally add `events`
  _events: (control, options) ->

    if options?.events?

      if options.events is true
        control.events = new require('events').EventEmitter

      else if options.events isnt false
        control.events = options.events
