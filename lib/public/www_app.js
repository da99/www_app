
"use strict";

(function () {

  function findInScope(key, scope, doModelGet) {
    var val;
    if (scope && typeof scope == 'object' && scope[key] !== undefined && scope[key] !== null) {
      val = scope[key];
    }

    return val;
  }

  // === My monkey-patches to Hogan. ======
  // When a variable is not found,
  // I want to throw an Error.
  // ======================================
  Hogan.Template.prototype.f = function(key, ctx, partials, returnFound) {
    var val    = false,
    v          = null,
    found      = false,
    doModelGet = this.options.modelGet;

    for (var i = ctx.length - 1; i >= 0; i--) {
      v = ctx[i];
      val = findInScope(key, v, doModelGet);
      if (val !== undefined && val !== null) {
        found = true;
        break;
      }
    }

    if (!found) {
      throw new Error("Value not found: " + key);
    }

    return val;
  }; // === .f

  Hogan.Template.prototype.d = function(key, ctx, partials, returnFound) {
    var val,
    names = key.split('.'),
    data  = _.detect(ctx, function (v) { return _.has(v, names[0]);}),
    cx    = null;

    if (key === '.' && isArray(ctx[ctx.length - 2])) {
      throw new Error("Unknown key: " + key);
    }

    val = _.reduce(names, function (memo, v) { return memo && memo[v]}, data);

    if (val == undefined || val == null) {
      throw new Error("Dot-notated value not found: " + key + " in: " + JSON.stringify(ctx));
    }
    return val;
  }; // === .d
  // ======================================
  // End of monkey-patches for Hogan.
  // ======================================

})();



// ======================================
// Start of client-side WWW_App.
// ======================================

var WWW_App = {};

(function () {

  var SPACES            = /\s+/;
  var ALL_KNOWN_CLASSES = 'no_reset reset page_load prepend append no_reset'.split(SPACES);
  var script_meta       = {};
  var compiled          = {};
  var the_scripts       = $('script[type="text/hogan"]');

  // ================================ Helpers
  var auto_id = function (o) {
    if (!_.isNumber(auto_id.counter)) {
      auto_id.counter = -1;
    }
    auto_id.counter = auto_id.counter + 1;

    if (o.attr('id')) {
      return o.attr('id');
    }

    var new_id = "auto_id_" + auto_id.counter;
    $(o).attr('id', new_id);
    return new_id;
  };

  var is_numeric = function (val) {
    return _.isNumber(val) && !_.isNaN(val);
  };

  var classes = function (j) {
    var raw = j.attr('class');

    if (!raw)
      return [];

    var str = _.trim(raw);

    if (_.isEmpty(str))
      return [];

    return str.split(SPACES);
  };

  var known_classes  = function (j) {
    var arr = _.select(classes(j), function (v) {
      return _.contains(ALL_KNOWN_CLASSES, v);
    });
  };

  var custom_classes = function (j) {
    return _.reject(classes(j) ,function (v) {
      return _.contains(ALL_KNOWN_CLASSES, v);
    });
  };

  var every = function (val, func) {
    if (!_.isArray(val)) {
      throw new Error("Value is not an array: " + typeof val);
    }

    if (_.isEmpty(val))
      return false;

    return _.every(val, func);
  };

  var log = function () {
    if (!window.console) { return; }
    return console.log.apply(console, arguments);
  };
  // ==============================================
  // End of helpers.
  // ==============================================

  var run = WWW_App.run = function (arr_of_data) {
    if (!_.isArray(arr_of_data)) {
      throw new Error("Not an array.");
    }

    _.each(arr_of_data, function (data, arr_of_data_i) {
      var displays   = _.has(data, 'display_as') && ((_.isArray(data.display_as) && !_.isEmpty(data.display_as)) || _.isString(data.display_as)) ? data.display_as : null;
      var bag        = _.has(data, 'display_as') ? data.data : data;
      var main_class = null;
      var scripts    = null;
      var is_array   = _.isArray(data);

      if (displays) {
        main_class = displays[0];
        scripts = $(_.select(the_scripts, function (o) { return $(o).hasClass(main_class); }));
      } else {
        scripts = the_scripts;
      }

      scripts.each(function (i) {

        var o                     = $(this);
        var id                    = auto_id(o);

        var all_script_class      = classes(o);
        var custom_script_classes = custom_classes(o);
        var known_script_classes  = known_classes(o);

        var childs                = null;
        var reset_it              = !o.hasClass('no_reset') && !is_array;
        var old_childs            = script_meta[id];
        var render_it             = (!displays && (o.hasClass('page_load') || _.isEmpty(custom_script_classes))) || (displays && every(displays, function (c) { return o.hasClass(c); }));


        // === Reset script.
        //
        if (reset_it && old_childs) {
          old_childs.remove();
        }

        if (render_it) {
          // === Compile.
          //
          if (!compiled[id])
            compiled[id] = Hogan.compile('{{=!{ }!=}}' + "\n" + o.html());
          childs = $(compiled[id].render(bag));

          if (_.isEmpty(childs.html())) {
            childs = null;
          }

          if (reset_it && childs)
            script_meta[id] = childs;

          // === Add to DOM.
          //
          if (childs) {
            if (o.hasClass('prepend') || (is_array && !o.parent().hasClass('append'))) {
              o.parent().prepend(childs);
            } else if (o.hasClass('append') || (is_array && o.parent().hasClass('append'))) {
              o.parent().append(childs);
            } else {
              o.before(childs);
            }
          }

        } // === if render_it

        // === Save results for reset.
        //
        script_meta[id] = childs;
      }); // === each scripts

    }); // === each data


    return this;
  };

  var context = WWW_App.context = [
    {
    html: {
      first: 'Hans',
      last: 'Hoppe',
      movie: 'Sky Captain &amp; The World of Tomorrow',
      author: 'Hoppe'
    }
  },
  {
    display_as: ['news', 'good'],
    data: { 
      html : {
        msg: 'Good' 
      }
    }
  }
  ];

  run(context);
  WWW_App.run = run;

})(); // === WWW_App scope

