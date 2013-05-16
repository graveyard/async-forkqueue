Queue = require "#{__dirname}/.."
_ = require 'underscore'
assert = require 'assert'

describe 'async-forkqueue', ->
  it 'accumulates successfully when there are no errors', (done) ->
    queue = new Queue 4, 4, "#{__dirname}/lib/square_worker", accumulate: true
    nums = _.range 20
    queue.push i for i in nums
    queue.end (err, results) ->
      assert.ifError err
      assert.equal results.length, nums.length
      assert i*i in results for i in nums.length
      done()

  it "doesn't accumulate successfully when there are no errors", (done) ->
    queue = new Queue 4, 4, "#{__dirname}/lib/square_worker"
    nums = _.range 20
    queue.push i for i in nums
    queue.end (err, results) ->
      assert.ifError err
      assert not results
      done()
