
"use strict";

var WWW_Applet = null;


(function () {

  var read_var = function (o, name) {
    if (!o.vars.hasOwnProperty(name)) {
      if (!o.parent) {
        throw new Error('No var found with name: ' + name);
      }
      return read_var(o.parent, name);
    }
    return o.vars[name];
  };

  // From:
  // http://stackoverflow.com/questions/1026069/capitalize-the-first-letter-of-string-in-javascript 
  var capitalize = function (s) {
    return s.charAt(0).toUpperCase() + s.substring(1);
  };

  var get_tail_by_types = function (o, stack, types, stack_name) {
    if (types.length === 0) {
      throw new Error("No arguments.");
    }

    var vals = _.last(stack, types.length);
    var any  = ['any', 'last'];

    if (vals.length !== types.length) {
      throw new Error('Not enough in ' + stack_name + 's.');
    }

    _.each(types, function (t, i) {
      if (_.isString(t) && !_.contains(any, t)) {
        throw new Error('Unknown position: ' + t);
      }

      var val = vals[i];
      if (!_.contains(any, t) && val.constructor !== t) {
        throw new Error(capitalize(stack_name) + " is not a " + func_name(t) + ': ' + inspect(val));
      }

      o[to_number_name(i)] = val;
    });

    if (types.length === 1) {
      return o.first;
    }

    return vals;
  }; // function

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

  var run_args = function (scope, args) {
    var arg_scope = run_in(new_scope(scope), args);
    return arg_scope.stack;
  };

  var run_func = function (scope, name, args) {
    if (!funcs[name]) {
      throw new Error("Function not found: " + name);
    }

    var func        = funcs[name];
    var args_list   = func.toString().split(')')[0].split('(')[1].split(/[,\s]+/);
    var args_stack  = [];

    var o = {

      'scope' : scope,

      'var': function (name, val) {
        var args       = _.toArray(arguments);
        var return_val = null;
        switch (args.length) {

          case 1:
            return_val = read_var(scope, name);
          break;

          case 2:
            scope.vars[name] = val;
          return_val = val;
          break;

          default:
            throw new Error("Unknown value: " + args.length);

        } // === switch args.length

        return return_val;
      },

      'push': function () {
        var args = _.toArray(arguments);
        scope.stack = scope.stack.concat(args);
        return args;
      },

      'right_concat': function (arr) {
        scope.stack = scope.stack.concat(arr);
        return arr;
      },

      'right': function () {
        return get_tail_by_types(o, scope.stack, _.toArray(arguments), 'stack value');
      },

      'left': function () {
        return get_tail_by_types(o, o.run_args(), _.toArray(arguments), 'arg');
      },

      'replace_left': function (arr) {
        o._left_args = arr;
        return o._left_args;
      },

      'run_args': function () {
        if (o._left_args) {
          return o._left_args;
        }
        o._left_args = run_args(scope, args);
        return o._left_args;
      },

      'raw_args': function () {
        return args;
      }

    };

    return func.apply(null, [o]);

  }; // === run_func

  var run_in = function (scope, code_array) {

    each(code_array, function (item, l) {

      if (_.isArray(item)) {
        throw new Error("Syntax error: args w/o function name.");

      } else if (_.isString(item), _.isArray(l.next_or_null())) {
        run_func(scope, item, l.grab_next());

      } else {
        scope.stack.push(item);
      } // === if

    }); // === .each

    return scope;
  }; // === run_in ================

  var new_scope = function (parent) {
    var o = {
      stack  : [],
      vars   : {}
    };

    if (parent) {
      o.parent = parent;
    }

    return o;
  };

  var run = function (code_array) {

    var scope = new_scope();

    return run_in(scope, code_array);
  }; // === run ====================

  var funcs =  {
    "focus on" : function (o) {
      o.var('the focus', $(o.left(String)));
      return o.var('the focus');
    },

    "focus on ancestor" : function (o) {
      o.var('the focus', o.var('the focus').parents(o.left(String)));
      return o.var('the focus');
    },

    "submit" : function (o) {
      var form = $(o.var('the focus'));
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
      o.var('the focus').addClass(o.left(String));
      return o.left('last');
    },

    "add to stack": function (o) {
      o.right_concat( o.run_args() );
      return o.run_args();
    },

    "compare numbers" : function (o) {
      var scope = o.scope;
      var first = o.right(Number);

      o.left(String, Number);
      var compare = o.first;
      var second  = o.second;

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
      var parent = o.scope
      var scope  = new_scope(parent);
      var focus  = read_var(scope, 'the focus');
      scope.vars['the focus'] = focus;

      $(focus).click(function () {
        run_in(scope, o.raw_args());
      });

      return null;
    },

    "on": function (o) {
      return null;
    }

  }; // === funcs

  WWW_Applet = {
    funcs : funcs,
    run   : run
  };

})(); // === WWW_Applet scope



