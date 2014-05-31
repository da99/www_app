/*jslint node: true */
/*global describe, it */
"use strict";

// ================================================================================
// Helpers and Requires
// ================================================================================
var assert = require("assert");
var fs = require("fs");

var for_each = function (arr, f) {
  for (var i = 0; i < arr.length; i++) {
    f(arr[i], i);
  }
};

// ================================================================================
// WWW_Applet_Test
// ================================================================================

var WWW_Applet_Test = function (input, output) {
  this.input = input;
  this.output = output;
  return this;
};

WWW_Applet_Test.prototype.run = function () {
  assert.equal(this.input, this.output);
  return this;
};

// ================================================================================
// The Tests.
// ================================================================================
for_each(fs.readdirSync("./specs/as_json"), function (f) {
  var desc = f.replace(/^\d\d\d\d-|.json$/g, "").replace(/_/g, " ");
  var json = JSON.parse(fs.readFileSync("./specs/as_json/" + f).toString());
  describe(desc, function () {
    for_each(json, function (o) {
      it(o.it, function () {
        var t = new WWW_Applet_Test(o.input, o.output);
        t.run();
      });
    });
  });
});



