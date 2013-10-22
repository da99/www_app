
var _     = require('underscore')
_s        = require('underscore.string')
;

var IS_ERROR = function (o) { return (_.isObject(o) && o.constructor == Error); };
var SPACES   = /\ +/g;

// ================================================================
//                    Helpers
// ================================================================

function quote(str) { return '"' + str + '"'; }

function grab_next_args(arr, i, l) {
  var args = [];
  var end_it = false;
  while (i < (l - 1) && !end_it) {
    ++i;
    if (_.isArray(arr[i]) || _.isObject(arr[i]))
      args.push(arr[i]);
    else {
      --i;
      end_it = true;
    }
  }

  return [i, args];
}

function nest_error(curr) {
  var name      = curr.name;
  var func_meta = curr.meta;
  var nest      = curr.app.nesting;
  var child_of  = func_meta.child_of;
  var is_parent = func_meta.is_parent;

  if (!child_of && !is_parent)
    return false;

  if (child_of && !_.contains(nest, child_of))
    return new Error(name + ': can only be used within ' + quote(child_of) + '.');

  if (is_parent && _.where(nest, name).length > 1)
    return new Error(name + ": can not be used within another " + quote(name) + '.');

  return false;
}


// ================================================================
//                    Define Container
// ================================================================

var Applet = exports.Applet = function (source, funcs) {};

// ================================================================
//                    Main Stuff
// ================================================================


Applet.new = function (source, funcs) {
  var me = new Applet;
  me.source  = source;
  me.funcs   = {};
  me.error   = null;
  me.data    = {};
  me.nesting = [];

  if (funcs)
    me.multi_def(funcs);

  return me;
}

Applet.prototype.def = function (name, func) {
  var me = this;
  me.funcs[name] = {child_of: null, func: func, is_parent: false};
  return me;
};

Applet.prototype.def_in = function (parent, name, func) {
  var me = this;
  me.funcs[name] = {child_of: parent, func: func, is_parent: false};
  return me;
};

Applet.prototype.def_parent = function (name, func) {
  var me = this;
  me.funcs[name] = {child_of: null, func: func, is_parent: true};
  return me;
};

Applet.prototype.multi_def = function (funcs) {

  var me = this;

  _.find(funcs, function (v, k) {

    var names   = k.split(SPACES);
    var is_parent = false;
    var parent  = null;
    var name    = null;

    if (names.length === 1) {

      name = names.pop();

    } else if (names.length === 2) {

      if (names[0] !== 'parent') {
        me.error = new Error('Possible typo: ' + k);
        return true;
      }
      name = names[1];
      is_parent = true;

    } else if (names.length === 3) { // parent . child

      if (names[1] !== '.') {
        me.error = new Error('Possible typo: ' + k);
        return true;
      }
      parent = names[0];
      name = names[2];


    } else {
      me.error = new Error('Invalid name format: ' + k);
      return true;
    }

    if (is_parent) {
      me.def_parent(name, v);
    } else if (parent) {
      me.def_in(parent, name, v);
    } else {
      me.def(name, v);
    }

  });

  return me;
};

Applet.prototype.after_run = function (func) {
  var me = this;
  if (!me.after_runs)
    me.after_runs = [];
  me.after_runs.push(func);
  return me;
};

Applet.prototype.save_error = function (err) {
  this.error = err;
  return this;
};

Applet.prototype.run = function (source) {
  var me        = this;
  var code      = (arguments.length === 0) ? me.source : source;
  var l         = code.length;
  var i         = 0;
  var token     = null;
  var next      = null;
  var func_meta = null;
  var results   = [];
  var prev      = null;
  var curr      = null;

  if (!source && me.is_busy)
    return me.save_error(new Error('Applet already running.'));

  if (!source)
    me.is_busy = true;

  while(i < l) {
    token = code[i];

    if (!_.isString(token))
      return me.save_error(new Error("Invalid input: " + token));

    var temp = grab_next_args(code, i, l);

    next = temp[1];
    i    = temp[0];

    func_meta = me.funcs[token];

    if (!func_meta)
      return me.save_error( new Error("Func not found: " + token) );

    curr = {
      prev: prev,
      name: token,
      args: next,
      meta: func_meta,
      data: me.data,
      app:  me,
      error: function (err) {
        if (!err)
          return me.error;
        else {
          me.error = err;
          return me;
        }
      }
    };

    me.nesting.push(token);

    me.error = nest_error(curr);
    if (me.error)
      return me;

    results.push(func_meta.func.apply(null, [curr].concat(next)));
    me.nesting.pop();

    if (me.error)
      return me;

    ++i;
    prev = curr;
  }

  if (source) {
    return {results: results};
  }

  me.is_busy = false;
  me.results = results;

  if (me.after_runs) {
    _.each(me.after_runs, function (func) {
      func(me);
    });
  }

  return me;

};







