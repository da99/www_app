
var _ = require('underscore')
, assert = require('assert')
, Ok = require('ok_slang').Ok
;


describe( 'ok_slang', function () {

  describe( '.to_html', function () {

    it( 'returns a string', function () {
      var html = [{
        form: [
          {text_box: ['my_name', "enter name", "one line"] } ]
      }];
      var r = Ok.new(html).to_html();
      assert.equal(r, "<form><input name=\"my_name\" type=\"text\">enter name</input></form>");
    });

    it( 'throws error if invalid chars in name', function () {
      var err = null;
      var html = [{
        form: [
          {text_box: ['my name', "enter name", "one line"] } ]
      }];

      try { Ok.new(html).to_html(); }
      catch (e) { err = e; }

      assert.equal(err.message, "Invalid chars in name: my name");
    });

    it( 'throws error if unknown element', function () {
      var err = null;
      var html = [{
        form: [
          {text_boxy: ['my_name', "enter name", "one line"] } ]
      }];

      try { Ok.new(html).to_html(); }
      catch (e) { err = e; }

      assert.equal(err.message, "Unknown element: text_boxy");
    });

  }); // === end desc

}); // === end desc
