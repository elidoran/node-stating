builder = require('@stating/builder')({
  load: [ '@stating/string-plugin' ]
})

# Escape implementation adapted from Parsimmon. https://github.com/jneen/parsimmon
ESCAPE_REGEX = /\\(u[0-9a-fA-F]{4}|[^u])/
ESCAPES = Object.create null,
  b: value: '\b', configurable: false, writable: false, enumerable: true
  f: value: '\f', configurable: false, writable: false, enumerable: true
  n: value: '\n', configurable: false, writable: false, enumerable: true
  r: value: '\r', configurable: false, writable: false, enumerable: true
  t: value: '\t', configurable: false, writable: false, enumerable: true

escaper = (_, escape) ->
  type = escape[0]
  if type is 'u' then String.fromCharCode parseInt escape.slice(1), 16
  else ESCAPES[type] ? type

# yup, i know this allows invalid stuff.
NON_NUMBER_REX = /[^0-9\.eE+-]/g

NIL = {}

SPACE   = ' '.charCodeAt 0
TAB     = '\t'.charCodeAt 0
RETURN  = '\r'.charCodeAt 0
NEWLINE = '\n'.charCodeAt 0

DOT   = '.'.charCodeAt 0
COMMA = ','.charCodeAt 0
COLON = ':'.charCodeAt 0
PLUS  = '+'.charCodeAt 0
MINUS = '-'.charCodeAt 0

BIG_E = 'E'.charCodeAt 0
LIL_E = 'e'.charCodeAt 0

LEFT_BRACE    = '{'.charCodeAt 0
RIGHT_BRACE   = '}'.charCodeAt 0
LEFT_BRACKET  = '['.charCodeAt 0
RIGHT_BRACKET = ']'.charCodeAt 0
DOUBLE_QUOTE  = '"'.charCodeAt 0

ZERO  = '0'.charCodeAt 0
ONE   = '1'.charCodeAt 0
TWO   = '2'.charCodeAt 0
THREE = '3'.charCodeAt 0
FOUR  = '4'.charCodeAt 0
FIVE  = '5'.charCodeAt 0
SIX   = '6'.charCodeAt 0
SEVEN = '7'.charCodeAt 0
EIGHT = '8'.charCodeAt 0
NINE  = '9'.charCodeAt 0

N = 'n'.charCodeAt 0
U = 'u'.charCodeAt 0
L = 'l'.charCodeAt 0
T = 't'.charCodeAt 0
R = 'r'.charCodeAt 0
E = LIL_E
F = 'f'.charCodeAt 0
A = 'a'.charCodeAt 0
S = 's'.charCodeAt 0

# TODO:
#  when building up a string to use
#  instead of concatenating the parts when we have to wait
#  build up an array of individual strings.
#  then join() them when we have them all.

# TODO:
#  check strings to see if they are encoded Date values

