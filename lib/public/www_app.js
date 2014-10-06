
"use strict";


$('button').on('click', function (e) {
  e.preventDefault();
  e.stopPropagation();
  e.stopImmediatePropagation();
  return false;
});

var WWW_App = null;


(function () {

  var id_counter = -1;

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


  var id = function (str_or_o) {
    var target = $(str_or_o);
    if (!target.attr('id')) {
      id_counter = id_counter + 1;
      target.attr('id', target.prop('tagName').toLowerCase() + '_' + id_counter);
    }

    return '#' + target.attr('id');
  }; // function


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

    if (types.length === 1 && types[0] === 'all') {
      return stack;
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

  // ================================================================
  // === End Helper Functions =======================================
  // ================================================================


  // ================================================================
  // Scope
  // ================================================================
  var Scope = function (parent) {

    var o         = {};
    var vars      = {};
    var stack     = [];
    var events    = [];

    if (parent) {
      o.parent = parent;
    }

    // ==============================================================
    // ============== stack functions ===============================
    // ==============================================================

    var right = function () {
      return last_types(stack, _.toArray(arguments), 'stack');
    };


    var push = function () {
      var args = _.toArray(arguments);
      _.each(args, function (v) {
        stack.push(v);
      });
      return args;
    }; // push ========================================


    var concat = function (arr) {
      push.apply(null, arr);
      return arr;
    }; // concat ================================


    // ==============================================================
    // ================ run functions ===============================
    // ==============================================================

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

    var run_func = function (name, raw_args) {

      var compiled_args = null;
      var first         = null;
      var second        = null;
      var left_args     = null;
      var target        = null;

      var run_args = function () {
        if (!compiled_args) {
          compiled_args = child().run(raw_args).right('all');
        }

        return compiled_args;
      }; // run_args

      var left = function () {
        return last_types(run_args(), _.toArray(arguments), 'args');
      };

      var replace_left = function (arr) {
        compiled_args = arr;
        return compiled_args;
      };

      switch (name) {

        case 'focus on':
          set('the focus', left(String));
          return the_focus();

        case 'focus on ancestor':
          set('the focus', the_focus().parents(left(String)));
          return get('the focus');

        case 'submit':
            var form   = the_focus();
            var action = form.attr('action');
            if (/[^a-zA-Z0-9\_\-\/]+/.test(action)) {
              throw new Error("Invalid chars in #" + form.attr('id') + " action: " + action);
            }
            return null;

        case 'array':
          push(run_args());
          return right('last');

        case 'add class':
          the_focus().addClass(left(String));
          return left('last');

        case 'add to stack':
          concat( run_args() );
          return run_args();

        case "and":
          first     = right(Boolean);
          second    = null;
          left_args = null;

          if (first === true) {
            second = left(Boolean);

            if (first === true && second === true) {
              push(true);
              return true;
            }
          }

          push(false);
          return false;

        case "or":
          first     = right(Boolean);
          second    = null;
          left_args = null;

          if (first === true) {
            push(true);
            return true;
          }

          second = left(Boolean);

          if (second === true) {
            push(true);
            return true;
          }

          push(false);
          return false;

        case "if true":
          first = right(Boolean);

          if (first) {
            run_args();
          }

          return null;

        case "if false":
          first = right(Boolean);

          if (!first) {
            run_args();
          }

          return null;

        case "on click":
          var focus_selector  = get('the focus');
          var scope  = child();
          scope.set('the focus', focus_selector);

          $(focus_selector).click(function () {
            scope.run(raw_args);
          });

          return null;

        case "on":
          throw new Error('Not ready yet: on');

        case 'bigger or equal':
          return run_func('compare numbers', ['>=', left(Number)]);

        case 'bigger':
          return run_func('compare numbers', ['>', left(Number)]);

        case 'less':
          return run_func('compare numbers', ['<', left(Number)]);

        case 'less or equal':
          return run_func('compare numbers', ['<=', left(Number)]);

        case 'equal':
          first  = right('any');
          second = left('any');
          push(first === second);
          return right('last');

        case 'compare numbers':
          first = right(Number);

          var args    = left(String, Number);
          var compare = args.first;
          second  = args.second;

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

          push(result);
          return result;

        case 'allows':
          var event_name = left(String);
          target     = $(right(String));

          if (!_.contains(['mousedown', 'mouseup', 'focus', 'blur', 'click'], event_name)) {
            throw new Error('Unknown event name: ' + event_name);
          }

          target.off(event_name);
          target.on(event_name, function (e) {

            e.preventDefault();
            e.stopPropagation();
            e.stopImmediatePropagation();

            _.each(events, function (meta) {
              var first = meta.path_tokens[0];
              var second = meta.path_tokens[1];

              if (first === event_name) {

                if (!$(second).is($(e.target))) { return false; }
                var c = child();
                c.push(id(second));
                c.run(meta.code);
                return true;

              } else {

                if ($(e.target).hasClass(first)) {
                  var relative = $(e.target).find(second)[0] || $(e.target).parents(second)[0] || ($(second).is($(e.target)) && e.target);
                  if (!relative) { return false; }
                  var c = child();
                  c.push(id(relative));
                  c.run(meta.code);
                }

              }
            });

            return false;
          });

          return event_name;

        case 'does':
          var path = right(String);

          var meta = {};
          meta.path_tokens = _.map(path.split('/'), function (v) {
            return _.str.trim(v);
          });

          if (meta.path_tokens[0] === '') {
            meta.path_tokens.shift();
          }

          if (meta.path_tokens.length != 2) {
            throw new Error('Unknown path: ' + path);
          }

          events.push({
            code   : raw_args,
            path   : path,
            path_tokens : meta.path_tokens
          });

          return path;

        case 'remove':
          $(right(String)).find(left(String)).remove();
          return null;


        default:
          throw new Error("Function not found: " + name);
      } // === switch name

    }; // run_func ===================================


    // ==============================================================
    // ============= miscel. functions ==============================
    // ==============================================================

    var child = function () {
      return( new Scope(o) );
    };

    var the_focus = function () {
      return $(get('the focus'));
    };

    var set = function (name, val) {
      if (name === 'the focus' && !_.isString(val)) {
        throw new Error("Focus selector must be a String.");
      }

      vars[name] = val;
      return val;
    }; // function

    var get = function (name) {
      if (!vars.hasOwnProperty(name) && !parent) {
        throw new Error('No var found with name: ' + name);
      }

      return (vars.hasOwnProperty(name)) ?
        vars[name] :
        parent.get(name);
    }; // val =========================================

    o.right = right;
    o.get   = get;
    o.set   = get;
    o.push  = push;
    o.run   = run;
    return o;

  // ================================================================
  }; // ===== Scope =================================================
  // ================================================================

  WWW_App = {
    Scope : Scope,
    run   : function (code_array) {
      return (new Scope()).run(code_array);
    } // run
  };

})(); // === WWW_App scope



