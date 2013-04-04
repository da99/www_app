
var _     = require('underscore')
_s        = require('underscore.string')
;

var IS_ERROR = function (o) { return (_.isObject(o) && o.constructor == Error); };
var SPACES   = /\ +/g;

var Main = exports.Applet = function (source, funcs) {
  return new Applet(source, funcs);
};

var Applet = function (source, funcs) {
  var me = this;

  me.source = source;
  me.funcs  = {};
  me.error  = null;
  me.data   = {};
  me.is_busy = false; // -> is it "compiling" code?

  if (funcs)
    me.multi_def(funcs);

  return me;
};

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
    return {error: new Error('Applet already running.')};
  if (!source)
    me.is_busy = true;

  while(i < l) {
    token = code[i];

    if (!token)
      return { error: new Error("Invalid input: " + token) };

    var temp = grab_next_arrays(code, i, l);

    next = temp[1];
    i    = temp[0];

    func_meta = me.funcs[token];

    if (!func_meta)
      return {error: new Error("Func not found: " + token)};

    curr = {
      prev: prev,
      name: token,
      args: next,
      meta: func_meta,
      data: me.data,
      app:  me
    };

    results.push(func_meta.func.apply(null, next.concat([curr])));
    ++i;
    prev = curr;
  }

  if (!source)
    me.is_busy = false;
  return results;
};

function grab_next_arrays(arr, i, l) {
  var args = [];

  while (i < (l - 1)) {
    ++i;
    if (_.isArray(arr[i]))
      args.push(arr[i]);
  }

  return [i, args];
}








