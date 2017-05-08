assert = require 'assert'

bufferInput = require '../../lib/buffer-input.coffee'
stringInput = require '../../lib/string-input.coffee'
objectInput = require '../../lib/object-input.coffee'

describe 'test buffer addByConcat', ->

  it 'should update input and index', ->

    context =
      input: Buffer.from 'start'
      index: 5
      $add : bufferInput.addByConcat

    buffer = Buffer.from 'testing'
    context.$add buffer

    assert.equal context.index, 0
    assert.equal context.input, buffer

  it 'should concat input', ->

    context =
      input: Buffer.from 'start'
      index: 2
      $add : bufferInput.addByConcat

    buffer = Buffer.from 'testing'
    context.$add buffer

    assert.equal context.index, 0
    assert.notEqual context.input, buffer
    assert.deepEqual context.input, Buffer.from 'arttesting'


describe 'test buffer addByBufferList', ->

  it 'should update input and index', ->

    context =
      input: Buffer.from 'start'
      index: 5
      $add : bufferInput.addByBufferList

    buffer = Buffer.from 'testing'
    context.$add buffer

    assert.equal context.index, 0
    assert.equal context.input, buffer

  it 'should combine input in bl', ->

    context =
      input: Buffer.from 'start'
      index: 2
      $add : bufferInput.addByBufferList

    buffer = Buffer.from 'testing'
    context.$add buffer

    assert.equal context.index, 0
    assert.notEqual context.input, buffer
    assert.deepEqual context.input.toString(), 'arttesting'


describe 'test string add', ->

  it 'should update input and index', ->

    context =
      input: 'start'
      index: 5
      $add : stringInput.stringInputAdd

    context.$add 'testing'

    assert.equal context.index, 0
    assert.equal context.input, 'testing'

  it 'should combine input', ->

    context =
      input: 'start'
      index: 2
      $add : stringInput.stringInputAdd

    context.$add 'testing'

    assert.equal context.index, 0
    assert.equal context.input, 'arttesting'
