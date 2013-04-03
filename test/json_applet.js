
var _     = require('underscore')
, assert  = require('assert')
, Applet  = require('json_applet').Applet
, cheerio = require('cheerio');
;

var HTML = {
  'block' : function (app) {
    return "<div></div>";
  },
  'parent form': function (app) {
    return "<form></form>";
  },
  'form . text_input' : function (app) {
    return '<input></input>';
  }
};

var Ok = function (source) {
  return Applet(source, HTML).run();
};

var to_html = function (str) {
  var r = (Ok.run) ? Ok.run(str) : Ok(str);
  if (r.error)
    throw r.error;
  return r.html;
};

var to_js = function (str) {
  var r = (Ok.run) ? Ok.run(str) : Ok(str);
  if (r.error)
    throw r.error;
  return r.js;
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

    it( 'runs funcs defined for parent', function () {
      var slang = [
        'form', [
          'text_input', [ "hello world" ]
        ]
      ];
      assert.equal(to_html(slang), '<form><input>hello world</input></form>');
    });

  }); // === end desc

  describe( 'parent ', function () {

    it( 'creates a HTML button tag', function () {
      var slang = [
        'button', 'my_button', 'Send'
      ];
      assert.equal(to_html(slang), '<button id="my_button">Send</button>');
    });

    describe( '{on_click: [...]}', function () {

      it.skip( 'generates JavaScript', function (done) {
        var slang = [
          'button', 'my', 'Send',
          'on_click', ['alert', 'It worked.']
        ];
        assert.equal(to_js(slang), 'ok_slang.on_click("my", "alert", "It worked.")');
      });

    }); // === end desc

  }); // === end desc

  describe( '{link: ["name", "link", "text"]}', function () {

    it( 'accepts 3 args: name, link, text', function () {
      var html = [
        'link', ['my_link', 'http://www.test.com/'], 'My Link'
      ];
      var r    = Ok(html).html;
      var a    = cheerio.load(r)('a');
      assert.equal( a.attr('id')   , 'my_link');
      assert.equal( a.attr('href') , "http://www.test.com/");
      assert.equal( a.text()       , "My Link" );
    });

    it( 'accepts 2 args: link, text', function () {
      var html = ['link', ['http://www.test.com/'], 'My Link'];
      assert.equal(Ok(html).html, '<a href="http://www.test.com/">My Link</a>');
    });

    it( 'normalizes href', function () {
      var html = ['link', ['hTTp://www.test.com/'], 'My Link'];
      assert.equal(Ok(html).html, '<a href="http://www.test.com/">My Link</a>');
    });

    it( 'returns error if link is invalid', function () {
      var html = ['link', ['http://www.te\x3Cst.com/'], 'My Link'];
      var err  = null;
      assert.equal(Ok(html).error.message, 'Invalid link address: http://www.te<st.com/');
    });

  }); // === end desc

}); // === end desc


