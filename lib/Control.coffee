NIL = {}
module.exports = class Control

  constructor: (stating, options) ->
    # default context is an object with the input reset function
    @_context = options?.context ? Object.create options?.baseContext ? null

    # start may be overridden by options, otherwise get it from `stating`
    @_start = options?.start ? stating._start

    # if direct then get the actual start node
    @_start = stating.nodes[@_start] if options?.direct

    # the queue, _next, begins with only our start node
    @_next = [ @_start ]
    @_nodes = stating.nodes

    @_beforesAdded = []
    @_prepareNext =
      if options?.direct is true then Control.prototype._prepareByNode
      else Control.prototype._prepareByName

    @_node = null
    @_after = null
    @_failed = null
    @waiting = null
    @_result = null


  _reset: ->
    @_failed = null
    @_node = null
    @_after = null
    @waiting = null
    @_result = null
    @_beforesAdded = []
    @_next = [ @_start ]
    @_context.$clear?()


  fail: (reason, error) ->
    context =
      if typeof @_context.$copy is 'function' then @_context.$copy()
      else Object.assign {}, @_context

    @_failed =
      reason : reason
      node   : @_node
      context: context

    if error? then @_failed.error = error
    return

  next: ->

    names = new Array arguments.length
    # NOTE: we're reversing the array as we assign it into `names`
    names[arguments.length - 1 - i] = arguments[i] for i in [0 ... arguments.length]

    # local alias
    next = @_next

    # first, remove the node we're currently at
    next.pop()

    # push the specified next names in reverse order onto the next 'stack'.
    if names.length > 0 then next.push.apply next, names

    # then do the same for the after names so they'll be done *before* the next() ones.
    if @_after?.length > 0 then next.push.apply next, @_after

    return

  wait: (info) ->
    @waiting = info ? 'waiting'
    return

  # must use separate result var because result can be `null`
  result: (value) ->
    @_result = value ? NIL
    return

  _process: (data, done) ->

    if done? then process.nextTick => @_begin data, done
    else @_begin data, (error, result) -> error ? result

  _begin: (data, done) ->

    if typeof data is 'function'
      done = data
      data = null

    @_context.$add data

    loop # the main processing loop. checks if it has input then calls next

      # 1. if we should wait for input, remove the marker and then return/done
      if @waiting?
        result = @waiting
        @waiting = null
        return done null, result

      # 2. if we want to return a result, remove the marker and then return/done
      # NOTE:
      #  this supports repeated sycnchronous calls to retrieve one value at
      #  a time. the main goal of `stating` is processing of chunks which
      #  can provide many values via a different outlet than the sycnchronous
      #  return value. but, it's useful for dev/testing/perf to do this too.
      if @_result?
        result = if @_result is NIL then null else @_result
        @_result = null
        return done null, result

      # 3. if we @_failed then tell done() and return
      if @_failed?
        result = @_failed
        @_failed = null
        # reset everything so we can start over.
        @_reset()
        # the `_failed` has the context in it for them.
        return done result

      # 4. get the next node and call it
      @_call @_prepareNext done


  _call: (node) ->
    unless node? then return
    try # TODO: stop providing the `this` and instead do: node this, @_context
      node.call @_context, this, @_context
    catch error
      @fail 'Caught error', error

  _prepareByName: ->

    next = @_next

    # get our next node's name. don't pop() until next() is called.
    console.log
    nodeName = next[next.length - 1]
    node = @_nodes[nodeName]

    # without a next node, send an error
    # unless node? then return done {error:'Missing next node: ' + nodeName}, null
    unless node? then return @fail 'missing next node: ' + nodeName

    # if the `node` has `before` nodes, then, add them to do first.
    # remember adding its 'before' names so we do it once.
    # they're stored in a stack so it gets pop()'d off when we get back to it.
    if node.before?.length > 0

      if @_beforesAdded[@_beforesAdded.length - 1] is node
        @_beforesAdded.pop()

      else
        @_beforesAdded.push node
        next.push.apply next, node.before
        nodeName = next[next.length - 1]
        node = @_nodes[nodeName]

    @_node = node
    @_after = node.after
    return node


  _prepareByNode: ->

    next = @_next

    # get our next node's name. don't pop() until next() is called.
    node = next[next.length - 1]

    # without a next node, send an error
    # unless node? then return done {error:'Missing next node'}, null
    unless node? then return @fail 'missing next node'

    # if the `node` has `before` nodes, then, add them to do first.
    # remember adding its 'before' names so we do it once.
    # they're stored in a stack so it gets pop()'d off when we get back to it.
    if node.before?.length > 0

      if @_beforesAdded[@_beforesAdded.length - 1] is node
        @_beforesAdded.pop()

      else
        @_beforesAdded.push node
        # @_next.splice @_next.length, 0, @_node.before
        next.push.apply next, node.before
        node = next[next.length - 1]

    @_node = node
    @_after = node.after
    return node
