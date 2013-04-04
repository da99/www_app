
var _     = require('underscore')
, assert  = require('assert')
, Applet  = require('json_applet').Applet
, cheerio = require('cheerio');
;

var HTML = {
  'block' : function (args, meta) {
    var results = meta.app.run(args);
    if (results.error)
      return results;
    return "<div>" + results.join("") + "</div>";
  },
  'parent form': function (args, meta) {
    var results = meta.app.run(args);
    if (results.error)
      return results;
    return "<form>" + results.join("") + "</form>";
  },
  'form . text_input' : function (args, meta) {
    return '<input>' + args[0] + '</input>';
  }
};

var Ok = function (source) {
  return Applet(source, HTML).run();
};

var to_html = function (str) {
  var r = (Ok.run) ? Ok.run(str) : Ok(str);
  if (r.error)
    throw r.error;
  return r.join("");
};

var to_js = function (str) {
  var r = (Ok.run) ? Ok.run(str) : Ok(str);
  if (r.error)
    throw r.error;
  return r;
};

describe( 'Applet', function () {

  describe( '.run', function () {

    it( 'returns error if func not defined', function () {
      var html = [
        'text_boxs', ['my name', "something else"]
      ];

      assert.equal(Ok(html).error.message, "Func not found: text_boxs");
    });

  }); // === end desc

  describe( 'in parent', function () {

    it( 'returns error if child element is used as a parent', function () {
      var html = [
        'text_input', ['my name', "something else"]
      ];
      assert.equal(Ok(html).error.message, "text_input: can only be used within \"form\".");
    });

  }); // === end desc

  describe( 'parent ', function () {

    it( 'runs funcs defined for parent', function () {
      var slang = [
        'form', [
          'text_input', [ "hello world" ]
        ]
      ];
      assert.equal(to_html(slang), '<form><input>hello world</input></form>');
    });

    it( 'returns error if parent element is used as a child within another parent: form > form', function () {
      var html = [
        'form', [ 'form', [ 'text_input', ['my_name', 'some text']] ]
      ];
      assert.equal(Ok(html).error.message, "form: can not be used within another \"form\".");
    });

    it( 'returns error if parent element is used as a nested child: form > block > form', function () {
      var html = [
        'form', [ 'block', [ 'form', ['my_name', 'some text']] ]
      ];
      assert.equal(Ok(html).error.message, "form: can not be used within another \"form\".");
    });

  }); // === end desc

}); // === end desc