var load = WWW_App.load;
var context = WWW_App.context;

/**

1) it "adds childs before the script tag"
4) it "does not reset script if data is an Array"

2) it "prepends to parent if script class has 'prepend'"
5) it "prepends to parent if data is an Array"

3) it "appends to parent if script class has 'append'"
6) it "appends to parent if data is an Array and script class has 'append'"

7) Error is thrown if value is underfined in "data".
7) Error is thrown if value is null in "data".

8) it "does not render template if script tag does not contain data.display_as classes"
9) it "renders template if script tag has no classes and there is no data.display_as defined"
9) it "renders template if script tag has a known class (append, prepend, etc) and there is no data.display_as defined"


 **/

// (function () {

  // var VALID_TOUCH_ACTIONS       = ['mousedown', 'mouseup', 'focus', 'blur', 'click'];
  // var all_scopes                = [];
  // var id_counter                = -1;
  // var INVALID_FORM_ACTION_CHARS = /[^a-z0-9\/\.\_]+/g;
  // var MAIN                      = null;
  // var WHITE_SPACE               = /\s+/;


  // // ================================================================
  // // Helper Functions
  // // ================================================================

  // // From:
  // // http://stackoverflow.com/questions/1026069/capitalize-the-first-letter-of-string-in-javascript 
  // var capitalize = function (s) {
    // return s.charAt(0).toUpperCase() + s.substring(1);
  // };


  // var classes = function (raw) {
    // return _.str.trim($(raw).attr('class')).split(WHITE_SPACE);
  // }; // function


  // var tag_name = function (raw) {
    // return ($(raw).prop('tagName') || '').toLowerCase();
  // }; // function


  // var inspect = function (val) {
    // var name = func_name(val.constructor || 'Unknown');
    // return name + ': ' + val;
  // };

  // var form_status = function (form, data, key) {
    // var dom = form.find('div.status_msg:first');
    // if (dom.length === 0) {
      // form.find('div.buttons:first').before('<div class="status_msg"></div>');
      // return form_status(form, data, key);
    // }

    // dom.addClass(key);
    // dom.html(data.clean_html[key]);
    // return dom;
  // }; // function

  // var form_reset_class = function (form, css_class) {
    // form.removeClass('submitted');
    // form.removeClass('loading');
    // form.removeClass('error');
    // form.removeClass('errors');

    // if (css_class === 'errors')
      // css_class = 'error';

    // if (css_class) {
      // form.addClass(css_class);
    // }
    // return form;
  // }; // function


  // var id = function (str_or_o) {
    // var target = $(str_or_o);
    // if (!target.attr('id')) {
      // id_counter = id_counter + 1;
      // target.attr('id', target.prop('tagName').toLowerCase() + '_client_default_id_' + id_counter);
    // }

    // return '#' + target.attr('id');
  // }; // function




  // var func_name = function (raw) {
    // var s    = null;
    // var name = null;

    // if (_.isString(raw)) {
      // s = raw;
    // } else {
      // s = ('' + raw);
    // }

    // name = _.last( _.first(s.split('(')).split('function ') );
    // return name;
  // };

  // var each = function (arr, func) {
    // var l      = arr.length;
    // var i      = 0;
    // var each_o = {

      // next: function () {
        // if (each_o.is_last()) {
          // throw new Error('No more items: i: ' + i + ' total: ' + l);
        // }
        // return arr[i + 1];
      // }, // === next

      // prev : function () {
        // if (each_o.is_first()) {
          // throw new Error('No previous items: i: ' + i + ' total: ' + l);
        // }
        // return arr[i - 1];
      // },

      // next_or_null: function () {
        // if (each_o.is_last()) { return null; }
        // return arr[i + 1];
      // },

      // prev_or_null : function () {
        // if (each_o.is_first()) { return null; }
        // return arr[i - 1];
      // },

      // is_first: function () {
        // return i < 1;
      // },

      // is_last: function () {
        // return i >= (l - 1);
      // },

      // grab_next: function () {
        // if (each_o.is_last()) {
          // throw new Error('Can\'t grab next because already at last position.');
        // }
        // i = i + 1;
        // return arr[i];
      // }

    // }; // === each_o

    // while ( i < l ) {
      // each_o.i = i;
      // func(arr[i], each_o);
      // i = i + 1;
    // } // while

  // }; // === each


  // var to_number_name = function (num) {
    // var name = null;
    // switch (num) {
      // case 0:
        // name = 'first';
      // break;

      // case 1:
        // name = 'second';
      // break;

      // case 2:
        // name = 'third';
      // break;

      // case 3:
        // name = 'fourth';
      // break;

      // case 4:
        // name = 'fifth';
      // break;

      // case 5:
        // name = 'sixth';
      // break;

      // default:
      // throw new Error("Unknown value: " + num);
    // } // === switch num
    // return name;
  // }; // function


  // var last_types = function (stack, types, stack_name) {
    // var o = {};

    // if (types.length === 0) {
      // throw new Error("No arguments.");
    // }

    // if (types.length === 1 && types[0] === 'all') {
      // return stack;
    // }

    // var vals = _.last(stack, types.length);

    // if (vals.length !== types.length) {
      // throw new Error('Not enough values in ' + stack_name + '.');
    // }

    // _.each(types, function (t, i) {
      // var val = vals[i];
      // var ignore_type = t === 'any' || t === 'last';

      // if (!ignore_type) {
        // if (_.isString(t)) {
          // throw new Error('Unknown position or type: ' + t);
        // }

        // if (val.constructor !== t) {
          // throw new Error('Value in ' + stack_name + " is not a " + func_name(t) + ': ' + inspect(val));
        // }
      // }

      // o[to_number_name(i)] = val;
    // });

    // if (types.length === 1) {
      // return o.first;
    // }

    // return o;
  // }; // last_types

  // // ================================================================
  // // === End Helper Functions =======================================
  // // ================================================================


  // // ================================================================
  // // Scope
  // // ================================================================
  // var Scope = function (parent) {

    // var o         = {};
    // var vars      = {};
    // var stack     = [];
    // var events    = [];
    // var scope_log_stack = [];
    // var top       = o;

    // if (parent) {
      // o.parent = parent;
      // while(top.parent) {
        // top = top.parent;
      // }
    // }

    // all_scopes.push(o);

    // var scope_log = function () {
      // return _.each(_.toArray(arguments), function (val) {
        // top.log.push(val);
      // });
    // }; // function

    // var on = function (name, raw_target) {

      // if (name === 'defaults') { // =================================

        // // ========= Setup default actions for "button" tags: =======
        // _.each( $('button'), function (raw_b) {
          // on('click', raw_b);
        // }); // === _.each

        // // ========= Setup default actions for "a" tags: ============
        // _.each( $('a[href]'), function (raw_a) {
          // var a    = $(raw_a);
          // var href = a.attr('href');
          // if (href.indexOf('#') !== 0)
            // return false;

          // var anchor = $('a[name="' + href.replace('#', '') + '"]');
          // if (anchor.length > 0)
            // return false;

          // on('click', a);
        // });

        // return o;
      // } // if 'defaults' ============================================

      // if (!_.contains(VALID_TOUCH_ACTIONS, name)) {
        // throw new Error('Unknown event name: ' + name);
      // }

      // var target = $(raw_target);
      // target.off(name);
      // target.on(name, function (e) {

        // e.preventDefault();
        // e.stopPropagation();
        // e.stopImmediatePropagation();

        // run_does(name, e.target, {event: e});

        // var tag          = tag_name(target);
        // var is_click     = name === 'click';
        // var is_a         = tag === 'a';
        // var is_button    = tag === 'button';
        // var is_submit    = target.hasClass('submit') && target.parents('form:first').length > 0;
        // var is_hash      = is_a && target.attr('href').indexOf('#') === 0;
        // var form_parents = target.parents('form');
        // var is_touch     = _.contains(VALID_TOUCH_ACTIONS, name);

        // if (is_click && is_button && !is_submit ) {
          // _.each(classes(target), function (css) {
            // run_does(css, target, {event: e});
          // });
          // return false;
        // }

        // if (is_click && is_a && !is_submit && is_hash) {
          // var action = target.attr('href').replace('#', '');
          // var no_anchors = $('a[name="' + action + '"]').length === 0;
          // if (no_anchors)
            // run_does(action, target, {event: e});
          // return false;
        // }

        // if (is_submit) {
          // submit_form(e.target, {event: e});
          // return false;
        // }

        // if (is_touch) {
          // _.each(classes(target), function (css) {
            // run_does(css, target, {event: e});
          // });
        // }

        // return false;
      // }); // target.on

    // }; // === on

    // var click_button = function (name, raw_target, options) {
      // var target = $(raw_target);
      // var do_click = !target.hasClass('submit');

      // if (!do_click)
        // return false;

    // }; // function

    // var submit_form = function (raw_target, options) {
      // var e         = options.event;
      // var target    = $(raw_target);
      // var form      = target.parents('form:first');
      // var tag       = tag_name(target);

      // var form_type = _.detect('GET POST PUT DELETE'.split(/\s+/), function (val) {
        // return target.hasClass(val.toLowerCase());
      // }) || 'POST';

      // var form_data = form.serializeObject();
      // if (form_type !== 'GET' && form_type !== 'POST') {
        // form_data._method = form_type;
        // form_type = 'POST';
      // }

      // var is_success = false;
      // var url = form.attr('action');
      // var settings = {
        // type     : form_type,
        // dataType : "json",
        // data     : form_data,
        // success  : function (data,status_str, jxhr) {
          // is_success = true;
          // if (data.clean_html.error_msg) {
            // form_status(form, data, 'error_msg');
            // form_reset_class(form, 'error');
            // run_does('error', target, {event: e, vars: {data: data.data}});
          // } else {
            // form_status(form, data, 'success_msg');
            // form_reset_class(form, 'success');
            // run_does('success', target, {event: e, vars: {data: data.data}});
          // }
        // },
        // error : function (data) {
          // form_status(form, {clean_html: {error_msg: 'An unknown network error has occurred.'}}, 'error_msg');
          // form_reset_class(form, 'error');
        // },
        // complete : function (a,b,c) {
          // form.removeClass('loading');
          // form.addClass('complete');
          // if (!is_success) {
            // form_reset_class(form, 'error');
            // form_status(form, 'An unknown error has occurred.');
          // }
        // }
      // };

      // var invalid = url.match(INVALID_FORM_ACTION_CHARS);
      // if (invalid) {
        // throw new Error('Invalid chars in form action url: ' + invalid.join('') );
      // }

      // form_reset_class(form, 'loading');
      // $.ajax(url, settings);

    // }; // submit_form_if_needed

    // var run_does = function (event_name, raw_target, options) {

      // var target = $(raw_target);

      // _.each(events, function (meta) {
        // var first    = meta.path_tokens[0];

        // if (first !== event_name)
          // return false;

        // var second   = meta.path_tokens[1];
        // var third    = meta.path_tokens[2];
        // var relative = (third || second) ? relative_id(target, (third || second)) : null;

        // var is_touch  = _.contains(VALID_TOUCH_ACTIONS, event_name);
        // var is_target = second && $(second).is(target);
        // var is_css    = target.hasClass(event_name);
        // var is_href   = tag_name(target) === 'a' && target.attr('href') === ('#' + event_name);
        // var push_target = null;

        // // === "/click/button.something/relative"
        // if (is_touch && is_target && third && relative)
          // push_target = relative;

        // else { // === "/click/button.something"
          // if (is_touch && is_target && !third)
            // push_target = id(target);

          // else { // === "/red/relative"
            // if ((is_css || is_href) && !third && relative)
              // push_target = relative;

            // else { // "/red"
              // if (is_css && !second && !third)
                // push_target = id(target);

              // else { // /success/#form_1
                // if (!third && first === event_name && relative)
                  // push_target = relative;
              // }
            // }
          // }
        // }

        // if (push_target)
          // return child(options.vars).push(push_target).run(meta.code);

        // return false;
      // });
    // }; // function


    // // ==============================================================
    // // ============== stack functions ===============================
    // // ==============================================================

    // var right = function () {
      // return last_types(stack, _.toArray(arguments), 'stack');
    // };


    // var push = function () {
      // var args = _.toArray(arguments);
      // _.each(args, function (v) {
        // stack.push(v);
      // });
      // return o;
    // }; // push ========================================


    // var concat = function (arr) {
      // push.apply(null, arr);
      // return arr;
    // }; // concat ================================


    // var relative_id = function (target, selector) {
      // if (!selector)
        // throw new Error('Invalid selector: ' + selector);

      // var relative = $(target).find(selector)[0] || $(target).parents(selector)[0] || ($(target).is($(selector)) && target);
      // if (relative) {
        // return id(relative);
      // }
      // return null;
    // };

    // // ==============================================================
    // // ================ run functions ===============================
    // // ==============================================================

    // var run = function (code_array) {
      // each(code_array, function (item, l) {

        // if (_.isArray(item)) {
          // throw new Error("Syntax error: args w/o function name.");

        // } else if (_.isString(item), _.isArray(l.next_or_null())) {
          // run_func(item, l.grab_next());

        // } else {
          // stack.push(item);
        // } // === if

      // }); // === .each

      // return o;
    // }; // run ========================================

    // var run_func = function (name, raw_args) {

      // var compiled_args = null;
      // var first         = null;
      // var second        = null;
      // var left_args     = null;
      // var target        = null;

      // var run_args = function () {
        // if (!compiled_args) {
          // compiled_args = child().run(raw_args).right('all');
        // }

        // return compiled_args;
      // }; // run_args

      // var left = function () {
        // return last_types(run_args(), _.toArray(arguments), 'args');
      // };

      // var replace_left = function (arr) {
        // compiled_args = arr;
        // return compiled_args;
      // };

      // switch (name) {

        // case 'get':
          // return push(get(left(String)));

        // case 'focus on ancestor':
          // set('the focus', the_focus().parents(left(String)));
          // return get('the focus');

        // case 'submit':
            // var form   = the_focus();
            // var action = form.attr('action');
            // if (/[^a-zA-Z0-9\_\-\/]+/.test(action)) {
              // throw new Error("Invalid chars in #" + form.attr('id') + " action: " + action);
            // }
            // return null;

        // case 'array':
          // push(run_args());
          // return right('last');

        // case 'remove class':
          // the_focus().removeClass(left(String));
          // return left('last');

        // case 'add class':
          // the_focus().addClass(left(String));
          // return left('last');

        // case 'add to stack':
          // concat( run_args() );
          // return run_args();

        // case "and":
          // first     = right(Boolean);
          // second    = null;
          // left_args = null;

          // if (first === true) {
            // second = left(Boolean);

            // if (first === true && second === true) {
              // push(true);
              // return true;
            // }
          // }

          // push(false);
          // return false;

        // case "or":
          // first     = right(Boolean);
          // second    = null;
          // left_args = null;

          // if (first === true) {
            // push(true);
            // return true;
          // }

          // second = left(Boolean);

          // if (second === true) {
            // push(true);
            // return true;
          // }

          // push(false);
          // return false;

        // case "if true":
          // first = right(Boolean);

          // if (first) {
            // run_args();
          // }

          // return null;

        // case "if false":
          // first = right(Boolean);

          // if (!first) {
            // run_args();
          // }

          // return null;

        // case 'log':
          // scope_log.apply(null, run_args());
          // return run_args();

        // case "on click":
          // var focus_selector  = get('the focus');
          // var scope  = child();
          // scope.set('the focus', focus_selector);

          // $(focus_selector).click(function () {
            // scope.run(raw_args);
          // });

          // return null;

        // case "on":
          // throw new Error('Not ready yet: on');

        // case 'bigger or equal':
          // return run_func('compare numbers', ['>=', left(Number)]);

        // case 'bigger':
          // return run_func('compare numbers', ['>', left(Number)]);

        // case 'less':
          // return run_func('compare numbers', ['<', left(Number)]);

        // case 'less or equal':
          // return run_func('compare numbers', ['<=', left(Number)]);

        // case 'equal':
          // first  = right('any');
          // second = left('any');
          // push(first === second);
          // return right('last');

        // case 'compare numbers':
          // first = right(Number);

          // var args    = left(String, Number);
          // var compare = args.first;
          // second  = args.second;

          // var result = null;

          // switch (compare) {

            // case '===':
              // result = first === second;
            // break;

            // case '<=':
              // result = first <= second;
            // break;

            // case '<':
              // result = first < second;
            // break;

            // case '>=':
              // result = first >= second;
            // break;

            // case '>':
              // result = first > second;
            // break;

            // default:
              // throw new Error("Unknown value : " + compare);
          // } // === switch

          // push(result);
          // return result;

        // case 'allows':
          // var event_name = left(String);
          // target     = $(right(String));

          // on(event_name, target);
          // return event_name;

        // case 'does':
          // var path = right(String);

          // var meta = {};
          // meta.path_tokens = _.map(path.split('/'), function (v) {
            // return _.str.trim(v);
          // });

          // if (meta.path_tokens[0] === '') {
            // meta.path_tokens.shift();
          // }

          // if (meta.path_tokens.length < 1 || meta.path_tokens.length > 3) {
            // throw new Error('Unknown path: ' + path);
          // }

          // events.push({
            // code        : raw_args,
            // path        : path,
            // path_tokens : meta.path_tokens
          // });

          // return path;

        // case 'remove':
          // $(right(String)).find(left(String)).remove();
          // return null;


        // default:
          // throw new Error("Function not found: " + name);
      // } // === switch name

    // }; // run_func ===================================


    // // ==============================================================
    // // ============= miscel. functions ==============================
    // // ==============================================================

    // var child = function (vars) {
      // var s = new Scope(o);
      // if (vars) {
        // _.each(vars, function (val, key) {
          // s.set(key, val);
        // });
      // }
      // return( s );
    // };

    // var the_focus = function () {
      // return $(right(String));
    // };

    // var set = function (name, val) {
      // vars[name] = val;
      // return val;
    // }; // function

    // var get = function (name) {
      // if (!vars.hasOwnProperty(name) && !parent) {
        // throw new Error('No var found with name: ' + name);
      // }

      // return (vars.hasOwnProperty(name)) ?
        // vars[name] :
        // parent.get(name);
    // }; // val =========================================


    // o.run   = run;

    // // ====================================================
    // // The following functions
    // // are meant to be used by WWW_App.run.
    // // Don't use them.
    // // ====================================================
    // o.right = right;
    // o.get   = get;
    // o.set   = set;
    // o.push  = push;
    // o.on    = on;
    // o.log   = scope_log_stack;
    // // ====================================================

    // return o;

  // // ================================================================
  // }; // ===== Scope =================================================
  // // ================================================================

  // WWW_App = {
    // run : function (code_array) {
      // WWW_App.MAIN = (new Scope()).on('defaults').run(code_array);
      // return WWW_App.MAIN;
    // }
  // };

  // WWW_App.run([]);

// })(); // === WWW_App scope



