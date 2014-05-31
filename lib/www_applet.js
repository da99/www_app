/*jslint node: true */
/*global console */
"use strict";


// ================================================================
//                    Define Container
// ================================================================

var WWW_Applet = function (code) {
  this.code = code
  if (typeof code === "string") {
    this.tokens = JSON.parse(code);
  } else {
    this.tokens = code;
  }

  this.funcs = {};
  this.vals  = {};
  this.stack = [];
  this.is_done = false;
  return this;
};

// ================================================================
//                    Helpers
// ================================================================

WWW_Applet.SPACES       = /\ +/g;
WWW_Applet.quote        = function (str) { return '"' + str + '"'; };
WWW_Applet.standard_key = function (s) { return WWW_Applet.trim(s).toUpperCase(); };
WWW_Applet.trim         = function (str) {
  if (str.trim) {
    return str.trim();
  }
  return String(str).replace(new RegExp('^\\s+|\\s+$', 'g'), '');
};

var puts = function () {
  if (typeof console === "undefined") {
    for_each(arguments, function (o) {
      puts.outputs.push(o);
    });
  } else {
    console.log.apply(console, arguments);
  }
};
puts.output = [];

// ================================================================
//                    Errors
// ================================================================

WWW_Applet.new_error = function (name) {
  return function (mess) {
    this.message = mess;
    this.name    = name;
    return this;
  };
};

WWW_Applet.Invalid               = WWW_Applet.new_error("Invalid");
WWW_Applet.Value_Not_Found       = WWW_Applet.new_error("Value_Not_Found");
WWW_Applet.Computer_Not_Found    = WWW_Applet.new_error("Computer_Not_Found");
WWW_Applet.Too_Many_Values       = WWW_Applet.new_error("Too_Many_Values");
WWW_Applet.Value_Already_Created = WWW_Applet.new_error("Value_Already_Created");
WWW_Applet.Missing_Value         = WWW_Applet.new_error("Missing_Value");

// ================================================================
//                    Computer
// ================================================================
WWW_Applet.Computer = function (computer_name, tokens, origin) {
  return function (calling_scope, name, args) {
    var forked = calling_scope.fork_and_run(name, args);
    var c = new WWW_Applet(tokens, origin);
    c.write_value("THE ARGS", forked.stack);
    c.run();
    return c.stack[c.stack.length - 1];
  };
};


// ================================================================
//                    Main Stuff
// ================================================================

WWW_Applet.prototype.read_value = function (raw_name) {
  return this.vals[WWW_Applet.standard_key(raw_name)];
};

WWW_Applet.prototype.write_value = function (raw_name, v) {
  var name = WWW_Applet.standard_key(raw_name);
  if (this.hasOwnProperty(name)) {
    throw new WWW_Applet.Value_Already_Created(name);
  }
  this.vals[name] = v;
  return v;
};

WWW_Applet.prototype.write_computer = function (raw_name, f) {
  var name = WWW_Applet.standard_key(raw_name);
  if (!this.funcs[name]) {
    this.funcs[name] = [];
  }
  this.funcs[name].push(f);

  return f;
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

exports.WWW_Applet = WWW_Applet;