module.exports =

  start: (control, $) -> control.next $.value, $.send, $.start


  send: (control) ->
    value = @value
    @value = null
    control.result if value is NIL then null else value
    control.next()


  value: (control, $) ->

      switch @code()

        when LEFT_BRACE
          @next() # increment by at least one, consume space
          @pushObject()
          control.next $.pair#, rightBrace # TODO: shorten as i did with array...

        when LEFT_BRACKET
          @next() # increment by at least one, consume space
          @pushArray()
          control.next $.element

        when DOUBLE_QUOTE
          @index++
          control.next $.notQuote, $.stringValue

        # stopped enforcing perfectly valid number format.
        # grab a glob of characters allowed in a number at least once
        # and convert that to a Number.
        # for valid numbers it works.
        # for strangely invalid strings, such as having extra dots or e's,
        # it will produce NaN.  like:  12.436.236e-1e+1
        # i'm okay with that. just don't input weird invalid numbers...
        when PLUS
          @string = ''
          @index++
          control.next $.number

        when MINUS
          @string = '-'
          @index++
          control.next $.number

        when ZERO
          @index++
          @string = '0'
          control.next $.number

        when ONE
          @string = '1'
          @index++
          control.next $.number

        when TWO
          @string = '2'
          @index++
          control.next $.number

        when THREE
          @string = '3'
          @index++
          control.next $.number

        when FOUR
          @string = '4'
          @index++
          control.next $.number

        when FIVE
          @string = '5'
          @index++
          control.next $.number

        when SIX
          @string = '6'
          @index++
          control.next $.number

        when SEVEN
          @string = '7'
          @index++
          control.next $.number

        when EIGHT
          @string = '8'
          @index++
          control.next $.number

        when NINE
          @string = '9'
          @index++
          control.next $.number


        when T

          if @has 4 and @ch(1) is R and @ch(2) is U and @ch(3) is E

            @to @index + 4
            @value = true
            control.next()

          else
            control.next $.true # TODO: change next node to 'rue'

        when F

          if @has 5 and @ch(1) is A and @ch(2) is L and @ch(3) is S and @ch(4) is E

            @to @index + 5
            @value = false
            control.next()

          else
            control.next $.false # TODO: change next node to 'alse'

        when N

          if @has 4 and @ch(1) is U and @ch(2) is L and @ch(3) is L

            @to @index + 4
            @value = NIL
            control.next()

          else
            control.next $.nil # TODO: change next node to 'ull'

        else
          console.log 'invalid char:', @input[@index], @code(), N
          control.fail 'invalid character'


  string: (control, $) ->

      if @consumeSpace() and @empty() then control.wait 'wait in string'

      else if @code() is DOUBLE_QUOTE
        @index++
        control.next $.notQuote

      else control.fail 'double quote required'

  notQuote: (control) ->

    if @empty() then return control.wait 'wait in !"'

    # start with an empty string
    @string ?= ''

    index = -1
    for i in [@index ... @input.length]
      if DOUBLE_QUOTE is @input.charCodeAt i
        index = i
        break
    # index = @input.indexOf '"', @index

    if index > -1
      # NOTE: this escapes some characters like Parsimmon does.
      # it's turned off for now to compare to Chevrotain which doesn't escape.
      # string = @string + @input[@index ... index]
      # @string = string.replace ESCAPE_REGEX, escaper

      @string += @input[@index ... index]

      # consume the closing double quote and any space after it
      @to index + 1
      control.next()

    else
      @string += @input[@index ... ]
      @index = @input.length
      control.wait 'wait in !"'


  stringValue: (control) ->

    if @string?
      @value = @string
      @string = null
      control.next()

    else control.fail 'incomplete string'


  number: (control) ->

    if @empty() then return control.wait 'wait in number'

    @string ?= ''

    NON_NUMBER_REX.lastIndex = @index
    result = NON_NUMBER_REX.exec @input

    if result?
      @value = Number @string + @input[@index ... result.index]
      @string = null
      @to result.index
      control.next()

    else # not yet in the input
      @string += @input[@index ... ]
      @index = @input.length
      control.wait 'wait in number'


  true : builder.string 'true' , -> @to @index + 4 ; @value = true  ; control.next()
  false: builder.string 'false', -> @to @index + 5 ; @value = false ; control.next()
  nil  : builder.string 'null' , -> @to @index + 4 ; @value = NIL   ; control.next()


  pair: (control, $) ->

      if @code() is RIGHT_BRACE

        if @object?
          @value = @object
          @popObject()
          @next()
          control.next()

        else control.fail '\'}\' without object'

      else control.next $.string, $.key, $.value, $.pairComma


  key: (control, $) ->

      if @string?
        @key = @string  # NOTE: @pushObject() handles recursion for @key
        @string = null

        # !" node already consumed space after the string for the key.
        if @code() is COLON
          @next() # consume colon and any space
          control.next()

        # else go to the colon node
        else control.next $.colon

      else control.fail 'string required for key'


  'colon': (control) ->

    if @consumeSpace() and @empty() then control.wait 'wait for colon'

    else if @code() is COLON
      @next() # increment by at least one, consume space
      control.next()

    else
      control.fail '\':\' required'


  'pairComma': (control, $) ->

      if @consumeSpace() and @empty() then return control.wait 'wait in "pair ,"'

      # handle assign here
      unless @key? then return control.fail 'key required for assign'
      unless @value? then return control.fail 'value required for assign'

      @object[@key] = if @value is NIL then null else @value
      @value = null

      # key node or colon node already consumed space after the colon
      switch @code()

        when COMMA
          @next() # increment by at least one, consume space
          control.next $.string, $.key, $.value, $.pairComma

        # handle right brace here
        when RIGHT_BRACE

          if @object?
            @value = @object
            @popObject()
            @next()
            control.next()

          else control.fail '\'}\' without object'

        else control.fail 'invalid character, should be either comma or right brace'


  # an element is any value, push into array, check for comma for more
  element: (control, $) ->

      @consumeSpace()

      if @empty() then control.wait 'wait in element'

      else if @code() is RIGHT_BRACKET
        @next()
        control.next()

        if @array?
          @value = @array
          @popArray()

        else return control.fail '\']\' without array'

      else control.next $.value, $.elementComma


  elementComma: (control, $) ->

      @consumeSpace()

      if @empty() then return control.wait()

      # push the value
      element = @value
      @value = null

      if element?
        @array[@array.length] = if element is NIL then null else element

      else
        return control.fail 'value required for push'


      switch @code()

        when COMMA
          @next() # increment by at least one, consume space
          control.next $.value, $.elementComma # element

        when RIGHT_BRACKET
          @next()
          control.next()

          if @array?
            @value = @array
            @popArray()

          else return control.fail '\']\' without array'

        else control.fail 'invalid character, should be either comma or right bracket'
