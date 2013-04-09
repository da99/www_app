
var _     = require('underscore')
, assert  = require('assert')
, WWW     = require('www_applet').Applet
, cheerio = require('cheerio');
;

var to_html = function (str) {
  var r = WWW.new(str).run();
  if (r.error)
    throw r.error;
  return r.results.html;
};

var to_js = function (str) {
  var r = WWW.new(str).run();
  if (r.error)
    throw r.error;
  return r.results.js;
};

var run = function (str) {
  return WWW.new(str).run();
};

describe( 'www_applet', function () {

  describe( 'to app', function () {

    it( 'returns error if unknown attrs', function () {
      var html = [
        'a', {ids: 'my name'}, [ "enter wrong name" ]
      ];

      assert.equal(run(html).error.message, "a: unknown attributes: \"ids\"");
    });

    it( 'returns error if invalid chars in name', function () {
      var html = [
        'a', {id: 'my name'}, [ "enter wrong name" ]
      ];

      assert.equal(run(html).error.message, "id: invalid characters: \"my name\"");
    });

    it( 'returns error if unknown element', function () {
      var slang = [
        'text_inputy', {}, ["enter name"]
      ];

      assert.equal(run(slang).error.message, "Function not found: text_inputy");
    });

    it( 'returns an error if content does not pass sanitization function', function () {
      var slang = [
        'button', {}, [["my text"]]
      ];

      assert.equal(run(slang).error.message, "button: Must be a string within an array: [[\"my text\"]]");
    });

  }); // === end desc

  describe( 'rendering of child elements', function () {

    it( 'creates children on previously defined element', function () {
      var slang = [
        'form', {action: 'http://www.text.com/'}, [
          'button', {}, ['Hello']
        ]
      ];
      assert.equal(to_html(slang), '<form action="http://www.text.com/"><button>Hello</button></form>');
    });

  }); // === end desc

  describe( 'buttons', function () {

    it( 'creates a HTML button tag', function () {
      var slang = [
        'button', {}, ['Send']
      ];
      assert.equal(to_html(slang), '<button>Send</button>');
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

  describe( 'links: a', function () {

    it( 'creates a HTML a tag', function () {
      var html = [
        'a', {href:'http://www.test.com/'}, ['My Link']
      ];
      var r    = to_html(html);
      var a    = cheerio.load(r)('a');
      assert.equal( a.attr('href') , "http://www.test.com/");
      assert.equal( a.text()       , "My Link" );
    });

    it( 'accepts 2 args: link, text', function () {
      var html = ['a', {href: 'http://www.test.com/'}, ['My Link']];
      assert.equal(to_html(html), '<a href="http://www.test.com/">My Link</a>');
    });

    it( 'normalizes href', function () {
      var html = ['a', {href: 'hTTp://www.test.com/'}, ['My Link']];
      assert.equal(to_html(html), '<a href="http://www.test.com/">My Link</a>');
    });

    it( 'returns error if link is invalid', function () {
      var html = ['a', {href: 'http://www.te\x3Cst.com/'}, ['My Link']];
      var err  = null;
      assert.equal(run(html).error.message, 'href: URI is not strictly valid.: http://www.te<st.com/');
    });

  }); // === end desc

}); // === end desc


