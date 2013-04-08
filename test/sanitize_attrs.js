
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

      if ( !_.contains("name href action".split(' '), name ) )
        it( 'adds specified name to error', function () {
          var result = E[name](null, 'my_name').message;
          if ( result.indexOf('my_name: ') !== 0)
            assert.fail(result, 'my_name', 'E.' + name + ' is not adding name to error message.');
        });

    }); // === end desc

  }); // end _.each

  describe( 'string', function () {
    it( 'returns value if string', function () {
      assert.equal(E.string("s"), "s");
    });

    it( 'returns error if value is number', function () {
      assert.equal(E.string(1).constructor, Error);
    });
  }); // === end desc

  describe( 'string_in_array', function () {
    it( 'returns value if string in array: [ my_string ]', function () {
      var val = ["This is a string."];
      assert.equal(E.string_in_array(val), val);
    });
  }); // === end desc

  describe( 'name', function () {
    it( 'returns value if valid string', function () {
      assert.equal(E.name("some_name"), "some_name");
    });
  }); // === end desc

  _.each( ['href', 'action', 'uri'] , function (name) {
    describe( 'url: ' + name, function () {
      it( 'returns error if url is not valid', function () {
        assert.equal(E[name]("http://wwwtome<").message, name + ": URI is not strictly valid.: http://wwwtome<");
      });
    }); // === end desc
  });

  describe( 'uri', function () {

    it( 'normalizes address', function () {
      var s = "hTTp://wWw.test.com/";
      assert.equal(E.uri(s), s.toLowerCase());
    });

    it( 'returns an Error if path contains: <', function () {
      var s = "http://www.test.com/<something/";
      assert.equal(E.uri(s).constructor, Error);
    });

    it( 'returns an Error if path contains HTML entities', function () {
      var s = "http://6&#9;6.000146.0x7.147/";
      assert.equal(E.uri(s).constructor, Error);
    });

    it( 'returns an Error if path contains HTML entities', function () {
      var s = "http://www.test.com/&nbsp;s/";
      assert.equal(E.uri(s).constructor, Error);
    });

    it( 'returns an Error if query string contains HTML entities', function () {
      var s = "http://www.test.com/s/test?t&nbsp;test";
      assert.equal(E.uri(s).constructor, Error);
    });

  }); // === end desc

  // ****************************************************************
  // ****************** END of Sanitize Attrs ***********************
  // ****************************************************************

  describe( '.opt(func)', function () {
    it( 'returns a function where null returns null', function () {
      assert.equal(E.opt(E.string)(null), null);
    });

    it( 'returns a function where undefined returns null', function () {
      assert.equal(E.opt(E.string)(undefined), null);
    });

    it( 'returns a function that passes false to underlying function', function () {
      assert.equal(E.opt(E.string)(false).constructor, Error);
    });

    it( 'returns a function that passes any Number to underlying function', function () {
      assert.equal(E.opt(E.string)(1).constructor, Error);
    });

    it( 'returns a function that passes any String to underlying function', function () {
      assert.equal(E.opt(E.string)("a"), "a");
    });
  }); // === end desc

}); // === end desc


