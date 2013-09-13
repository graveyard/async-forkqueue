_              = require 'underscore'
cp             = require 'child_process'
debug          = require('debug') 'async_forkqueue:queue'
{EventEmitter} = require 'events'
util           = require 'util'

nextTick = require('timers').setImmediate or process.nextTick

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
  kill: =>
    try
      @worker.disconnect()
      @worker.kill()
    catch err
      return if err.message is "IPC channel is already disconnected" # Doesn't matter, had disconnect
      throw err

module.exports = class Queue extends EventEmitter
  constructor: (@num_workers, @concurrency, @worker_module, @options={}) ->
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
      @emit 'data', result
      @_flush()
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
      return nextTick => @end cb
    @_kill_workers()
    debug "done running everything."
    debug "got err: #{util.inspect @error, true}"
    cb @error
