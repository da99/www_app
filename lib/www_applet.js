/*jslint node: true */
/*global console */
"use strict";


// ================================================================
//                    Define Container
// ================================================================

var WWW_Applet = function (code) {
  if (typeof code === "string") {
    this.code = JSON.parse(code);
  } else {
    this.code = code;
  }

  this.funcs = {};
  this.vals  = {};
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

WWW_Applet.Value_Already_Created = function (mess) {
  this.message = mess;
  this.name    = "Value_Already_Created";
  return this;
};

// ================================================================
//                    Main Stuff
// ================================================================

var puts = function () {
  if (typeof console !== "undefined") {
    console.log("hello");
  }
};

WWW_Applet.prototype.stack = function () {
  return [];
};

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
  return this;
};

exports.WWW_Applet = WWW_Applet;




