defaultDone = (error, result) -> return error ? result

module.exports = class Control

  constructor: (stating, options) ->
    # default context is an object with the input reset function
    @_context = options?.context ? Object.create options?.baseContext

    # if direct then get the node otherwise store the name.
    @_next = if options?.direct then [ stating.nodes[stating._start] ] else [ stating._start ]
    @_nodes = stating.nodes

    @_beforesAdded = []
    @_prepareNext =
      if options?.direct is true then Control.prototype._prepareByNode
      else Control.prototype._prepareByName

    @_node = null
    @_after = null
    @_failed = null


  fail: (reason, error) ->
    @_failed =
      reason : reason
      node   : @_node
      context: @_context
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
    # console.log 'control.next:', next
    return


  wait: (info) -> @waiting = info ? true

  # _prepareNext is assigned either _prepareByName or _prepareByNode

  _process: (data, done) ->

    if typeof data is 'function'
      done = data
      data = null

    else
      done ?= defaultDone

    @_context.reset data

    loop # the main processing loop. checks if it has input then calls next

      # 1. if we @_failed then tell done() and return
      if @_failed? then return done @_failed

      # 2. if we should wait for input, remove the marker and then return/done
      if @waiting?
        @waiting = null
        return done()

      # 3. get the next node and call it
      @_call @_prepareNext done

    return

  _call: (node) ->
    try
      # TODO: stop providing the `this` and instead do:
      # node this, @_context
      node.call @_context, this, @_context
    catch error
      @fail 'Caught error', error

  _prepareByName: (done) ->

    # get our next node's name. don't pop() until next() is called.
    nodeName = @_next[@_next.length - 1]
    node = @_nodes[nodeName]

    # without a next node, send an error
    unless node? then return done error:'Missing next node: ' + nodeName

    # if the `node` has `before` nodes, then, add them to do first.
    # remember adding its 'before' names so we do it once.
    # they're stored in a stack so it gets pop()'d off when we get back to it.
    if node.before?.length > 0

      if @_beforesAdded[@_beforesAdded.length - 1] is node
        @_beforesAdded.pop()

      else
        @_beforesAdded.push node
        # @_next.splice @_next.length, 0, @_node.before
        @_next.push.apply @_next, node.before
        nodeName = @_next[@_next.length - 1]
        node = @_nodes[nodeName]

    @_node = node
    @_after = node.after
    return node


  _prepareByNode: (done) ->

    next = @_next

    # get our next node's name. don't pop() until next() is called.
    node = next[next.length - 1]

    # without a next node, send an error
    unless node? then return done error:'Missing next node'

    # if the `node` has `before` nodes, then, add them to do first.
    # remember adding its 'before' names so we do it once.
    # they're stored in a stack so it gets pop()'d off when we get back to it.
    if node.before?.length > 0

      if @_beforesAdded[@_beforesAdded.length - 1] is node
        @_beforesAdded.pop()

      else
        @_beforesAdded.push node
        # @_next.splice @_next.length, 0, @_node.before
        @_next.push.apply @_next, node.before
        node = @_next[@_next.length - 1]

    @_node = node
    @_after = node.after
    return node
