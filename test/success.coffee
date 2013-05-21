Queue = require "#{__dirname}/.."
_ = require 'underscore'
assert = require 'assert'

describe 'async-forkqueue', ->
  it 'accumulates successfully when there are no errors', (done) ->
    queue = new Queue 4, 4, "#{__dirname}/lib/square_worker"
    results = []
    queue.on 'data', (result) -> results.push result
    nums = _.range 20
    queue.push i for i in nums
    queue.end (err) ->
      assert.ifError err
      assert.equal results.length, nums.length
      assert i*i in results for i in nums.length
      done()
