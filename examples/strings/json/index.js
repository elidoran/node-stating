// i'm going to use CoffeeScript...
require('coffee-script/register')

var stringify = require('fast-safe-stringify')

var parse = require('./parser.js')

console.log('example strings/json\n---------------------------------------------------------')

var input = (function() {
  var index = process.argv.indexOf('--input')
  if (index > -1 && index + 1 < process.argv.length) {
    return process.argv[index + 1]
  }
})()

var result

if (input) {

  result = parse(input)
  console.log()
  console.log(result)
  console.log()

} else {

  // make a JSON string from an object
  input = stringify({
    some: 'object',
    easyAs: 123,
    // NOTE: stating/json doesn't decode a Date string, yet.
    array: [ 1, 2, 3, 'array', new Date, -1, 1.25 ],
    inner: {
      key: 'value',
      num: 1234567890
    }
  })

  // split the input into chunks
  var inputs = [
    input.slice(0, 5), input.slice(5, 12), input.slice(12, 21), input.slice(21)
  ]

  // process multiple strings provided separately
  for (var i = 0; i < inputs.length; i += 1) {
    result = parse(inputs[i])
  }

  // send the last result which should be the object.
  console.log(JSON.stringify(result, null, 2))

  console.log('  ... again ...')

  // do the same thing again all as one string.
  console.log(JSON.stringify(parse(input), null, 2))

}
