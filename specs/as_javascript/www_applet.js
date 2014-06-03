/*jslint node: true */
/*global describe, it */
"use strict";

// ================================================================================
// Helpers and Requires
// ================================================================================
var assert     = require("assert");
var fs         = require("fs");
var WWW_Applet = require("../../lib/www_applet").WWW_Applet;

var last = function (arr) {
  return arr[arr.length-1];
};

var for_each = function (arr, f) {
  for (var i = 0; i < arr.length; i++) {
    f(arr[i], i);
  }
};

// ================================================================================
// WWW_Applet_Test
// ================================================================================

var WWW_Applet_Test = function (input, output) {
  this.err    = null;

  this.input  = new WWW_Applet(input);

  this.output = new WWW_Applet(output);
  this.output.values["APPLET"] = input;
  this.output.extend(WWW_Applet_Test.Computers);

  return this;
};

WWW_Applet_Test.prototype.run = function () {
  this.input.run();
  this.output.run();
  return this;
};


WWW_Applet_Test.Computers = {

  "value should ==" : function (o,n,v) {
    var name   = last(o.stack);
    var target = last(o.fork_and_run(n,v).stack);
    return assert.equal(this.input.values[name.toUpperCase()], target);
  },

  "should raise" : function (o,n,v) {
    var target = last(o.fork_and_run(n,v).stack);
    assert.throws(function () {
      if (this_test.err) {
        throw this_test.err;
      } else {
        throw new Error("No error thrown.");
      }
    });

    return true;
  },

  "message should match" : function (o,n,v) {
    var str_regex = last(o.fork_and_run(n,v).stack);
    var msg = last(this_test.output.stack);
    var regex = new RegExp(str_regex, "i");
    return assert.ok(regex.test(this_test.err));
  },

  "stack should ==" : function (o,n,v) {
    return assert.equal(applet.stack, o.fork_and_run(n,v).stack);
  },

  "should not raise" : function (o,n,v) {
    return assert.equal(this_test.err, null);
  },

  "last console message should ==" :  function (o,n,v) {
    return assert.equal(last(applet.console()), last(o.fork_and_run(n,v).stack));
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



