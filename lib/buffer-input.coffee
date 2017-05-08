# option 1: make a combined buffer
exports.addByConcat = (input) ->
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
exports.addByBufferList = (input) ->

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
  $add: exports.addByConcat
  input: null
  index: 0
