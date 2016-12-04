{Transform} = require 'stream'
assert = require 'assert'
buildBuilder = require '../../lib'

describe 'test objects()', ->

  greetings = []

  builder = buildBuilder()

  builder.add 'exists', (control) ->
    if @input? then control.next 'has-props'
    else control.fail 'input missing'

  builder.add 'has-props', (control) ->
    if not @input.greeting? then control.fail 'greeting missing'
    else if not @input.name? then control.fail 'name missing'
    else control.next 'greet'

  builder.add 'greet', (control) ->
    greetings.push @input.greeting + ' ' + @input.name
    control.wait()
    control.next 'exists'

  stator = builder.objects()

  results = []

  results.push stator.process greeting:input[0], name:input[1] for input in [
    [ 'Hiya', 'there' ]
    [ 'Hello', 'John' ]
    [ 'Hola', 'amigo' ]
  ]

  it 'should not error in process 1', -> assert.equal results[0]?.error, undefined
  it 'should not error in process 2', -> assert.equal results[1]?.error, undefined
  it 'should not error in process 3', -> assert.equal results[2]?.error, undefined

  it 'should receive greeting 1', -> assert.equal greetings[0], 'Hiya there'
  it 'should receive greeting 2', -> assert.equal greetings[1], 'Hello John'
  it 'should receive greeting 3', -> assert.equal greetings[2], 'Hola amigo'


describe 'test strings()', ->

  describe 'with key value pairs, before, and after', ->

    # add a 'which' node for alpha|num, then it sends to num-value or text-value
    # can do control.next 'num-value', 'key' which 'key' stores it as @key
    # or, put a marker in there telling num-value and text-value what to store
    # it as... or, 'key' always gets @string and stores it as @key instead
    # then, value,

    builder = buildBuilder()

    builder.add 'key', (control) ->
      # it's possible to use a reusable node which ensures there is content.
      # also, possible to have one which gets all alpha possible
      # then, 'key' can just take @input[@start..@index] and do its thing.
      # or, it could store it into @text with @index after it. hmm.
      # console.log 'key node',@alpha
      @key = @alpha
      control.next 'equal-sign'

    builder.add 'equal-sign', (control) -> # TODO: allow a colon as well
      # console.log 'equal-sign node'
      if @index >= @input.length then return control.wait()
      if @input[@index] is '='
        control.next 'value'
        @index++
      else control.fail 'not equal sign'

    builder.add 'alpha', (control) ->
      # console.log 'alpha node',@index,@input
      if @index >= @input.length then return control.wait()
      start = @index
      end = start
      end++ while 'a' <= @input[end] <= 'z' or 'A' <= @input[end] <= 'Z'

      unless end > start or @key? then return control.fail 'letters required'

      @index = end
      @alpha =
        if @alpha?.length > 0 then @alpha + @input[start...end]
        else @input[start...end]

      # if we're at the end of the input then we haven't hit an '=', so,
      # we should wait() for more input, store what we have so far.
      if end is @input.length then control.wait()
      else control.next()

    builder.before('key').run('alpha')

    objects = []

    builder.add 'value', (control) ->
      objects.push key:@key, value:@number
      @key = null
      @alpha = null
      @number = null
      control.next 'separator'

    builder.add 'number', (control) ->
      if @index >= @input.length then return control.wait()
      start = @index
      end = start
      end++ while '0' <= @input[end] <= '9'

      unless end > start or @key? then return control.fail 'digits required'

      @index = end
      @number =
        if @number? then @number + Number @input[start...end]
        else Number @input[start...end]

      # if we're at the end of the input then we haven't hit an '=', so,
      # we should wait() for more input, store what we have so far.
      if end is @input.length then control.wait()
      else control.next()

    builder.before('value').run('number')

    allowed = [',',' ','\n','\r','\t']
    builder.add 'separator', (control) ->
      if @index >= @input.length then return control.wait()
      if @input[@index] in allowed
        control.next 'key'
        @index++
      else control.fail('comma or whitespace required')


    string = 'num=1,numTwo=23 numThree=456\nnumberFour=7890\n'

    stator = builder.strings()

    # give it the whole string at once...
    result = stator.process string

    strings = [
      string[..3]
      string[4..8]
      string[9]
      string[10..14]
      string[15..24]
      string[25..37]
      string[38..]
    ]

    results = []

    results.push stator.process input for input in strings

    # console.dir results, colors:true
    # console.dir objects, colors:true

    it 'should not error', -> assert.equal result?.error, undefined

    it 'should not error process 1', -> assert.equal results[0]?.error, undefined
    it 'should not error process 2', -> assert.equal results[1]?.error, undefined
    it 'should not error process 3', -> assert.equal results[2]?.error, undefined
    it 'should not error process 4', -> assert.equal results[3]?.error, undefined
    it 'should not error process 5', -> assert.equal results[4]?.error, undefined
    it 'should not error process 6', -> assert.equal results[5]?.error, undefined
    it 'should not error process 7', -> assert.equal results[6]?.error, undefined

    it 'should provide object 1', ->
      assert.deepEqual objects[0], key:'num', value:1

    it 'should provide object 2', ->
      assert.deepEqual objects[1], key:'numTwo', value:23

    it 'should provide object 3', ->
      assert.deepEqual objects[2], key:'numThree', value:456

    it 'should provide object 4', ->
      assert.deepEqual objects[3], key:'numberFour', value:7890

    it 'should provide object 5', ->
      assert.deepEqual objects[4], key:'num', value:1

    it 'should provide object 6', ->
      assert.deepEqual objects[5], key:'numTwo', value:23

    it 'should provide object 7', ->
      assert.deepEqual objects[6], key:'numThree', value:456

    it 'should provide object 8', ->
      assert.deepEqual objects[7], key:'numberFour', value:7890
