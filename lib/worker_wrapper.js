require('coffee-script');
worker = require(process.argv[2]);

process.on('message', function(payload) {
  return worker(payload, function(err, result) {
    if (err) return process.send({error: err});
    return process.send({done: result});
  });
});
