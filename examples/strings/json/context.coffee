prop = (v, w) -> value:v, configurable:false, enumerable:true, writable:w

NON_SPACE = /[^ \t\r\n]/mg

proto = # prototype for the context has helper functions

  $add: (input) ->
    unless input is null

      @input =
        if @input? and @index < @input.length then @input[@index ... ] + input
        else input

      @index = 0

  $copy: ->

    copy = Object.assign {}, this

    # deep copy arrays
    copy.objects = @objects.slice()
    copy.arrays  = @arrays.slice()
    copy.keys    = @keys.slice()

    return copy

  $clear: ->
    @input  = null
    @index  = 0
    @value  = null
    @key    = null
    @string = null
    @object = null
    @array  = null
    @start  = -1
    @objects.length = 0
    @arrays.length  = 0
    @keys.length    = 0

  code: -> @input.charCodeAt @index

  has: (amount) -> @index + amount <= @input.length

  ch: (i) -> @input.charCodeAt @index + i

  pushObject: ->
    if @object? then @objects[@objects.length] = @object
    if @key?    then @keys[@keys.length] = @key

    @object = {}
    @key = null
    return

  pushArray: ->
    if @array? then @arrays[@arrays.length] = @array
    @array = []
    return

  popObject: ->
    @object = @objects.pop()
    @key = @keys.pop()
    return

  popArray: -> @array = @arrays.pop() ; return

  next: -> @to @index + 1

  to: (index) ->
    NON_SPACE.lastIndex = index
    result = NON_SPACE.exec @input
    # if it found a non-space then go to that index,
    # else, go to the end of the input
    @index = if result? then result.index else @input.length
    return

  consumeSpace: ->
    NON_SPACE.lastIndex = @index
    result = NON_SPACE.exec @input
    # if it found a non-space then go to that index,
    # else, go to the end of the input
    @index = if result? then result.index else @input.length
    return true

  empty: -> @index >= @input.length


props = # provide properties we'll use
  index  : prop 0, true
  input  : prop null, true
  value  : prop null, true
  string : prop null, true
  key    : prop null, true
  object : prop null, true
  array  : prop null, true
  start  : prop -1, true
  objects: prop [], false
  arrays : prop [], false
  keys   : prop [], false

# create the context with our proto+props
context = Object.create proto, props

module.exports = context
