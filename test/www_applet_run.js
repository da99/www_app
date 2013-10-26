
var _     = require('underscore')
, assert  = require('assert')
, Applet  = require('www_applet/lib/www_applet').Applet
, cheerio = require('cheerio');
;





describe( '.after_run', function () {

  it( 'runs all funcs in order defined', function () {
    var source = [
      'form', [ 'input_text', [ "hello world" ] ]
    ];
    var app = Applet.new(source);
    var results = [];
    app.after_run(function (app) { results.push(1); });
    app.after_run(function (app) { results.push(2); });
    app.run();
    assert.deepEqual(results, [1,2]);
  });

}); // === end desc



