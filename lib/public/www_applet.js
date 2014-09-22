
"use strict";

var WWW_Applet = {

  inspect: function (val) {
    try {
      return JSON.stringify(val);
    } catch (e) {
      var c = '' + val.constructor;
      c = _.first(c.split('('));
      c = _.last(c.split('function '));
      return c + ': ' + val;
    }
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

  _args : function (args) {
    if (!_.isObject(args) || !args.hasOwnProperty('length')) {
      WWW_Applet.log(args);
      throw new Error("Arguments object required.");
    }
    return _.toArray(args).slice(1, args.length);
  },

  funcs :  {
    "focus on" : function (scope, name) {
      scope.vars['the focus'] = $(name);
      return scope.vars['the focus'];
    },

    "array" : function (scope, _args) {
      var arr = WWW_Applet._args(arguments);
      scope.stack.push(arr);
      return arr;
    },

    "add class" : function (scope, name) {
      scope.vars['the focus'].addClass(name);
      return name;
    },

    "add to stack": function (scope, _args) {
      var args = WWW_Applet._args(arguments);
      scope.stack = scope.stack.concat(args);
      return args;
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
      return WWW_Applet.funcs['compare numbers'](scope, '===', second);
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
    }

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

  run_func: function (scope, name, args) {
    if (!WWW_Applet.funcs[name]) {
      throw new Error("Function not found: " + name);
    }

    var arg_scope = WWW_Applet.run_in(WWW_Applet.new_scope(scope), args);

    return WWW_Applet.funcs[name].apply(null, [scope].concat(arg_scope.stack));
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
