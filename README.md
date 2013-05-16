# Async-ForkQueue
Async-ForkQueue is based on (https://github.com/andrewjstone/forkqueue)[ForkQueue], but it allows setting a level of concurrency where each forked process will run that many at a time and provides a api for creating worker functions.

## Install

<pre>
  npm install async-forkqueue
</pre>

## API
```javascript
var Queue = require('async-forkqueue');
var num_workers = 4;
var concurrency = 4;

var queue = new Queue num_workers, concurrency, module_path

for (var i = 0; i < 100; i++) {
  queue.push(i);
}

queue.end(callback);
```

## Worker modules
Worker modules are spawned with [child_process.fork](http://nodejs.org/api/child_process.html#child_process_child_process_fork_modulepath_args_options).

A simple worker is below.

```javascript
module.exports = function (payload, cb) {
  // Do something with the payload
  cb()
}
```