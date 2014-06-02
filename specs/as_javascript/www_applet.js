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
  this.input  = new WWW_Applet(input);
  this.output = new WWW_Applet(output);
  this.err    = null;

  var applet = this.input;
  var this_test = this;

  this.output.write_computer("value should ==", function (o,n,v) {
    var name   = last(o.stack);
    var target = last(o.fork_and_run(n,v).stack);
    return assert.equal(this.input.read_value(name), target);
  });

  this.output.write_computer("should raise", function (o,n,v) {
    var target = last(o.fork_and_run(n,v).stack);
    assert.throws(function () {
      if (this_test.err) {
        throw this_test.err;
      } else {
        throw new Error("No error thrown.");
      }
    });

    return true;
  });

  this.output.write_computer("message should match", function (o,n,v) {
    var str_regex = last(o.fork_and_run(n,v).stack);
    var msg = last(this_test.output.stack);
    var regex = new RegExp(str_regex, "i");
    return assert.ok(regex.test(this_test.err));
  });

  this.output.write_computer("stack should ==", function (o,n,v) {
    return assert.equal(applet.stack, o.fork_and_run(n,v).stack);
  });

  this.output.write_computer("should not raise", function (o,n,v) {
    return assert.equal(this_test.err, null);
  });

  this.output.write_computer("last console message should ==", function (o,n,v) {
    return assert.equal(last(applet.console()), last(o.fork_and_run(n,v).stack));
  });

  return this;
};

WWW_Applet_Test.prototype.run = function () {
  console.log("running");
  // this.input.run();
  // this.output.run();
  return this;
};

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



