
var _     = require('underscore')
, assert  = require('assert')
, Applet  = require('www_applet/lib/www_applet').Applet
, cheerio = require('cheerio');
;


var APP     = function (source) { return Applet.new(source); };

var RESULTS = function (source) {
  return RUN(source).results;
};

var RUN = function (source) {
  var results = APP(source).run();
  if (results.message)
    throw results;
  return results;
};

var ERROR   = function (source) {
  var results = APP(source).run();
  if (!results.message)
    throw new Error("Error expected, but not found: " + JSON.stringify(source));
  return results;
};


describe( 'Errors:', function () {

  it( 'returns error if func not defined', function () {
    var html = [
      'text_boxs', ['my name', "something else"]
    ];

    assert.equal(ERROR(html).message, "Function not found: text_boxs");
  });


  it( 'returns error if arguments are numbers instead of array/object', function () {
    var app = Applet.new(['box', 100, []]);
    app.def_tag('box', [], function (m, a1, a2) {});

    assert.equal(app.run().message, "box: invalid argument: 100");
  });

  it( 'returns error if tag .on_run func does not return an array', function () {
    var app = Applet.new(['box', {}, []]);
    app.def_tag('box', [], function (m, a1, a2) {});

    var msg = "box: function does not return a [tag, args, content] array: function (m, a1, a2) {}";
    assert.equal(app.run().message, msg);
  });

  it( 'returns error if unknown attributers are used', function () {
    var app = Applet.new(['box', {val: 'something'}, []]);
    app.def_tag('box', [], function (m, a1, a2) {});

    assert.equal(app.run().message, "box: unknown attributes: \"val\"");
  });

  it( 'returns error if .run has any arguments', function () {
    var app = Applet.new(['box', []]);
    assert.equal(app.run([]).message, ".run does not accept any arguments: [[]]");
  });
}); // === end desc



