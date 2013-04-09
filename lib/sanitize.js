
var _     = require('underscore')
_s        = require('underscore.string')
unhtml    = require('unhtml')
special   = require('special-html')
HTML_E    = require('entities')
URI_js    = require('uri-js')
cheerio   = require('cheerio')
;

var NL             = "\n";
var SPACES         = /\ +/g;
var VALID_HTML_ID  = /^[0-9a-zA-Z_]+$/;
var VALID_HTML_TAG = /^[0-9a-zA-Z_]+$/;
var IS_ERROR       = function (o) { return (_.isObject(o) && o.constructor == Error); };
var funcs_scope    = this;
var INSPECT        = function (v) { return JSON.stringify(v); };

var E = exports.Sanitize = {};

// ****************************************************************
// ****************** Sanitize Tag Attributes and content *********
// ****************************************************************


E.name   = function (v) { return E.id(v  , "name"); };
E.href   = function (v) { return E.uri(v , "href"); }
E.action = function (v) { return E.uri(v , 'action'); };

E.string = function (raw, name) {
  name = (name) ? (name + ': ') : '';

  if (_.isString(raw))
    return (raw.trim());

  return new Error(name + "String expected, instead got: " + JSON.stringify(raw));
};

E.uri = function (raw, name) {
  name = (name) ? name : 'uri';

  var val = E.string(raw, name);
  if (E.is_error(val))
    return val;

  var url   = HTML_E.decode(val, 2);
  var parse = URI_js.parse(url);
  if (parse.errors.length)
    return new Error(name + ": " + parse.errors[0] + ': ' + val);

  return URI_js.normalize(url);
};

E.tag = function (raw, name) {
  name = (name) ? name : "tag";

  var val = E.string(raw, name);
  if (E.is_error(val))
    return val;

  if (!val.match(VALID_HTML_TAG))
    return new Error(name + ": invalid characters: " + JSON.stringify(val));

  return val;
};

E.id   = function (raw_val, name) {
  name = (name) ? name : "id";

  var val = E.string(raw_val, name);
  if (val.message)
    return val;

  if (!val.match(VALID_HTML_ID))
    return new Error(name + ": invalid characters: " + JSON.stringify(val));

  return val;
};

E.num_of_lines = function (raw_val, name) {
  name = (name) ? name : 'num_of_lines';

  if (!_.isNumber(raw_val) || _.isNaN(raw_val))
    return new Error(name + ": Must be a number: " + JSON.stringify(raw_val));

  if (raw_val < 1 || raw_val > 250)
    return new Error(name + ": Number out of range: " + JSON.stringify(raw_val));

  return raw_val;
};

E.string_in_array = function (unk, name) {
  name = (name) ? name : 'string_in_array';
  if (_.isArray(unk) && unk.length === 1 && _.isString(unk[0]))
    return unk;
  return new Error(name + ": Must be a string within an array: " + JSON.stringify(unk));
};

var temp = null;
E.attr_funcs = [];
for (temp in E) {
  if (_.isFunction(E[temp])) {
    E.attr_funcs.push(temp);
  }
}

E.opt = function (func, name) {
  return function (v) {
    if (v === undefined || v === null)
      return null;
    return func(v, name);
  };
};

E.is = function (func) {
  return function (v) {
    var result = func(v);
    if (result && result.message)
      return false;
    return !!result;
  };
};

_.each(E.attr_funcs, function (name, i) {
  E["opt_" + name] = E.opt(E[name], name);
  E["is_" + name] = E.is(E[name]);
});

// ****************************************************************
// ****************** End of Sanitize Attr Checkers ***************
// ****************************************************************

E.is_error = function (obj) {
  if (!_.isObject(obj))
    return false;
  return obj.constructor === Error;
};

E.html = function (str) {
  if (!_.isString(str))
    return null;
  return special( _s.escapeHTML( _s.unescapeHTML( HTML_E.decode( str , 2) ) ) );
};


E.attr = function (k, v, tag) {
  if (_.contains(['id', 'name', 'type'], k) && !v.match(VALID_HTML_ID))
    return new Error("Invalid chars in " + tag + " " + k + ": " + v);

  if (!k.match(VALID_HTML_ID))
    return new Error("Invalid chars in " + tag + " attribute name: " + k);

  var safe_name = Ok.escape(k).trim();

  if (_.contains(['href', 'action'], k)) {
    var safe_val  = Ok.escape_uri(v);
    if (!safe_val)
      return new Error('Invalid link address: ' + v);
  } else {
    var safe_val  = Ok.escape(v);
  }

  return [safe_name, safe_val];
};

E.attrs = function (raw_attrs, tag) {
  var sanitized = {};
  var err       = null;

  _.find(raw_attrs, function (v, k) {

    var pair = Ok.escape_attr(k, v, tag);

    if (IS_ERROR(pair)) {
      err = pair;
      return pair;
    }

    sanitized[pair[0]] = pair[1];

  });

  if (err)
    return err;

  return sanitized;
};


E.to_func_calls = function (arr) {
  var next  = null;
  var final = [];
  var line  = null;

  while (arr.length) {
    line = [arr.shift()];
    while(arr.length && !_.isString(arr[0])) {
      line.push(arr.shift());
    }
    final.push(line);
  }

  return final;
};

E.to_applet_func_calls = function (arr) {
  var next  = null;
  var final = [];

  while (arr.length) {
    var name = arr.shift();
    if (!_.isString(name))
      return new Error("No function specfied for arg: " + JSON.stringify(name));
    var attrs = null;
    var body  = null;

    next = arr[0];

    if (!_.isString(next)) {
      if (_.isObject(next) && !_.isArray(next))
        attrs = arr.shift();
      next = arr[0];
      if (_.isArray(next))
        body  = arr.shift();
      next = arr[0];
      if (next && !_.isString(next))
        return new Error(name + ": invalid argument: " + JSON.stringify(next));
    }

    final.push([name, attrs, body]);
  }

  return final;
};



