
var _ = require('underscore')
, assert = require('assert')
, Ok = require('ok_slang').Ok
;


describe( 'ok_slang', function () {

  describe( '.to_html', function () {

    it( 'returns a string', function () {
      var r = Ok.new([{form: [{text_box: ['my_name', "enter name", "one line"]}]}]).to_html();
      assert.equal(r, "<form><input name=\"my_name\" type=\"text\">enter name</input></form>");
    });

  }); // === end desc
}); // === end desc
