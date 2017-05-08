exports.$add = (input) -> @input = input

exports.baseContext =
  $add: exports.$add
  input: null
