
var _     = require('underscore')
, assert  = require('assert')
, Applet  = require('www_applet').Applet
, cheerio = require('cheerio');
;
function RUN(source) {
  var results = Applet.new(source).run();
  if (results.message)
    throw results;
  return results;
}
function HTML(source) { return RUN(source).results.html; }
function JS(source) { return RUN(source).results.js; }
function ERROR(source) {
  var results = Applet.new(source).run();
  if (results.message)
    return results;
  throw new Error('Error not found for: ' + JSON.stringify(source));
}

describe( '.def_tag', function () {

  it( 'treats a null for args as an empty array: [ ]', function () {
    var app = Applet.new(['box', ["text"]]);
    app.def_tag('box', null);
    assert.equal(app.run().results.html, "<box>text</box>");
  });

}); // === end desc

describe( '.run .html', function () {

  it( 'returns error if unknown attrs', function () {
    var html = [
      'a', {ids: 'my name'}, [ "enter wrong name" ]
    ];

    assert.equal(ERROR(html).message, "a: unknown attributes: \"ids\"");
  });

  it( 'returns error if invalid chars in id', function () {
    var html = [
      'a', {id: 'my name'}, [ "enter wrong name" ]
    ];

    assert.equal(ERROR(html).message, "id: invalid characters: \"my name\"");
  });

  it( 'returns error if unknown element', function () {
    var slang = [
      'text_inputy', {}, ["enter name"]
    ];

    assert.equal(ERROR(slang).message, "Function not found: text_inputy");
  });

  it( 'creates children on previously defined element', function () {
    var slang = [
      'form', {action: 'http://www.text.com/'}, [
        'button', {}, ['Hello']
    ]
    ];
    assert.equal(RUN(slang).results.html, '<form action="http://www.text.com/"><button>Hello</button></form>');
  });

  it( 'uses a copy of the source array', function () {
    var slang = [
      'form', {action: 'http://www.text.com/'}, [
        'button', {}, ['Hello']
    ]
    ];
    var copy = slang.slice();
    RUN(slang);
    assert.deepEqual(slang, copy);
  });

}); // === end desc


describe( 'tag: button', function () {

  it( 'creates a HTML button tag', function () {
    var slang = [
      'button', {}, ['Send']
    ];
    assert.equal(HTML(slang), '<button>Send</button>');
  });

  it( 'allows on_click events', function () {
    var slang = [
      'button', ['Send'],
      'on_click', ['tell', ['It worked.']]
    ];
    assert.deepEqual(RUN(slang).results.js, [['button.ok_1', 'on_click', null, ['tell', ['It worked.']]]]);
  });

}); // === end desc

describe( 'tag: a', function () {

  it( 'creates a HTML a tag', function () {
    var html = [
      'a', {href:'http://www.test.com/'}, ['My Link']
    ];
    var r    = HTML(html);
    var a    = cheerio.load(r)('a');
    assert.equal( a.attr('href') , "http://www.test.com/");
    assert.equal( a.text()       , "My Link" );
  });

  it( 'accepts 2 args: link, text', function () {
    var html = ['a', {href: 'http://www.test.com/'}, ['My Link']];
    assert.equal(HTML(html), '<a href="http://www.test.com/">My Link</a>');
  });

  it( 'normalizes href', function () {
    var html = ['a', {href: 'hTTp://www.test.com/'}, ['My Link']];
    assert.equal(HTML(html), '<a href="http://www.test.com/">My Link</a>');
  });

  it( 'returns error if link is invalid', function () {
    var html = ['a', {href: 'http://www.te\x3Cst.com/'}, ['My Link']];
    var err  = null;
    assert.equal(ERROR(html).message, 'href: URI is not strictly valid.: http://www.te<st.com/');
  });

}); // === end desc

