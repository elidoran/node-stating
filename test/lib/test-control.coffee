assert = require 'assert'

Control = require '../../lib/Control.coffee'

describe 'test control', ->

  it 'should reset', ->

    noop = ->
    control = new Control {nodes:{noop}, _start:'noop'}, {}

    control._reset()

    assert.equal control._error, null
    assert.equal control._node, null
    assert.equal control._after, null
    assert.equal control._loop, true
    assert.equal control._result, null
    assert.equal control._error, null
    assert.deepEqual control._beforesAdded, []
    assert.deepEqual control._next, [noop]


  it 'should record failure', ->

    context = some: 'context'
    control = new Control {nodes:{}, _start:'noop'}, context: context
    control._node = 'testing2'
    error = new Error 'cuz'
    control.fail error

    assert.equal control._error.message, 'cuz'
    assert.equal control._error.node, 'testing2'
    assert.notStrictEqual control._error.context, context
    assert.deepEqual control._error.context, context


  it 'should add details to failure error', ->

    context = some: 'context'
    control = new Control {nodes:{}, _start:'noop'}, context: context
    control._node = 'testing2'
    error = new Error 'cuz'
    control.fail error, extra: 'details'

    assert.equal control._error.message, 'cuz'
    assert.equal control._error.node, 'testing2'
    assert.notStrictEqual control._error.context, context
    assert.deepEqual control._error.context, context
    assert.equal control._error.extra, 'details'

  it 'should use string to create failure error', ->

    control = new Control {nodes:{}, _start:'noop'}, context: {}
    control.fail 'message'
    assert.equal control._error.message, 'message'

  it 'should accept a failure error w/out details', ->

    control = new Control {nodes:{}, _start:'noop'}, context: {}
    control.fail new Error 'blah'
    assert.equal control._error.message, 'blah'


  it 'should use context $copy', ->

    context = some: 'context', $copy: -> some: 'copy'
    control = new Control {nodes:{}, _start:'noop'}, context: context
    control._node = 'testing2'
    error = new Error 'cuz'
    control.fail error, extra: 'testing'

    assert.equal control._error.message, 'cuz'
    assert.equal control._error.node, 'testing2'
    assert.notStrictEqual control._error.context, context
    assert.deepEqual control._error.context, some:'copy'
    assert.equal control._error.extra, 'testing'


  it 'should use function as done instead of data', ->

    calledData = {}
    add = (data) -> calledData = data
    noop = (control) -> control.result 'testing'
    control = new Control {nodes:{noop}, _start:'noop'}, context: $add: add
    calledError = calledResult = null
    done = (error, result) -> calledError = error ; calledResult = result
    control._begin done

    assert.equal calledData, null
    assert.equal calledError, null
    assert.deepEqual calledResult, 'testing'


  it 'should be capable of returning a null result', ->

    noop = (control) -> control.result null
    control = new Control {nodes:{noop}, _start:'noop'}, context: $add: ->
    result = control._process()
    assert.strictEqual result, null

  it 'should error in _call() w/out node', ->

    control = new Control {nodes:{}, _start:'noop'}, context: {}
    control._call()
    assert.equal control._error?.message, 'no next node to call'

  it 'should catch error in _call() when node throws', ->

    control = new Control {nodes:{}, _start:'noop'}, context: {}
    control._call -> throw 'error'
    assert.equal control._error?.message, 'error'

  it 'should error in _nextNode() w/out next node', ->

    control = new Control {nodes:{}, _start:'noop'}, context: {}
    control._nextNode()
    assert control._error?.message, 'no next node'
