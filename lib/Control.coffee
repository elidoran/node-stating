StatingError = require('./error')

module.exports = class Control

  constructor: (stating, options) ->
    # default context is an object with the input reset function
    @_context = options?.context ? Object.create options?.baseContext ? null

    # start may be overridden by options, otherwise get it from `stating`
    @_start = options?.start ? stating.nodes[stating._start]

    # the queue, _next, begins with only our start node
    @_nodes = stating.nodes

    @_node = null
    @_result = null
    @_error = null
    @_beforesAdded = []
    @_loop = true
    @_next = [ @_start ]


  _reset: ->
    @_node = null
    @_result = null
    @_error = null
    @_beforesAdded = []
    @_next = [ @_start ]
    @_context.$clear?()


  fail: (error, details) ->

    @_loop = false # stop processing

    if typeof error is 'string' then error = new StatingError error, details

    # copy details properties onto Error
    else if details?
      error[key] = value for key, value of details

    context =
      if typeof @_context.$copy is 'function' then @_context.$copy()
      else Object.assign {}, @_context

    error.node = @_node
    error.context = context

    @_error = error
    return

  wait: (info) ->
    @_loop = false # stop processing
    @_result = info ? 'waiting'
    return

  # must use separate result var because result can be `null`
  result: (value) ->
    @_loop = false # stop processing
    @_result = value
    return

  next: ->

    nodes = new Array arguments.length
    # NOTE: we're reversing the array as we assign it into `names`
    nodes[arguments.length - 1 - i] = arguments[i] for i in [0 ... arguments.length]

    # local alias
    next = @_next

    # first, remove the node we're currently at
    next.pop()

    # push the specified next names in reverse order onto the next 'stack'.
    if nodes.length > 0 then next.push.apply next, nodes

    # then do the same for the after names so they'll be done *before* the next() ones.
    if @_node.after?.length > 0 then next.push.apply next, @_node.after

    return

  _process: (data, done) ->

    if done? then process.nextTick => @_begin data, done
    else @_begin data, (error, result) -> error ? result

  _begin: (data, done) ->

    if typeof data is 'function'
      done = data
      data = null

    @_context.$add data

    @_loop = true
    @_error = @_result = null  # ensure we don't have stored result/error

    # the main processing loop. gets next node and calls it.
    # NOTE: isolates the try-catch in its own function because only the newest
    # node versions can optimize a function with a try-catch.
    @_call @_nextNode() while @_loop  # reset it to true at start

    # if they provided the callback then we're giving them the info as usual.
    # if they didn't, then it's the placeholder which returns either
    # the error, if it exists, or the result.
    done @_error, @_result


  _call: (node) ->
    unless node? then return @fail 'no next node to call'

    try
      node.call @_context, this, @_nodes, @_context
    catch error
      @fail error


  _nextNode: ->

    next = @_next

    # get our next node's name. don't pop() until next() is called.
    node = next[next.length - 1]

    # without a next node, send an error
    unless node? then return @fail 'no next node'

    # if the `node` has `before` nodes, then, add them to do first.
    # remember adding it so we do it once.
    # they're stored in a stack so it gets pop()'d off when we get back to it.
    if node.before?.length > 0

      if @_beforesAdded[@_beforesAdded.length - 1] is node
        @_beforesAdded.pop()

      else
        @_beforesAdded.push node
        next.push.apply next, node.before
        node = next[next.length - 1]

    @_node = node
    return node
