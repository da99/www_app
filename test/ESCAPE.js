
var _     = require('underscore')
, _s      = require('underscore.string')
, unhtml  = require('unhtml')
, special = require('special-html')
, assert  = require('assert')
, Ok      = require('ok_slang').Ok
, BRACKET = "";
;

describe( 'Ok.escape', function () {

  it( 'does not re-escape already escaped text mixed with HTML', function () {
    var h = "<p>Hi</p>";
    var e = _s.escapeHTML(h);
    var o = e + h;
    assert.equal(Ok.escape(o), _s.escapeHTML(h + h));
  });

  it( 'escapes special chars: "Hello ©"', function () {
    var s = "Hello & World ©";
    var t = "Hello &amp; World &#169;";
    assert.equal(Ok.escape(s), t);
  });

  it( 'escapes all 70 different combos of "<"', function () {
    assert.equal(_.uniq(Ok.escape(BRACKET.trim()).split(/\s+/)).join(' '), "&lt; %3C");
  });

}); // === end desc

describe( 'Ok.escape_uri', function () {

  it( 'normalizes address', function () {
    var s = "hTTp://wWw.test.com/"
    assert.equal(Ok.escape_uri(s), s.toLowerCase());
  });

  it( 'returns null if path contains: <', function () {
    var s = "http://www.test.com/<something/";
    assert.equal(Ok.escape_uri(s), null);
  });

  it( 'returns null if path contains HTML entities', function () {
    var s = "http://6&#9;6.000146.0x7.147/";
    assert.equal(Ok.escape_uri(s), null);
  });

  it( 'returns null if path contains HTML entities', function () {
    var s = "http://www.test.com/&nbsp;s/";
    assert.equal(Ok.escape_uri(s), null);
  });

  it( 'returns null if query string contains HTML entities', function () {
    var s = "http://www.test.com/s/test?t&nbsp;test";
    assert.equal(Ok.escape_uri(s), null);
  });

}); // === end desc


BRACKET = " < %3C &lt &lt; &LT &LT; &#60 &#060 &#0060  \
&#00060 &#000060 &#0000060 &#60; &#060; &#0060; &#00060;  \
&#000060; &#0000060; &#x3c &#x03c &#x003c &#x0003c &#x00003c  \
&#x000003c &#x3c; &#x03c; &#x003c; &#x0003c; &#x00003c;  \
&#x000003c; &#X3c &#X03c &#X003c &#X0003c &#X00003c &#X000003c  \
&#X3c; &#X03c; &#X003c; &#X0003c; &#X00003c; &#X000003c;  \
&#x3C &#x03C &#x003C &#x0003C &#x00003C &#x000003C &#x3C; &#x03C;  \
&#x003C; &#x0003C; &#x00003C; &#x000003C; &#X3C &#X03C  \
&#X003C &#X0003C &#X00003C &#X000003C &#X3C; &#X03C; &#X003C; &#X0003C;  \
&#X00003C; &#X000003C; \x3c \x3C \u003c \u003C ";
