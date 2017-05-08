flatten = require '@flatten/array'

Control = require './Control'

module.exports = class Stating

  constructor: (options) ->

    @nodes = options?.nodes ? Object.create null
    @_start = options?.start


  start: (name) -> @_start = name


  add: (id, node, init) ->

    if typeof id is 'function'
      node = id
      id = node.id ? node.options?.id

    unless typeof node is 'function' then return error:'must specify a function'
    unless typeof id is 'string' then return error:'must specify an `id`'

    @nodes[id] = node

    # first node added is the start by default...
    @_start ?= id

    if init is true then node.$IS_INIT = true

    return this


  addAll: (object, init) ->
    for own id, node of object
      unless typeof node is 'function'
        return error:'must specify a function', id:id
      @nodes[id] = node
      @_start ?= id
      if init is true then node.$IS_INIT = true


  #   builder.before('a', 'b').run('c', 'd')
  before: ->
    # optimization friendly method (splats use slice which isn't)
    names = new Array arguments.length
    names[i] = arguments[i] for i in [0 ... arguments.length]
    run: @_before.bind this, flatten names


  #   builder.after('a', 'b').run('c', 'd')
  after : ->
    # optimization friendly method (splats use slice which isn't)
    names = new Array arguments.length
    names[i] = arguments[i] for i in [0 ... arguments.length]
    run: @_after.bind this, flatten names


  # helper used by before()
  _before: (names) ->
    beforeNames = new Array arguments.length - 1
    # reverse them as we copy them into the array
    beforeNames[arguments.length - 1 - i] = arguments[i] for i in [1 ... arguments.length]
    @_insert 'before', names, flatten beforeNames


  # helper used by after()
  _after : (names) ->
    afterNames = new Array arguments.length - 1
    # reverse them as we copy them into the array
    afterNames[arguments.length - 1 - i] = arguments[i] for i in [1 ... arguments.length]
    @_insert 'after', names, flatten afterNames


  # helper used by _before() and _after()
  _insert: (which, names, others) ->

    # NOTE: `others` has already been reversed.
    # they're specified forward so it's readable and makes sense.
    # they're reversed now so we push them on the stack in
    # the proper order: LIFO

    # for each node to add the 'others' to...
    for name in names

      # get the node
      node = @nodes[name]

      unless node? then return error: 'unknown node name', name: name

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

    # if we're in direct mode then tell Control...
    if @_direct is true then options.direct = true

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

    # if we're in direct mode then tell Control...
    if @_direct is true then options.direct = true

    # create the Control to use
    control = new Control this, options

    # define the transform() using the Control
    transformOptions.transform = (data, _, next) -> control._process data, next

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

  # changes from referring to nodes by string (ID)
  # to referring to the nodes directly.
  direct: ->

    callbacks = []
    direct = (ids, callback) -> callbacks.push [ ids, callback ]

    # phase 1: replace all initializers with their nodes
    for id, node of @nodes

      # replace initializers with the result of running them
      if node.$IS_INIT is true
        # replace it
        @nodes[id] = node direct
        # remember the id
        @nodes[id].id = id
        # copy over the before/after node refs
        @nodes[id].before = node.before if node.before?
        @nodes[id].after  = node.after if node.after?


    # phase 2: provide the nodes via their callbacks
    for i in [0 ... callbacks.length]

      [ids, callback] = callbacks[i]

      # replace the desired ids with the actual nodes
      ids[i] = @nodes[id] for id, i in ids

      # call the callback with the desired nodes
      callback.apply null, ids

    # phase 3: replace the id's in before/after with the nodes
    for id, node of @nodes

      # replace before/after names with nodes their actual nodes
      if node.before? then node.before[i] = @nodes[id2] for id2, i in node.before
      if node.after?  then node.after[i]  = @nodes[id2] for id2, i in node.after

    # remember we're in "direct mode".
    @_direct = true

    return
