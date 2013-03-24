
var _ = require('underscore')
, assert = require('assert')
, Ok = require('ok_slang').Ok
;


describe( 'ok_slang', function () {

  describe( '.to_html', function () {

    it( 'returns a string', function (done) {
      var r = Ok.new([{form: []}]).to_html();
      assert.equal(r, "<form></form>");
    });

  }); // === end desc
}); // === end desc
