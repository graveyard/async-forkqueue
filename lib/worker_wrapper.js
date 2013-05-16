require('coffee-script');
debug = require('debug')('async_forkqueue:wrapper');
worker = require(process.argv[2]);

process.on('message', function(payload) {
  return worker(payload, function(err, result) {
    debug('got err ' + err + ' and result ' + result);
    if (err) return process.send({error: err});
    return process.send({done: result});
  });
});
