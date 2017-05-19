Stating = require './Stating'

# export a function which creates a Stating instance
module.exports = (options) -> new Stating options

# export the classes as sub properties on the builder function
module.exports.Stating = Stating
module.exports.Control = require './Control'

# export these helper functions for use in custom contexts
module.exports.bufferInput = require './buffer-input'
module.exports.stringInput = require './string-input'
module.exports.objectInput = require './object-input'

module.exports.StatingError = require './error'
