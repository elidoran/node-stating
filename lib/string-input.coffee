# this avoids doing:  @input[first..last].trim()
# because that creates a substring and then may create a second substring.
# this way, we create one substring, the one we want.
exports.trim = (first, last) ->
  first++ while @input[first] is ' '
  last-- while @input[last] is ' '
  @input[first..last]

exports.stringInputReset = (input) ->
  @input =
    if @input?.length > 0 and @index < @input.length then @input[@index..] + input
    else input
  @index = 0
  return

exports.baseContext = reset:exports.stringInputReset, trim:exports.trim
