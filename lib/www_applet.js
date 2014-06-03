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

var inspect           = function (o) { return JSON.stringify(o); };
var is_string         = function (s) { return typeof s === 'string'; };
var is_function       = function (o) { return o && o.constructor === Function; };
var is_empty          = function (arr) { return arr.length ===  0; };
var is_array          = function (o) { return o && o.constructor === Array; };
var is_object         = function (o) { return o && is_array(o.IS) && o.constructor === Object; };
var is_applet_object  = function (o) { return is_object(o) && is_array(o.IS); };
var last              = function (arr) { return arr[arr.length-1]; };

var source_string = function () {
  var pieces = [];
  var token  = null;
  var stop   = arguments.length;

  for ( var i = 0; i < stop; i++ ) {
    token = arguments[i];
    if (is_stack_able(token)) {
      pieces.push(inspect(token));
    } else if (is_array(token)) {
      if (is_empty(token)) {
        pieces.push("[ ]");
      } else {
        pieces.push("[...]");
      }
    } else {
      pieces.push(inspect(token));
    }
  } // === for

  return pieces.join(" ");
};

var is_applet_command = function (val) {
  return is_applet_object(val) && is_included(val.IS, "APPLET COMMAND");
};

var is_stack_able = function (o) {
  if (o && is_included(STACK_ABLES, o.constructor)) {
    return true;
  }

  if (is_applet_object(o) && !is_applet_command(o)) {
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
  this.is_fork    = false;
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
        throw new Error("At least one argument required.");
      }
      throw new Error("Too many extra arguments: " + inspect(arguments));
  } // switch

  if (!this.name) {
    this.name = "[UNKNOWN]";
  }

  if (!is_array(this.args)) {
    throw new Error("Invalid value: for args: " + inspect(this.args));
  }

  if (is_string(this.tokens)) {
    this.tokens = JSON.parse(this.tokens);
  }

  if (!is_array(this.tokens)) {
    throw new Error("Invalid: JS object must be an array");
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


WWW_Applet.prototype.fork_and_run = function (name, tokens) {
  var c = new WWW_Applet(this, name, tokens);
  c.is_fork = true;
  c.run();
  return c;
};

WWW_Applet.prototype.top = function () {
  var p = this.parent;
  var curr = p;
  while (curr) {
    curr = p.parent;
    if (curr) {
      p = curr;
    }
  }

  return p || this;
};

WWW_Applet.prototype.run = function () {

  if (this.is_running) {
    throw new Error("Invalid state: Already running.");
  }

  this.is_running = true;

  if (this.is_done) {
    throw new Error("Invalid state: Already finished running.");
  }

  var stop     = this.tokens.length;
  var curr     = 0;

  while (curr < stop && !this.is_done) {

    var val      = this.tokens[curr];
    if (is_array(val)) {
      throw new Error("Invalid syntax: Computer name not specified: " + inspect(val));
    }
    var next_val    = this.tokens[curr + 1];
    var is_end      = (curr + 1) === stop;
    var should_send = is_array(next_val);

    curr = curr + 1;

    if (is_end || !should_send) {
      if (!is_stack_able(val)) {
        throw new Error("Invalid value: " + inspect(val));
      }
      this.stack.push(val);
      continue;
    }

    // ===================================================
    // SEND TO COMPUTER
    // ===================================================
    curr = curr + 1; // move past the tokens array
    var from                = this;
    var to                  = standard_key(val);
    var raw_args            = next_val;
    var should_compile_args = (to !== standard_key("IS A COMPUTER"));
    var args                = null;
    var resp                = null;
    var box                 = this;
    var found               = null;
    var c                   = null;
    var computers           = null;
    var computers_box       = null;

    if (should_compile_args) {
      args = from.fork_and_run("arg run for " + inspect(to), raw_args).stack;
    } else {
      args = raw_args;
    }

    // === Find the computer. ============================
    // === Send to computer. =============================
    // === Re-send to next computer if requested. ========
    // === Process final result. =========================
    while (box && !found) { // === computer as box with array of computers

      computers     = box.computers[to];
      computers_box = box;

      box = box.parent;
      if (!computers) {
        continue;
      }

      for ( var i_computer = 0; !found && i_computer < computers.length; ++i_computer) {

        c = computers[i_computer];
        if (is_function(c)) {
          resp = c(from, to, args);
        } else {
          resp = computers_box[c](from, to, args);
        }

        if (is_stack_able(resp)) { // === push value to stack
          this.stack.push(resp);
          found = true;

        } else { // === run applet command

          switch (resp.VALUE) {

            case "STOP APPLET":
              this.is_done = true;
            found = true;
            break;

            case "IGNORE RETURN": // don't put anything on the stack
              found = true;
            break;

            case "CONTINUE":
              found = false;
            break;

            default:
              throw new Error("Invalid: Unknown operation: " + inspect(resp.VALUE) );

          } // === switch

        } // === if/else

      } // === for
    } // === while box && !found

    if (!found) {
      throw new Error("Computer not found: " + inspect(val));
    }

    // ===================================================
    // END OF SEND TO COMPUTER
    // ===================================================

  } // === while

  this.is_done = true;
  return this;
};


// ================================================================
//                    Computers
// ================================================================

WWW_Applet.Computers = {

  "REQUIRE ARGS" : function (sender, to, args) {
    var the_args = sender.get("THE ARGS");
    if (args.length !== the_args.length) {
      throw new Error("Args mismatch: " + inspect(to) + " " + inspect(args) + " != " + inspect(the_args));
    }

    for (var i = 0; i < args.length; i++) {
      sender.IS(args[i], the_args[i]);
    }

    return WWW_Applet.IGNORE_RETURN;
  },

  "COPY OUTSIDE STACK" : function (sender, to, args) {
    var target = sender.parent;
    if (args.length > target.stack.length) {
      throw new Error("Stack underflow in " + inspect(target.name) + " for : " + inspect(to) + " " + inspect(args));
    }

    for (var i = 0; i < args.length; i++) {
      sender.IS(args[i], target.stack[target.stack.length - args.length - i]);
    }

    return WWW_Applet.IGNORE_RETURN;
  },

  "PRINT" : function (sender, to, args) {
    var val = null;
    if (args.length === 1) {
      val = inspect(last(args));
    } else {
      val = inspect(args);
    }
    this.top().console.push(val);
    return WWW_Applet.IGNORE_RETURN;
  },

  "HAS?" : function (sender, to, args) {
    if (arguments.length === 1) { // run as native function
      return this.values.hasOwnProperty(standard_key(arguments[0]));
    } else {
      throw new Error("NOT DONE YET.");
    }
  },

  "GET" : function (sender, to, args) {
    if (arguments.length === 1) { // run as native function
      return this.values[standard_key(arguments[0])];
    }

    var name = standard_key(last(args));
    var target = sender;

    while (!target.values.hasOwnProperty(name) && target.is_fork && target.parent) {
      target = target.parent;
    }

    if (!target.values.hasOwnProperty(name)) {
      throw new Error("Value not found: " + inspect(name));
    }

    return target.values[name];
  },

  "IS": function (sender, to, args) {
    var orig_name, raw_name, source, name, value;

    if (arguments.length === 2) { // run as native function
      orig_name = arguments[0];
      name  = standard_key(orig_name);
      value = arguments[1];

      if (this.values.hasOwnProperty(name)) {
        throw new Error("Value already created: " + inspect(orig_name));
      }
      this.values[name] = value;

      return value;
    }

    raw_name = sender.stack.pop();
    value    = last(args);
    source   = inspect(raw_name) + " " + inspect(to) + " " + inspect(args);

    if (!raw_name) {
      throw new Error("Missing value: " + source);
    }

    if (!is_string(raw_name)) {
      throw new Error("Invalid value: Must be a string: " + source);
    }

    if (is_empty(args)) {
      throw new Error("Missing value: " + source);
    }

    name = standard_key(raw_name);
    if (sender.values.hasOwnProperty(name)) {
      throw new Error("Value already created: " + inspect(name));
    }

    sender.values[name] = value;
    return value;
  },

  "IS A COMPUTER" : function (sender, to, tokens) {
    var source   = source_string(last(sender.stack), to, tokens);
    if (is_empty(sender.stack)) {
      throw new Error("Missing value: a name for the computer: " + source);
    }

    var raw_name = sender.stack.pop();

    if (!is_string(raw_name)) {
      throw new Error("Invalid value: computer name must be a string: " + source);
    }

    var name = standard_key(raw_name);
    if  (sender.computers[name]) {
      throw new Error("Invalid value: computer name already taken: " + source);
    }

    sender.computers[name] = [tokens];

    return {"IS": ["COMPUTER"], "VALUE": name};
  },

  "STOP APPLET": function (sender, to, tokens) {
    return WWW_Applet.STOP_APPLET;
  }

}; // === Computers


exports.WWW_Applet = WWW_Applet;




