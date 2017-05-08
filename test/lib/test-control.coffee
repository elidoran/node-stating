assert = require 'assert'

Control = require '../../lib/Control.coffee'

describe 'test control', ->

  it 'should reset', ->

    control = new Control {nodes:{}, _start:'noop'}, {}

    control._reset()

    assert.equal control._failed, null
    assert.equal control._node, null
    assert.equal control._after, null
    assert.equal control.waiting, null
    assert.equal control._result, null
    assert.deepEqual control._beforesAdded, []
    assert.deepEqual control._next, ['noop']


  it 'should record failure', ->

    context = some: 'context'
    control = new Control {nodes:{}, _start:'noop'}, context: context
    control._node = 'testing2'
    error = new Error 'cuz'
    control.fail 'testing', error

    assert.equal control._failed.reason, 'testing'
    assert.equal control._failed.node, 'testing2'
    assert.equal control._failed.error, error
    assert.notStrictEqual control._failed.context, context
    assert.deepEqual control._failed.context, context


  it 'should use context $copy', ->

    context = some: 'context', $copy: -> some: 'copy'
    control = new Control {nodes:{}, _start:'noop'}, context: context
    control._node = 'testing2'
    error = new Error 'cuz'
    control.fail 'testing', error

    assert.equal control._failed.reason, 'testing'
    assert.equal control._failed.node, 'testing2'
    assert.equal control._failed.error, error
    assert.notStrictEqual control._failed.context, context
    assert.deepEqual control._failed.context, some:'copy'


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
