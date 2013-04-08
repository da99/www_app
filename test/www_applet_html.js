
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

describe( 'ok_slang', function () {

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

  }); // === end desc

  describe( '[ "tag", [],  [ ele, ele, ele ] ]', function () {

    it( 'creates children on previously defined element', function () {
      var slang = [
        'form', {action: 'http://www.text.com/'}, [
          'button', {}, ['Hello']
        ]
      ];
      assert.equal(to_html(slang), '<form action="http://www.text.com/"><button id="my_button">Hello</button></form>');
    });

  }); // === end desc

  describe( '{button: ["name", "text", ...]}', function () {

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


