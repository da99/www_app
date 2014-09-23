
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

    if(_.last(args_list) === 'raw_args') {
      return func.apply(null, [scope, args]);
    } else {
      args_stack = run_args(scope, args);
      if (_.last(args_list) === '_args') {
        return func.apply(null, [scope, args_stack]);
      } else {
        return func.apply(null, [scope].concat(args_stack));
      }
    }

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
    "focus on" : function (scope, name) {
      scope.vars['the focus'] = $(name);
      return scope.vars['the focus'];
    },

    "array" : function (scope, _args) {
      scope.stack.push(_args);
      return _args;
    },

    "add class" : function (scope, name) {
      scope.vars['the focus'].addClass(name);
      return name;
    },

    "add to stack": function (scope, _args) {
      scope.stack = scope.stack.concat(_args);
      return _args;
    },

    "compare numbers" : function (scope, compare, second) {
      var first = _.last(scope.stack);

      if (!is_numeric(first)) {
        throw new Error("Not numeric: " + inspect(first));
      }

      if (!is_numeric(second)) {
        throw new Error("Not numeric: " + inspect(second));
      }

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

      scope.stack.push(result);
      return result;
    },

    "equal" : function (scope, second) {
      var first = _.last(scope.stack);
      scope.stack.push(first === second);
      return first === second;
    },

    "less or equal" : function (scope, second) {
      return funcs['compare numbers'](scope, '<=', second);
    },

    "less" : function (scope, second) {
      return funcs['compare numbers'](scope, '<', second);
    },

    "bigger" : function (scope, second) {
      return funcs['compare numbers'](scope, '>', second);
    },

    "bigger or equal" : function (scope, second) {
      return funcs['compare numbers'](scope, '>=', second);
    },

    "and": require(Boolean, function (scope, raw_args) {
      var first     = _.last(scope.stack);
      var second    = null;
      var left_args = null;

      if (first === true) {
        left_args = run_args(scope, raw_args);
        second    = _.last(left_args);

        if (!_.isBoolean(second)) {
          throw new Error('Left hand value is not a Boolean: ' + inspect(second));
        }

        if (first === true && second === true) {
          scope.stack.push(true);
          return true;
        }
      }

      scope.stack.push(false);
      return false;
    }), // === and

    "or": require(Boolean, function (scope, raw_args) {
      var first     = _.last(scope.stack);
      var second    = null;
      var left_args = null;

      if (first === true) {
        scope.stack.push(true);
        return true;
      }

      left_args = run_args(scope, raw_args);
      second    = _.last(left_args);

      if (!_.isBoolean(second)) {
        throw new Error('Left hand value is not a Boolean: ' + inspect(second));
      }

      if (second === true) {
        scope.stack.push(true);
        return true;
      }

      scope.stack.push(false);
      return false;

    }), // === or

    "if true": require(Boolean, function (scope, raw_args) {
      var first = _.last(scope.stack);

      if (first) {
        run_args(scope, raw_args);
      }

      return null;
    }),

    "if false": require(Boolean, function (scope, raw_args) {
      var first = _.last(scope.stack);

      if (!first) {
        run_args(scope, raw_args);
      }

      return null;
    })

  }; // === funcs

  WWW_Applet = {
    funcs : funcs,
    run   : run
  };

})(); // === WWW_Applet scope



