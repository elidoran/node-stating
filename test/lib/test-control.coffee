assert = require 'assert'

Control = require '../../lib/Control.coffee'

describe 'test control', ->

  it 'should reset', ->

    noop = ->
    control = new Control {nodes:{noop}, _start:'noop'}, {}

    control._reset()

    assert.equal control._failed, null
    assert.equal control._node, null
    assert.equal control._after, null
    assert.equal control.waiting, null
    assert.equal control._result, null
    assert.deepEqual control._beforesAdded, []
    assert.deepEqual control._next, [noop]


  it 'should record failure', ->

    context = some: 'context'
    control = new Control {nodes:{}, _start:'noop'}, context: context
    control._node = 'testing2'
    error = new Error 'cuz'
    control.fail error

    assert.equal control._failed.message, 'cuz'
    assert.equal control._failed.node, 'testing2'
    assert.notStrictEqual control._failed.context, context
    assert.deepEqual control._failed.context, context


  it 'should add details to failure error', ->

    context = some: 'context'
    control = new Control {nodes:{}, _start:'noop'}, context: context
    control._node = 'testing2'
    error = new Error 'cuz'
    control.fail error, extra: 'details'

    assert.equal control._failed.message, 'cuz'
    assert.equal control._failed.node, 'testing2'
    assert.notStrictEqual control._failed.context, context
    assert.deepEqual control._failed.context, context
    assert.equal control._failed.extra, 'details'

  it 'should use string to create failure error', ->

    control = new Control {nodes:{}, _start:'noop'}, context: {}
    control.fail 'message'
    assert.equal control._failed.message, 'message'

  it 'should accept a failure error w/out details', ->

    control = new Control {nodes:{}, _start:'noop'}, context: {}
    control.fail new Error 'blah'
    assert.equal control._failed.message, 'blah'


  it 'should use context $copy', ->

    context = some: 'context', $copy: -> some: 'copy'
    control = new Control {nodes:{}, _start:'noop'}, context: context
    control._node = 'testing2'
    error = new Error 'cuz'
    control.fail error, extra: 'testing'

    assert.equal control._failed.message, 'cuz'
    assert.equal control._failed.node, 'testing2'
    assert.notStrictEqual control._failed.context, context
    assert.deepEqual control._failed.context, some:'copy'
    assert.equal control._failed.extra, 'testing'


  it 'should function as done instead of data', ->

    calledData = {}
    add = (data) -> calledData = data
    control = new Control {nodes:{}, _start:'noop'}, context: $add: add
    control.fail 'testing'
    failed = control._failed
    calledError = calledResult = null
    done = (error) -> calledError = error
    control._begin done

    assert.equal calledData, null
    assert.deepEqual calledError, failed


  it 'should be capable of returning a null result', ->

    control = new Control {nodes:{}, _start:'noop'}, context: $add: ->
    control.result null
    assert.deepEqual control._result, {} # NIL is an empty object
    result = control._process()
    assert.strictEqual result, null

  it 'should error in _call() w/out node', ->

    control = new Control {nodes:{}, _start:'noop'}, context: {}
    control._call()
    assert.equal control._failed?.message, 'no next node to call'

  it 'should catch error in _call() when node throws', ->

    control = new Control {nodes:{}, _start:'noop'}, context: {}
    control._call -> throw 'error'
    assert.equal control._failed?.message, 'error'

  it 'should error in _prepareNext() w/out next node', ->

    control = new Control {nodes:{}, _start:'noop'}, context: {}
    control._prepareNext()
    assert control._failed?.message, 'no next node'
