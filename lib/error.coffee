'use strict'

```
function StatingError(message, details) {
  var key, i, array
  Error.captureStackTrace(this, this.constructor)
  this.name = this.constructor.name
  this.message = message
  if (details) {
    array = Object.keys(details)
    for (i = 0; i < array.length; i++) {
      key = array[i]
      this[key] = details[key]
    }
  }
}

require('util').inherits(StatingError, Error)

module.exports = StatingError
module.exports.StatingError = StatingError
```
