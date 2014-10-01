
"use strict";

var WWW_Applet = null;


(function () {

  // ================================================================
  // Scope
  // ================================================================
  var Scope = function (parent) {

    var o     = {};
    var vars  = {};
    var stack = [];

    if (parent) {
      o.parent = parent;
    }

    var run_func = function (name, args) {
      var func = funcs[name];

      if (!func) {
        throw new Error("Function not found: " + name);
      }

      return func.apply(null, [o]);
    }; // run_func ===================================

    var val = function (name, val) {
      var args       = _.toArray(arguments);
      var return_val = null;
      switch (args.length) {

        case 1:
          if (!vars.hasOwnProperty(name) && !parent) {
          throw new Error('No var found with name: ' + name);
        }

        return_val = (vars.hasOwnProperty(name)) ?
          vars[name] :
          parent.read_var(name);
        break;

        case 2:
          vars[name] = val;
        return_val = val;
        break;

        default:
          throw new Error("Unknown value: " + args.length);

      } // === switch args.length

      return return_val;
    }; // val =========================================

    var push = function () {
      var args = _.toArray(arguments);
      stack    = stack.concat(args);
      return args;
    }; // push ========================================

    var right_concat = function (arr) {
      var o = this;
      o.stack = o.stack.concat(arr);
      return arr;
    }; // right_concat ================================

    var right = function () {
      return last_types(o.stack, _.toArray(arguments), 'stack');
    };

    var left = function () {
      return last_types(o.run_args(), _.toArray(arguments), 'args');
    };

    var replace_left = function (arr) {
      o._left_args = arr;
      return o._left_args;
    };

    var run_args = function (args) {
      if (o.args && args) {
        throw new Error('Args already given.');
      }

      if (args) {
        o.args = args;
      }

      if (!o.args && !args) {
        throw new Error("No args given.");
      }

      if (o._left_args) {
        return o._left_args;
      }

      o._left_args = o.child().run(args).stack;

      return o._left_args;
    }; // run_args

    var raw_args = function () {
      return o.args;
    }; // raw_args

    var child = function () {
      return( new Scope(o) );
    };

    var run = function (code_array) {
      each(code_array, function (item, l) {

        if (_.isArray(item)) {
          throw new Error("Syntax error: args w/o function name.");

        } else if (_.isString(item), _.isArray(l.next_or_null())) {
          run_func(item, l.grab_next());

        } else {
          stack.push(item);
        } // === if

      }); // === .each

      return o;
    }; // run ========================================

    o.vars  = vars;
    o.stack = stack;
    o.run   = run;

    return o;

  // ================================================================
  }; // ===== Scope =================================================
  // ================================================================


  // ================================================================
  // Helper Functions
  // ================================================================

  // From:
  // http://stackoverflow.com/questions/1026069/capitalize-the-first-letter-of-string-in-javascript 
  var capitalize = function (s) {
    return s.charAt(0).toUpperCase() + s.substring(1);
  };


  var inspect = function (val) {
    var name = func_name(val.constructor || 'Unknown');
    return name + ': ' + val;
  };


  var is_numeric = function (val) {
    return _.isNumber(val) && !_.isNaN(val);
  };


  var log = function () {
    if (!window.console) { return; }
    return console.log.apply(console, arguments);
  };


  var func_name = function (raw) {
    var s    = null;
    var name = null;

    if (_.isString(raw)) {
      s = raw;
    } else {
      s = ('' + raw);
    }

    name = _.last( _.first(s.split('(')).split('function ') );
    return name;
  };


  var each = function (arr, func) {
    var l      = arr.length;
    var i      = 0;
    var each_o = {

      next: function () {
        if (each_o.is_last()) {
          throw new Error('No more items: i: ' + i + ' total: ' + l);
        }
        return arr[i + 1];
      }, // === next

      prev : function () {
        if (each_o.is_first()) {
          throw new Error('No previous items: i: ' + i + ' total: ' + l);
        }
        return arr[i - 1];
      },

      next_or_null: function () {
        if (each_o.is_last()) { return null; }
        return arr[i + 1];
      },

      prev_or_null : function () {
        if (each_o.is_first()) { return null; }
        return arr[i - 1];
      },

      is_first: function () {
        return i < 1;
      },

      is_last: function () {
        return i >= (l - 1);
      },

      grab_next: function () {
        if (each_o.is_last()) {
          throw new Error('Can\'t grab next because already at last position.');
        }
        i = i + 1;
        return arr[i];
      }

    }; // === each_o

    while ( i < l ) {
      each_o.i = i;
      func(arr[i], each_o);
      i = i + 1;
    } // while

  }; // === each


  var to_number_name = function (num) {
    var name = null;
    switch (num) {
      case 0:
        name = 'first';
      break;

      case 1:
        name = 'second';
      break;

      case 2:
        name = 'third';
      break;

      case 3:
        name = 'fourth';
      break;

      case 4:
        name = 'fifth';
      break;

      case 5:
        name = 'sixth';
      break;

      default:
      throw new Error("Unknown value: " + num);
    } // === switch num
    return name;
  }; // function


  var last_types = function (stack, types, stack_name) {
    var o = {};

    if (types.length === 0) {
      throw new Error("No arguments.");
    }

    var vals = _.last(stack, types.length);

    if (vals.length !== types.length) {
      throw new Error('Not enough values in ' + stack_name + '.');
    }

    _.each(types, function (t, i) {
      var val = vals[i];
      var ignore_type = t === 'any' || t === 'last';

      if (!ignore_type) {
        if (_.isString(t)) {
          throw new Error('Unknown position or type: ' + t);
        }

        if (val.constructor !== t) {
          throw new Error('Value in ' + stack_name + " is not a " + func_name(t) + ': ' + inspect(val));
        }
      }

      o[to_number_name(i)] = val;
    });

    if (types.length === 1) {
      return o.first;
    }

    return o;
  }; // last_types

  // ===========================================================================
  // === End Helper Functions ==================================================
  // ===========================================================================

  var funcs =  {
    "focus on" : function (o) {
      o.val('the focus', $(o.left(String)));
      return o.val('the focus');
    },

    "focus on ancestor" : function (o) {
      o.val('the focus', o.val('the focus').parents(o.left(String)));
      return o.val('the focus');
    },

    "submit" : function (o) {
      var form = $(o.val('the focus'));
      var action = form.attr('action');
      if (/[^a-zA-Z0-9\_\-\/]+/.test(action)) {
        throw new Error("Invalid chars in #" + form.attr('id') + " action: " + action);
      }
    },

    "array" : function (o) {
      o.push(o.run_args());
      return o.right('last');
    },

    "add class" : function (o) {
      o.val('the focus').addClass(o.left(String));
      return o.left('last');
    },

    "add to stack": function (o) {
      o.right_concat( o.run_args() );
      return o.run_args();
    },

    "compare numbers" : function (o) {
      var scope = o.scope;
      var first = o.right(Number);

      var args    = o.left(String, Number);
      var compare = args.first;
      var second  = args.second;

      var result = null;

      switch (compare) {

        case '===':
          result = first === second;
        break;

        case '<=':
          result = first <= second;
        break;

        case '<':
          result = first < second;
        break;

        case '>=':
          result = first >= second;
        break;

        case '>':
          result = first > second;
        break;

        default:
          throw new Error("Unknown value : " + compare);
      } // === switch

      o.push(result);
      return result;
    },

    "equal" : function (o) {
      var first  = o.right('any');
      var second = o.left('any');
      o.push(first === second);
      return o.right('last');
    },

    "less or equal" : function (o) {
      o.replace_left(['<=', o.left(Number)]);
      return funcs['compare numbers'](o);
    },

    "less" : function (o) {
      o.replace_left(['<', o.left(Number)]);
      return funcs['compare numbers'](o);
    },

    "bigger" : function (o) {
      o.replace_left(['>', o.left(Number)]);
      return funcs['compare numbers'](o);
    },

    "bigger or equal" : function (o) {
      o.replace_left(['>=', o.left(Number)]);
      return funcs['compare numbers'](o);
    },

    "and": function (o) {
      var first     = o.right(Boolean);
      var second    = null;
      var left_args = null;

      if (first === true) {
        second = o.left(Boolean);

        if (first === true && second === true) {
          o.push(true);
          return true;
        }
      }

      o.push(false);
      return false;
    }, // === and

    "or": function (o) {
      var first     = o.right(Boolean);
      var second    = null;
      var left_args = null;

      if (first === true) {
        o.push(true);
        return true;
      }

      second = o.left(Boolean);

      if (second === true) {
        o.push(true);
        return true;
      }

      o.push(false);
      return false;

    }, // === or

    "if true": function (o) {
      var first = o.right(Boolean);

      if (first) {
        o.run_args();
      }

      return null;
    },

    "if false": function (o) {
      var first = o.right(Boolean);

      if (!first) {
        o.run_args();
      }

      return null;
    },

    "on click": function (o) {
      var scope  = o.child();
      var focus  = scope.var('the focus');
      scope.var('the focus', focus);

      $(focus).click(function () {
        scope.run(o.raw_args());
      });

      return null;
    },

    "on": function (o) {
      return null;
    }

  }; // === funcs ===================================================

  WWW_Applet = {
    funcs : funcs,
    Scope : Scope,
    run   : function (code_array) {
      return (new Scope()).run(code_array);
    } // run
  };

})(); // === WWW_Applet scope



