/*jslint node: true */
/*global console */
"use strict";


// ================================================================
//                    Define Container
// ================================================================

var WWW_Applet = function () {
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

// ================================================================
//                    Main Stuff
// ================================================================

var puts = function () {
  if (typeof console !== "undefined") {
    console.log("hello");
  }
};

WWW_Applet.new = function () {
    puts("hello");
};

WWW_Applet.new();





