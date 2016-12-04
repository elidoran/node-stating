Control = require './Control'

module.exports = class Stating

  constructor: (options) ->
    @reset options

  reset: (options = {}) ->
    @options = options
    @nodes = options.nodes ? {}
    @start = options.start

  start: (name) -> @start = name

  add: (id, node) ->

    if typeof id is 'function'
      node = id
      id = node.id ? node?.options.id

    unless node? then return error:'must specify a function'
    unless id? then return error:'must specify an `id`'

    @nodes[id] = node

    # first node added is the start by default...
    @start ?= id

    return this

  addAll: (object) ->
    for own id, node of object
      unless node? then return error:'must specify a function', id:id
      @nodes[id] = node
      @start ?= id

  #   builder.before('a', 'b').run('c', 'd')
  before: (names...) -> run: @_before.bind this, names

  #   builder.after('a', 'b').run('c', 'd')
  after : (names...) -> run: @_after.bind this, names

  _reversedArray: (array) ->
    if Array.isArray array[0] then array = array[0]

    front = 0
    tail = array.length - 1
    while front < tail
      temp = array[front]
      array[front] = array[tail]
      array[tail] = temp
      front++
      tail--

    return array

  _before: (names, beforeNames...) -> @_insert 'before', names, beforeNames
  _after : (names, afterNames... ) -> @_insert 'after', names, afterNames

  _insert: (which, names, others...) ->
    if Array.isArray names[0] then names = names[0]
    # reversed cuz we push them on a stack so, let's reverse them now
    others = @_reversedArray others
    # for each node to add the 'others' to...
    for name in names
      # get the node
      node = @nodes[name]
      # if the array exists already, splice these into the end
      if node[which]? then node[which].splice node[which].length, 0, others
      # otherwise, copy the array so it has its own
      else node[which] = others[..]


  objects: (options) ->
    control = new Control this, options
    @_events control, options
    return process: (input, done) -> control._process input, done


  strings: (options = {}) ->

    strings = require './string-input'

    if options.context?
      options.context.reset ?= strings.stringInputReset
      options.context.trim ?= strings.trim
    else
      options.baseContext ?= strings.baseContext

    control = new Control this, options

    @_events control, options

    return process: (input, done) -> control._process input, done


  transform: (options = {}) ->

    transformOptions = options.transform ? {}

    # default to data as strings and push()'ing objects?
    transformOptions.decodeStrings ?= false
    transformOptions.readableObjectMode ?= true

    # if we're dealing with strings, use some helpers
    if transformOptions.decodeStrings is false
      strings = require './string-input'
      if options.context?
        options.context.reset ?= strings.stringInputReset
        options.context.trim ?= strings.trim
      else
        options.baseContext ?= strings.baseContext

    # create the Control to use
    control = new Control this, options

    # define the transform() using the Control
    transformOptions.transform = (data, _, done) -> control._process data, done

    # create the Transform
    transform = new require('stream').Transform transformOptions

    # make the push() available on the context, but, put it in the prototype
    # so it isn't one of the context's "own" properties
    control._context.__proto__.push = transform.push.bind transform

    return transform

  _events: (control, options) ->

    if options?.events?
      if options.events is true
        control.events = new require('events').EventEmitter
      else
        control.events = options.events
