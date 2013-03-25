
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
      assert.equal(r, "<form><input id=\"my_name\" name=\"my_name\" type=\"text\">enter name</input></form>");
    });

    it( 'throws error if invalid chars in name', function () {
      var err = null;
      var html = [{
        form: [
          {text_box: ['my name', "enter name", "one line"] } ]
      }];

      try { Ok.new(html).to_html(); }
      catch (e) { err = e; }

      assert.equal(err.message, "Invalid chars in text_box id: my name");
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

  describe( '{button: ["name", "text", ...]}', function () {

    it( 'creates a HTML button tag', function () {
      var html = [{button: ['my_button', 'Send']}];
      var r    = Ok.new(html).to_html();
      assert.equal(r, '<button id="my_button">Send</button>');
    });
  }); // === end desc

}); // === end desc
