
var _     = require('underscore')
, assert  = require('assert')
, Applet  = require('www_applet/lib/www_applet').Applet
, cheerio = require('cheerio');
;

var HTML = [
  'block', function (meta, args) {
    return "<div>" + err_check(meta.app.run(args)).join("") + "</div>";
  },
  'form', function (meta, args, content) {
    return "<form>" + err_check(meta.app.run(content)).join("") + "</form>";
  }, {is_parent: true},
  'text_input', function (meta, args, content) {
    return '<input>' + content[0] + '</input>';
  }, {child_of: 'form'}
];

var anything = function (any) { return any; };
var Ok      = function (source) { return Applet.new(source, HTML).run(); };
var ERROR   = function (source) { return Ok(source).error; };
var RESULTS = function (source) {
  var results = Ok(source);
  if (results.error)
    throw error;
  return results.results;
};
var RUN = function (app) {
  app.run();
  if (app.error)
    throw app.error;
  return app;
};

var err_check = function (results) {
  if (results && results.error)
    return [results.error.message];
  return results.results;
};



describe( '.run', function () {

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

describe( 'in parent', function () {

  it( 'returns error if child element is used as a parent', function () {
    var html = [
      'text_input', {}, ["something else"]
    ];
    assert.equal(ERROR(html).message, "text_input: can only be used within \"form\".");
  });

}); // === end desc

describe( 'parent ', function () {

  it( 'runs funcs defined for parent', function () {
    var slang = [
      'form', {}, [
        'text_input', {}, [ "hello world" ]
      ]
    ];
    assert.equal(RESULTS(slang).results, '<form><input>hello world</input></form>');
  });

  it( 'returns error if parent element is used as a child within another parent: form > form', function () {
    var html = [
      'form', [ 'form', [ 'text_input', ['my_name', 'some text']] ]
    ];
    assert.equal(ERROR(html).message, "form: can not be used within another \"form\".");
  });

  it( 'returns error if parent element is used as a nested child: form > block > form', function () {
    var html = [
      'form', [ 'block', [ 'form', ['my_name', 'some text']] ]
    ];
    assert.equal(ERROR(html).message, "form: can not be used within another \"form\".");
  });

}); // === end desc

describe( '.after_run', function () {

  it( 'runs all funcs in order defined', function () {
    var source = [
      'form', [ 'text_input', [ "hello world" ] ]
    ];
    var app = Applet.new(source, HTML);
    app.after_run(function (app) { app.results.push('1'); });
    app.after_run(function (app) { app.results.push('2'); });
    assert.deepEqual(app.run().results, ["<form><input>hello world</input></form>","1","2"]);
  });

}); // === end desc



