baseContext = reset: (input) -> @input = input
defaultDone = (error, result) ->
  if error? then throw new Error error
  return result

module.exports = class Control

  constructor: (stating, options = {}) ->
    # default context is an object with the input reset function
    @_context = options?.context ? Object.create options.baseContext ? baseContext

    @_next = [ stating.start ]
    @_nodes = stating.nodes

    @_beforesAdded = []

  fail: (reason, error) ->
    @_failed =
      reason : reason
      node   : @_node
      context: @_context
    if error? then @_failed.Error = error
    return

  next: (names...) ->

    # first, remove the node we're currently at
    @_next.pop()

    # push the specified next names in reverse order onto the next 'stack'.
    @_next.push name for name in names by -1

    # then do the same for the _after names so they'll be done *before* the next() ones.
    if @_node.after?.length > 0 then @_next.splice @_next.length, 0, @_node.after

    return


  wait: (info = true) -> @waiting = info


  _process: (data, done) ->

    if typeof data is 'function'
      done = data
      data = null

    else
      done ?= defaultDone

    @_context.reset data

    loop # the main processing loop. checks if it has input then calls next

      # 1. if we @_failed then tell done() and return
      if @_failed? then return done error:@_failed

      # 2. if we should wait for input, remove the marker and then return/done
      if @waiting?
        @waiting = null
        return done()

      # 3. get our next node's name. don't pop() until next() is called.
      nodeName = @_next[@_next.length - 1]
      @_node = @_nodes[nodeName]

      # 4. without a next node, send an error
      unless @_node? then return done error:'Missing next node: ' + nodeName

      # if the `node` has `before` nodes, then, add them to do first.
      # remember adding its 'before' names so we do it once.
      # they're stored in a stack so it gets pop()'d off when we get back to it.
      if @_node.before?.length > 0
        if @_beforesAdded[@_beforesAdded.length - 1] is nodeName
          @_beforesAdded.pop()
        else
          @_beforesAdded.push nodeName
          @_next.splice @_next.length, 0, @_node.before
          nodeName = @_next[@_next.length - 1]
          @_node = @_nodes[nodeName]

      # 5. call the node
      try
        @_node.call @_context, this, @_context
      catch error
        @fail 'Caught error', error

      # from here, we start back at the top of the loop.

    return
