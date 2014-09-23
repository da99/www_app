
"use strict";

var WWW_Applet = {

  inspect: function (val) {
    var c = '' + (val.constructor || 'Unknown');
    c = _.first(c.split('('));
    c = _.last(c.split('function '));
    return c + ': ' + val;
  },

  is_numeric: function (val) {
    return _.isNumber(val) && !_.isNaN(val);
  },

  log: function () {
    if (!window.console) {
      return;
    }
    return console.log.apply(console, arguments);
  },

  funcs :  {
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

      if (!WWW_Applet.is_numeric(first)) {
        throw new Error("Not numeric: " + WWW_Applet.inspect(first));
      }

      if (!WWW_Applet.is_numeric(second)) {
        throw new Error("Not numeric: " + WWW_Applet.inspect(second));
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
      return WWW_Applet.funcs['compare numbers'](scope, '<=', second);
    },

    "less" : function (scope, second) {
      return WWW_Applet.funcs['compare numbers'](scope, '<', second);
    },

    "bigger" : function (scope, second) {
      return WWW_Applet.funcs['compare numbers'](scope, '>', second);
    },

    "bigger or equal" : function (scope, second) {
      return WWW_Applet.funcs['compare numbers'](scope, '>=', second);
    },

    "and": function (scope, raw_args) {
      var first     = _.last(scope.stack);
      var second    = null;
      var left_args = null;

      if (!_.isBoolean(first)) {
        throw new Error('Right hand value is not a bool: ' + WWW_Applet.inspect(first));
      }

      if (first === true) {
        left_args = WWW_Applet.run_args(scope, raw_args);
        second    = _.last(left_args);

        if (!_.isBoolean(second)) {
          throw new Error('Left hand value is not a bool: ' + WWW_Applet.inspect(second));
        }

        if (first === true && second === true) {
          scope.stack.push(true);
          return true;
        }
      }

      scope.stack.push(false);
      return false;
    } // === and

  }, // === funcs

  each: function (arr, func) {
    var l = arr.length;
    var i = 0;
    var funcs = {

      next: function () {
        if (funcs.is_last()) {
          throw new Error('No more items: i: ' + i + ' total: ' + l);
        }
        return arr[i + 1];
      }, // === next

      prev : function () {
        if (funcs.is_first()) {
          throw new Error('No previous items: i: ' + i + ' total: ' + l);
        }
        return arr[i - 1];
      },

      next_or_null: function () {
        if (funcs.is_last()) { return null; }
        return arr[i + 1];
      },

      prev_or_null : function () {
        if (funcs.is_first()) { return null; }
        return arr[i - 1];
      },

      is_first: function () {
        return i < 1;
      },

      is_last: function () {
        return i >= (l - 1);
      },

      grab_next: function () {
        if (funcs.is_last()) {
          throw new Error('Can\'t grab next because already at last position.');
        }
        i = i + 1;
        return arr[i];
      }

    }; // === funcs

    while ( i < l ) {
      func(arr[i], funcs);
      i = i + 1;
    } // while

  }, // === each

  run_args: function (scope, args) {
    var arg_scope = WWW_Applet.run_in(WWW_Applet.new_scope(scope), args);
    return arg_scope.stack;
  },

  run_func: function (scope, name, args) {
    if (!WWW_Applet.funcs[name]) {
      throw new Error("Function not found: " + name);
    }

    var func        = WWW_Applet.funcs[name];
    var args_list   = func.toString().split(')')[0].split('(')[1].split(/[,\s]+/);
    var args_stack  = [];

    if(_.last(args_list) === 'raw_args') {
      return func.apply(null, [scope, args]);
    } else {
      args_stack = WWW_Applet.run_args(scope, args);
      if (_.last(args_list) === '_args') {
        return func.apply(null, [scope, args_stack]);
      } else {
        return func.apply(null, [scope].concat(args_stack));
      }
    }

  }, // === run_func

  run_in: function (scope, code_array) {

    WWW_Applet.each(code_array, function (item, l) {

      if (_.isArray(item)) {
        throw new Error("Syntax error: args w/o function name.");

      } else if (_.isString(item), _.isArray(l.next_or_null())) {
        WWW_Applet.run_func(scope, item, l.grab_next());

      } else {
        scope.stack.push(item);
      } // === if

    }); // === .each

    return scope;
  }, // === run_in ================

  new_scope : function (parent) {
    var scope = {
      stack : [],
      vars  : (parent ? parent.vars : {'the focus' : $('no tag')})
    };
    return scope;
  },

  run: function (code_array) {

    var scope = WWW_Applet.new_scope();

    return WWW_Applet.run_in(scope, code_array);
  } // === run ====================

};
