ForkQueue = require 'forkqueue'
cp = require 'child_process'
_ = require 'underscore'
{EventEmitter} = require 'events'

class AsyncWorker extends EventEmitter
  constructor: (@worker_module, @concurrency) ->
    @in_progress = 0
    @worker = cp.fork "#{__dirname}/worker_wrapper", [@worker_module]
    @worker.on 'message', (data) =>
      # Data comes in the format {event: message}
      event = _(data).keys()[0]
      message = _(data).values()[0]
      @emit event, message
    @on 'done', => @in_progress--
  length: => @in_progress
  done: => @is_done
  push: (payload) =>
    @worker.send payload
    @in_progress++
  can_handle: => @concurrency - @in_progress

module.exports = class Queue extends EventEmitter
  constructor: (@num_workers, @concurrency, @worker_module, @options={}) ->
    # Used in the test cases
    _(@options).defaults accumulate: false
    @workers = []
    @queue = []
    @results = []
    @add_worker() for i in _.range @num_workers
    @error = null
  _unfinished_workers: =>
    (worker for worker in @workers when worker.length())
  _available_workers: =>
    (worker for worker in @workers when worker.length() < @concurrency)
  add_worker: =>
    worker = new AsyncWorker @worker_module, @concurrency
    worker.on 'done', (result) =>
      @flush()
      @results.push result if @options.accumulate
    worker.on 'error', (err) =>
      @error = err
      @queue = [] # Don't process anything else
    @workers.push worker
    @flush()
  push: (payload) =>
    @queue.push payload
    @flush()
  flush: =>
    for worker in @_available_workers()
      for i in _.range Math.min(worker.can_handle(), @queue.length)
        worker.push @queue.shift()
  end: (cb) =>
    if @queue.length is 0 and @_unfinished_workers().length is 0
      return cb @error, @results
    @flush()
    process.nextTick => @end cb
