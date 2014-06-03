/*jslint node: true */
/*global describe, it */
"use strict";

// ================================================================================
// Helpers and Requires
// ================================================================================
var assert     = require("assert");
var fs         = require("fs");
var WWW_Applet = require("../../lib/www_applet").WWW_Applet;
var last       = function (arr) { return arr[arr.length-1]; };

var for_each = function (arr, f) {
  for (var i = 0; i < arr.length; i++) {
    f(arr[i], i);
  }
};

var is_included = function (arr, val) {
  var curr  = 0;
  var stop  = arr.length;

  while (curr < stop) {
    if (arr[curr] === val) {
      return true;
    }
    curr = curr + 1;
  }
  return false;
}; // function is_included

// ================================================================================
// WWW_Applet_Test
// ================================================================================

var WWW_Applet_Test = function (input, output) {
  this.err    = null;

  this.input  = new WWW_Applet({name: "INPUT", json: input});

  this.output = new WWW_Applet({name: "OUTPUT SPECS", json: output});
  this.output.extend(WWW_Applet_Test.Computers);
  this.output.test_applet = this.input;
  this.output.test_err    = null;

  return this;
};

WWW_Applet_Test.prototype.run = function () {
  try {
    this.input.run();
  } catch (e) {
    if (!is_included(this.output.tokens, "should raise")) {
      throw e;
    }
    this.output.test_err = e;
  }
  this.output.run();
  return this;
};


WWW_Applet_Test.Computers = {

  "value should ==" : function (sender, to, args) {
    var name   = last(sender.stack);
    var target = last(args);
    assert.equal(this.test_applet.GET(name), target);
    return true;
  },

  "should raise" : function (sender, to, args) {
    var err_name = last(args);
    assert.ok(this.test_err.message, new RegExp(err_name, "i"));
    return this.test_err.message;
  },

  "message should match" : function (sender, to, args) {
    var str_regex = last(args);
    var msg = last(sender.stack);
    var regex = new RegExp(str_regex, "i");
    assert.ok(regex.test(this.test_err.message))
    return true;
  },

  "stack should ==" : function (sender, to, args) {
    assert.deepEqual(this.test_applet.stack, args);
    return true;
  },

  "should not raise" : function (sender, to, args) {
    assert.equal(this.test_err, null);
    return true;
  },

  "last console message should ==" :  function (sender, to, args) {
    assert.deepEqual(last(this.test_applet.console), last(args));
    return true;
  },

  "console should ==": function (sender, to, args) {
    assert.deepEqual(this.test_applet.console, args);
    return true;
  }

}; // === WWW_Applet.Computers



// ================================================================================
// The Tests.
// ================================================================================
for_each(fs.readdirSync("./specs/as_json"), function (f) {

  var desc = f.replace(/^\d\d\d\d-|.json$/g, "").replace(/_/g, " ");
  var json = JSON.parse(fs.readFileSync("./specs/as_json/" + f).toString());

  describe('"' + desc + '"', function () {

    for_each(json, function (o) {
      it(o.it, function () {
        var t = new WWW_Applet_Test(o.input, o.output);
        t.run();
      }); // === it
    });

  }); // === describe

});



