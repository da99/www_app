
"use strict";


var WWW_App = null;


(function () {

  var VALID_TOUCH_ACTIONS       = ['mousedown', 'mouseup', 'focus', 'blur', 'click'];
  var all_scopes                = [];
  var id_counter                = -1;
  var INVALID_FORM_ACTION_CHARS = /[^a-z0-9\/\.\_]+/g;
  var MAIN                      = null;


  // ================================================================
  // Helper Functions
  // ================================================================

  // From:
  // http://stackoverflow.com/questions/1026069/capitalize-the-first-letter-of-string-in-javascript 
  var capitalize = function (s) {
    return s.charAt(0).toUpperCase() + s.substring(1);
  };


  var tag_name = function (raw) {
    return ($(raw).prop('tagName') || '').toLowerCase();
  }; // function


  var inspect = function (val) {
    var name = func_name(val.constructor || 'Unknown');
    return name + ': ' + val;
  };


  var form_error = function (form, msg) {
    form_reset_class(form, 'errors');
  }; // function


  var form_success = function (form, msg) {
    form_reset_class(form, 'success');
  };


  var form_loading = function (form) {
    form_reset_class(form, 'loading');
    return form;
  }; // function


  var form_reset_class = function (form, css_class) {
    form.removeClass('submitted');
    form.removeClass('loading');
    form.removeClass('errors');
    if (css_class) {
      form.addClass(css_class);
    }
    return form;
  }; // function


  var id = function (str_or_o) {
    var target = $(str_or_o);
    if (!target.attr('id')) {
      id_counter = id_counter + 1;
      target.attr('id', target.prop('tagName').toLowerCase() + '_client_default_id_' + id_counter);
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
    var scope_log_stack = [];
    var top       = o;

    if (parent) {
      o.parent = parent;
      while(top.parent) {
        top = top.parent;
      }
    }

    all_scopes.push(o);

    var scope_log = function () {
      return _.each(_.toArray(arguments), function (val) {
        top.log.push(val);
      });
    }; // function

    var on = function (name, raw_target) {
      if (!_.contains(VALID_TOUCH_ACTIONS, name)) {
        throw new Error('Unknown event name: ' + name);
      }

      var target = $(raw_target);
      target.off(name);
      target.on(name, function (e) {

        e.preventDefault();
        e.stopPropagation();
        e.stopImmediatePropagation();

        run_does(name, e.target, {event: e});
        link_as_button(name, e.target, {event: e});
        submit_form(name, e.target, {event: e});

        return false;
      }); // target.on

    }; // === on


    var link_as_button = function (name, raw_target, options) {
      if (name !== 'click')
        return false;

      var tag = tag_name(raw_target);
      if (tag !== 'a')
        return false;

      var target = $(raw_target);
      if (target.hasClass('submit'))
        return false;

      var href = target.attr('href');
      if (href.indexOf('#') !== 0)
        return false;

      var action = href.replace('#', '');
      run_does(action, target, options);

      return true;
    }; // function

    var submit_form = function (event_name, raw_target, options) {
      if (event_name !== 'click')
        return false;

      var e         = options.event;
      var target    = $(raw_target);
      var form      = $(target.parents('form')[0]);
      var tag       = tag_name(target);
      var do_submit = (tag === 'a' || tag === 'button') && form.length === 1 && target.hasClass('submit');

      if (!do_submit)
        return false;

        var form_type = _.detect('GET POST PUT DELETE'.split(/\s+/), function (val) {
          return target.hasClass(val.toLowerCase());
        }) || 'POST';

        var form_data = form.serializeObject();
        if (form_type !== 'GET' && form_type !== 'POST') {
          form_data._method = form_type;
          form_type = 'POST';
        }

        var is_success = false;
        var url = form.attr('action');
        var settings = {
          type     : form_type,
          dataType : "json",
          data     : form_data,
          success  : function (data,status_str, jxhr) {
            is_success = true;
            form_success(form, "Success");
            run_does('success', target, {event: e, vars: {data: data.data}});
          },
          error : function (a,b,c) {
            log(a,b,c);
            form_error(form, 'An unknown network error has occurred.');
          },
          complete : function (a,b,c) {
            form.removeClass('loading');
            form.addClass('complete');
            if (!is_success) {
              form_error(form, 'An unknown error has occurred.');
            }
          }
        };

        var invalid = url.match(INVALID_FORM_ACTION_CHARS);
        if (invalid) {
          throw new Error('Invalid chars in form action url: ' + invalid.join('') );
        }

        form_loading(form);
        $.ajax(url, settings);


    }; // submit_form_if_needed

    var run_does = function (event_name, raw_target, options) {

      var target = $(raw_target);

      _.each(events, function (meta) {
        var first    = meta.path_tokens[0];
        var second   = meta.path_tokens[1];
        var third    = meta.path_tokens[2];
        var relative = relative_id(target, ( (third) ? third : second ));

        var is_touch  = _.contains(VALID_TOUCH_ACTIONS, event_name);
        var is_target = second && $(second).is(target);
        var is_css    = target.hasClass(event_name);
        var is_href   = tag_name(target) === 'a' && target.attr('href') === ('#' + event_name)
        var push_target = null;

        // === "/click/button.something/relative"
        if (is_touch && is_target && third && relative)
          push_target = relative;

        // === "/click/button.something"
        if (is_touch && is_target && !third)
          push_target = id(target);

        // === "/red/relative"
        if ((is_css || is_href) && !third && relative)
          push_target = relative;

        if (push_target)
          return child(options.vars).push(push_target).run(meta.code);

        return false;
      });
    }; // function


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
      return o;
    }; // push ========================================


    var concat = function (arr) {
      push.apply(null, arr);
      return arr;
    }; // concat ================================


    var relative_id = function (target, selector) {
      var relative = $(target).find(selector)[0] || $(target).parents(selector)[0] || ($(target).is($(selector)) && target);
      if (relative) {
        return id(relative);
      }
      return null;
    };

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

        case 'get':
          return push(get(left(String)));

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

        case 'log':
          scope_log.apply(null, run_args());
          return run_args();

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

          on(event_name, target);
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

          if (meta.path_tokens.length < 1 || meta.path_tokens.length > 3) {
            throw new Error('Unknown path: ' + path);
          }

          events.push({
            code        : raw_args,
            path        : path,
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

    var child = function (vars) {
      var s = new Scope(o);
      if (vars) {
        _.each(vars, function (val, key) {
          s.set(key, val);
        });
      }
      return( s );
    };

    var the_focus = function () {
      return $(right(String));
    };

    var set = function (name, val) {
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


    o.run   = run;

    // ====================================================
    // The following functions
    // are meant to be used by WWW_App.run.
    // Don't use them.
    // ====================================================
    o.right = right;
    o.get   = get;
    o.set   = set;
    o.push  = push;
    o.on    = on;
    o.log   = scope_log_stack;
    // ====================================================

    return o;

  // ================================================================
  }; // ===== Scope =================================================
  // ================================================================

  WWW_App = {};

  WWW_App.run = function (code_array) {
    var scope = (new Scope());

    // ========= Setup default actions for "button" tags: ===============
    _.each( $('button'), function (raw_b) {
      scope.on('click', raw_b);
    }); // === _.each

    // ========= Setup default actions for "a" tags: ================
    _.each( $('a[href]'), function (raw_a) {
      var a    = $(raw_a);
      var href = a.attr('href');
      if (href.indexOf('#') !== 0)
        return false;

      var anchor = $('a[name="' + href.replace('#', '') + '"]');
      if (anchor.length > 0)
        return false;

      scope.on('click', a);
    });


    WWW_App.MAIN = scope.run(code_array);
    return WWW_App.MAIN;
  };

  WWW_App.run([]);

})(); // === WWW_App scope



