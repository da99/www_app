
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

  it( 'accepts a KV object as an argument instead of array', function () {
    var args = {val: "anything"};
    var results = null;

    var app = Applet.new(['box', args, ["some text"]]);
    app.def_tag('box', {val: anything}, null, function (m, tag, attrs, content) {
      results = attrs;
      return [tag, attrs, content];
    });
    RUN(app);

    assert.equal(results, args);
  });

  it( 'returns error if arguments are numbers instead of array/object', function () {

    var app = Applet.new(['box', 100, []], ['box', function (m, a1, a2) {}]);
    app.run();

    assert.equal(app.error.message, "box: invalid argument: 100");
  });

}); // === end desc



