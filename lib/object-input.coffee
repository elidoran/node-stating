exports.reset = (input) -> @input = input

exports.baseContext =
  reset: exports.reset
  input: null
