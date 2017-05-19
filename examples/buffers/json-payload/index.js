// in your code replace this with:
// var nodes = require('stating')()
var nodes = require('../../../lib/')()

// handles circular references
var stringify = require('fast-safe-stringify')

console.log('example buffers/json')

// first added will be the start node.
// this decodes a length header specifying the number
// of bytes in the following JSON content.
nodes.add('header', function header(control, N) {

  if ((this.input.length - this.index) < 4) {
    control.wait()
  } else {
    this.contentLength = this.input.readUInt32BE(this.index)
    this.index += 4
    control.next(N.content)
  }

})

// this gathers buffers until it has enough to extract
// the JSON content; according to length header.
nodes.add('content', function content(control, N) {

  if (this.buffers
      && (this.buffersLength + this.input.length >= this.contentLength)) {

    this.index = this.contentLength - this.buffersLength
    this.buffers.push(this.input.slice(0, this.index))
    this.content = Buffer.concat(this.buffers)
    this.buffers = null
    this.buffersLength = 0
    control.next(N.parse, N.header)
  }

  else if ((this.index + this.contentLength) <= this.input.length) {
    this.content = this.input.slice(this.index, this.index + this.contentLength)
    this.index += this.contentLength
    control.next(N.parse, N.header)
  }

  else {
    this.buffers = this.buffers || []
    this.buffersLength = this.buffersLength || 0
    this.buffersLength += this.input.length - this.index
    this.buffers.push(this.input.slice(this.index, this.input.length))
    this.index = this.input.length
    control.wait()
  }

})

// once content is availble we parse the JSON.
nodes.add('parse', function parse(control, N) {
  this.value = JSON.parse(this.content)
  this.content = null
  control.next(N.report)
})

// report it
nodes.add('report', function report(control, N) {
  console.log('report:\n  ', this.value)
  this.value = null
  control.next()
})


// build an "executor" which will accept buffers
var executor = nodes.buffers()

// encode some JSON stuff into a buffer
var buffer = Buffer.alloc ? Buffer.alloc(25000) : new Buffer(25000)
var index = 0
var lengths = []

function add(thing) {
  var json = stringify(thing)
  var length = Buffer.byteLength(json)
  lengths.push(length)
  buffer.writeUInt32BE(length, index)
  index += 4
  console.log('written:',index, buffer.write(json, index, length, 'utf8'))
  index += length
}

add('testing')

add([123456789012, 12345.1234567, 'some array'])

add({
  object: true,
  some: 'thing',
  another: 'thing',
  something: 'else',
  now: new Date,
})

// big one, approximately 9,849 bytes on my system (varies).
add(process)

// process the buffer in chunks which are *not* at the
// length boundaries.
buffer = buffer.slice(0, index)

executor.process(buffer.slice(0, 5))
executor.process(buffer.slice(5, 21))
executor.process(buffer.slice(21, 31))
executor.process(buffer.slice(31, 51))
executor.process(buffer.slice(51, 201))
executor.process(buffer.slice(201, 2001))
executor.process(buffer.slice(2001, 4000))
executor.process(buffer.slice(4000, 7000))
executor.process(buffer.slice(7000, 9000))
executor.process(buffer.slice(9000, 12500))
executor.process(buffer.slice(12500, 16250))
executor.process(buffer.slice(16250, 18000))
executor.process(buffer.slice(18000, buffer.length))
