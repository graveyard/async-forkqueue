cp = require 'child_process'
_ = require 'underscore'
{EventEmitter} = require 'events'
debug = require('debug')('async_forkqueue:queue');
util = require 'util'

class AsyncWorker extends EventEmitter
  constructor: (@worker_module, @concurrency) ->
    @in_progress = 0
    @worker = cp.fork "#{__dirname}/worker_wrapper", [@worker_module]
    @worker.on 'message', (data) =>
      # Data comes in the format {event: message}
      event = _(data).keys()[0]
      message = _(data).values()[0]
      debug "got event #{JSON.stringify data} #{event} #{message}"
      @emit event, message
    @on 'done', => @in_progress--
    @on 'error', => @in_progress--
  length: => @in_progress
  push: (payload) =>
    @worker.send payload
    @in_progress++
  can_handle: => @concurrency - @in_progress
  kill: => @worker.disconnect()

module.exports = class Queue extends EventEmitter
  constructor: (@num_workers, @concurrency, @worker_module, @options={}) ->
    # Used in the test cases
    _(@options).defaults accumulate: false
    @workers = []
    @queue = []
    @results = []
    @_add_worker() for i in _.range @num_workers
    @error = null
  _unfinished_workers: =>
    (worker for worker in @workers when worker.length())
  _available_workers: =>
    (worker for worker in @workers when worker.length() < @concurrency)
  _add_worker: =>
    worker = new AsyncWorker @worker_module, @concurrency
    worker.on 'done', (result) =>
      debug "got done with result #{result}"
      @_flush()
      @results.push result if @options.accumulate
    worker.on 'error', (err) =>
      debug "got error with err #{err}"
      @error = err
      @queue = [] # Don't process anything else
    @workers.push worker
    @_flush()
  _flush: =>
    for worker in @_available_workers()
      for i in _.range Math.min(worker.can_handle(), @queue.length)
        worker.push @queue.shift()
  _kill_workers: => _(@workers).invoke 'kill'
  push: (payload) =>
    @queue.push payload if not @error
    @_flush()
  end: (cb) =>
    if @queue.length isnt 0 or @_unfinished_workers().length isnt 0
      @_flush()
      return process.nextTick => @end cb
    @_kill_workers()
    debug "done running everything."
    debug "got err: #{util.inspect @error, true}"
    debug "got results: #{@options.accumulate}"
    return cb() unless @error or @options.accumulate
    return cb @error if @error
    return cb null, @results
