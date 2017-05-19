# wrap in a describe+it so they won't run when i use .only() elsewhere.
describe 'run examples during', ->

  it 'testing', ->
    require '../../examples/strings/counter'
    require '../../examples/buffers/json-payload'
    require '../../examples/transforms/math'
    # require '../../examples/objects/messages'
    require '../../examples/strings/json'
