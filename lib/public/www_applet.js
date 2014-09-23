
"use strict";

var WWW_Applet = null;


(function () {

  var require = function (_args) {
    var args = _.toArray(arguments);
    var func = args.pop();
    func.right_types = args;
    return func;
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

    var types       = func.right_types || [];
    var right_stack = _.last(scope.stack, types.length);

    // === Check types of right stack
    _.each(types, function (e, i) {
      if (right_stack[i].constructor !== e) {
        throw new Error("Right hand value is not a " + func_name(types[i]) + ': ' + inspect(right_stack[i]));
      }
    });

    var o = {

      'var': function (name, val) {
        var args = _.toArray(arguments);
        switch (args.length) {

          case 1:
            if (!scope.hasOwnProperty(name)) {
            throw new Error('No var found with name: ' + name);
          }
          return scope.vars[name];
          break;

          case 2:
            scope.vars[name] = val;
          return val;
          break;

          default:
            throw new Error("Unknown value: " + args.length);

        } // === switch args.length
      },

      'push': function () {
        var args = _.toArray(arguments);
        scope.stack = scope.stack.concat(args);
        return args;
      },

      'right_last': function () {
        return _.last(scope.stack);
      },

      'left_first': function () {
        return _.first(o.left());
      },

      'right_concat': function () {
      },

      'right': function () {
      },

      'left': function () {
      },

      'replace_left': function (arr) {
      },

      'run_args': function () {
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
    var scope = {
      stack : [],
      vars  : (parent ? parent.vars : {'the focus' : $('no tag')})
    };
    return scope;
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

    "array" : function (o) {
      o.push(o.left());
      return o.right_last();
    },

    "add class" : function (o) {
      o.var('the focus').addClass(o.left(String);
      return o.left_first();
    },

    "add to stack": function (o) {
      o.right_concat( o.left() );
      return o.left();
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
      var first  = o.right('first');
      var second = o.left('second');
      o.push(first === second);
      return o.right_last();
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
      var first     = o.right(Boolean, 'first');
      var second    = null;
      var left_args = null;

      if (first === true) {
        second = o.left(Boolean, 'second');

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
    }

  }; // === funcs

  WWW_Applet = {
    funcs : funcs,
    run   : run
  };

})(); // === WWW_Applet scope



