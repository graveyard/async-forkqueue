Queue = require "#{__dirname}/.."
_ = require 'underscore'
assert = require 'assert'

describe 'async-forkqueue', ->
  it 'returns an error if the worker throws one', (done) ->
    queue = new Queue 4, 4, "#{__dirname}/lib/error_worker", accumulate: true
    nums = _.range 20
    queue.push i for i in nums
    queue.end (err, results) ->
      assert not results
      assert.equal err, 'ERROR!'
      done()
