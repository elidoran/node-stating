Stating = require './Stating'

# export a function which creates a Stating instance
module.exports = (options) -> new Stating options

# export the classes as sub properties on the builder function
module.exports.Stating = Stating
module.exports.Control = require './Control'
