# this avoids doing:  @input[first..last].trim()
# because that's two steps:
# 1. it gets a substring via @input[first...last]
# 2. it calls trim() which would create a second substring.
# this way, we create one substring, the one we want.
exports.trim = (first, last) ->
  first++ while @input[first] is ' '
  last-- while @input[last] is ' '
  @input[first..last]

exports.stringInputAdd = (input) ->
  @input =
    if @input?.length > 0 and @index < @input.length then @input[@index..] + input
    else input
  @index = 0
  return

exports.baseContext =
  $add: exports.stringInputAdd
  trim : exports.trim
  input: null
  index: 0
