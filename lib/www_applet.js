/*jslint node: true */
/*global console */
"use strict";


// ================================================================
//                    Helpers
// ================================================================

var SPACES          = /\ +/g;
var ALL_UNDERSCORES =/_/g;
var STACK_ABLES     = [String, Boolean, Number];
var quote           = function (str) { return '"' + str + '"'; };
var standard_key    = function (s) { return trim(s).toUpperCase(); };
var trim            = function (str) {
  if (str.trim) {
    return str.trim();
  }
  return String(str).replace(new RegExp('^\\s+|\\s+$', 'g'), '');
};

var is_string         = function (s) { return typeof s === 'string'; };
var is_empty          = function (arr) { return arr.length ===  0; };
var is_array          = function (o) { return o && o.constructor === Array; };
var is_object         = function (o) { return o && is_array(o.IS) && o.constructor === Object; };
var last              = function (arr) { return arr[arr.length-1]; };

var is_applet_command = function (val) {
  return is_object(val) && is_included(val.IS, "APPLET COMMAND");
};

var is_stack_able = function (o) {
  if (o && is_included(STACK_ABLES, o.constructor)) {
    return true;
  }

  if (is_object(o) && !is_applet_command(o)) {
    return true;
  }
  return false;

};

var is_included       = function (arr, val) {
  var curr  = 0;
  var stop  = arr.length;

  while (curr < stop) {
    if (arr[curr] === val) {
      return true;
    }
    curr = curr + 1;
  }
  return false;
};

var for_each = function (arr, func) {

  for (var i = 0; i < arr.length; i++) {

    var props = {
      is_start : i===0,
      is_end   : i===(arr.length-1),
      next_ele : arr[i+1]
    };

    func(arr[i], i, props);
  }

  return arr;
};

var puts = function () {
  if (typeof console === "undefined") {
    for_each(arguments, function (o) {
      puts.output.push(o);
    });
  } else {
    console.log.apply(console, arguments);
  }
};

puts.output = [];

// ================================================================
//                    Define Container
// ================================================================

//
// Possible:
//
//   new                         "[..JSON..]"
//   new            "__main__",  "[..JSON..] "
//   new                          [...tokens...]
//   new            "__main__",   [...tokens...]
//   new   applet , "my func" ,   [...tokens...]
//   new   applet , "my func" ,   [...tokens...], [..args..]
//
var WWW_Applet = function () {

  this.parent     = null;
  this.name       = null;
  this.tokens     = [];
  this.args       = [];
  this.computers  = {};
  this.values     = {};
  this.stack      = [];
  this.is_done    = false;
  this.is_running = false;

  switch (arguments.length) {

    case 1:
      this.tokens = arguments[0];
    break;

    case 2:
      this.name   = arguments[0];
      this.tokens = arguments[1];
      break;

    case 3:
      this.parent = arguments[0];
      this.name   = arguments[1];
      this.tokens = arguments[2];
      break;

    case 4:
      this.parent = arguments[0];
      this.name   = arguments[1];
      this.tokens = arguments[2];
      this.args   = arguments[3];
      break;

    default:
      if (arguments.length === 0) {
        throw "At least one argument required.";
      }
      throw "Too many extra arguments: " + JSON.encode(arguments);
  } // switch

  if (!this.name) {
    this.name = "[UNKNOWN]";
  }

  if (!is_array(this.args)) {
    throw "Invalid value: for args: " + JSON.encode(this.args);
  }

  if (is_string(this.tokens)) {
    this.tokens = JSON.parse(this.tokens);
  }

  if (!is_array(this.tokens)) {
    throw "Invalid: JS object must be an array";
  }

  if (!this.parent) {
    this.extend(WWW_Applet.Computers);
  }

  return this;
};

WWW_Applet.STOP_APPLET       = {"IS":  ["APPLET COMMAND"], "VALUE": "STOP APPLET" };
WWW_Applet.IGNORE_RETURN     = {"IS": "APPLET COMMAND", "VALUE": "IGNORE RETURN"};

WWW_Applet.prototype.extend = function (o) {
  for (var raw_name in o) {
    if (o.hasOwnProperty(raw_name)) {
      var name = standard_key(raw_name);
      this[name] = o[raw_name];
      this.computers[name.replace(ALL_UNDERSCORES, " ")] = [name];
    }
  }
  return this;
};

WWW_Applet.prototype.run = function () {

  if (this.is_done) {
    throw new WWW_Applet.Invalid("Already finished running.");
  }

  var start    = 0;
  var fin      = this.tokens.length;
  var curr     = start;
  var this_app = this;

  while (curr < fin && !this.is_done) {
    var val      = this.tokens[curr];
    var next_val = this.tokens[curr + 1];
  }

  this.is_done = true;
  return this;
};


// ================================================================
//                    Computers
// ================================================================

WWW_Applet.Computers = {

  "get" : function (raw_name) {
    return this.values[WWW_Applet.standard_key(raw_name)];
  },

  "is": function (raw_name, v) {
    var name = WWW_Applet.standard_key(raw_name);
    if (this.hasOwnProperty(name)) {
      throw new WWW_Applet.Value_Already_Created(name);
    }
    this.values[name] = v;
    return v;
  },

  "is a computer" : function (raw_name, f) {
    var name = WWW_Applet.standard_key(raw_name);
    if (!this.computers[name]) {
      this.computers[name] = [];
    }
    this.computers[name].push(f);

    return f;
  }

}; // === Computers


exports.WWW_Applet = WWW_Applet;




