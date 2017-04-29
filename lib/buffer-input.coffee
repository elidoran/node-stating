# option 1: make a combined buffer
exports.resetByConcat = (input) ->
  # console.log 'resetByConcat'
  @input =
    # if there's some bytes leftover in the current buffer
    if @input?.length > 0 and @index < @input.length

      Buffer.concat [
        @input.slice @index, @input.length
        input
      ], (input.length + @input.length) - @index

    else input

  @index = 0
  # console.log @index, @input.length
  return


# option 2: combine via package `bl` (buffer list)
exports.resetByBufferList = (input) ->

  @input =
    # if there's some bytes leftover in the current buffer
    if @input?.length > 0 and @index < @input.length

      bl = new (reqire('bl'))
      bl.append @input.slice index, @input.length
      bl.append input
      bl

    else input

  @index = 0

  return

exports.baseContext =
  reset: exports.resetByConcat
  input: null
  index: 0
