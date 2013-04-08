
var _      = require('underscore')
, _s       = require('underscore.string')
, unhtml   = require('unhtml')
, special  = require('special-html')
, assert   = require('assert')
, Sanitize = require('www_applet/lib/sanitize').Sanitize
, E        = Sanitize.html
;
var BRACKET = " < %3C &lt &lt; &LT &LT; &#60 &#060 &#0060  \
&#00060 &#000060 &#0000060 &#60; &#060; &#0060; &#00060;  \
&#000060; &#0000060; &#x3c &#x03c &#x003c &#x0003c &#x00003c  \
&#x000003c &#x3c; &#x03c; &#x003c; &#x0003c; &#x00003c;  \
&#x000003c; &#X3c &#X03c &#X003c &#X0003c &#X00003c &#X000003c  \
&#X3c; &#X03c; &#X003c; &#X0003c; &#X00003c; &#X000003c;  \
&#x3C &#x03C &#x003C &#x0003C &#x00003C &#x000003C &#x3C; &#x03C;  \
&#x003C; &#x0003C; &#x00003C; &#x000003C; &#X3C &#X03C  \
&#X003C &#X0003C &#X00003C &#X000003C &#X3C; &#X03C; &#X003C; &#X0003C;  \
&#X00003C; &#X000003C; \x3c \x3C \u003c \u003C ";


describe( 'Sanitize', function () {

  it( 'does not re-escape already escaped text mixed with HTML', function () {
    var h = "<p>Hi</p>";
    var e = _s.escapeHTML(h);
    var o = e + h;
    assert.equal(E(o), _s.escapeHTML(h + h));
  });

  it( 'escapes special chars: "Hello ©®∆"', function () {
    var s = "Hello & World ©®∆";
    var t = "Hello &amp; World &#169;&#174;&#8710;";
    assert.equal(E(s), t);
  });

  it( 'escapes all 70 different combos of "<"', function () {
    assert.equal(_.uniq(E(BRACKET.trim()).split(/\s+/)).join(' '), "&lt; %3C");
  });

}); // === end desc

