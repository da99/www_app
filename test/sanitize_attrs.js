
var _     = require('underscore')
, assert  = require('assert')
, E       = require('www_applet/lib/sanitize').Sanitize
;

describe( 'Sanitize attrs:', function () {

  // What if the value is null? undefined?
  _.each(E.attr_funcs, function (name) {

    describe( name, function () {

      it( 'returns error if value is null', function () {
        assert.equal(E[name](null).constructor, Error);
      });

      it( 'returns error if value is undefined', function () {
        assert.equal(E[name](undefined).constructor, Error);
      });

    }); // === end desc

  }); // end _.each

  describe( 'name', function () {
    it( 'returns value is valid string', function () {
      assert.equal(E.name("some_name"), "some_name");
    });
  }); // === end desc

  describe( 'href', function () {
    it( 'returns error if url is not valid', function () {
      assert.equal(E.href("http://wwwtome<").message, "href: URI is not strictly valid.: http://wwwtome<");
    });
  }); // === end desc
}); // === end desc


