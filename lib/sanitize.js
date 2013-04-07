
var _     = require('underscore')
_s        = require('underscore.string')
unhtml    = require('unhtml')
special   = require('special-html')
HTML_E    = require('entities')
URI_js    = require('uri-js')
cheerio   = require('cheerio')
;

var NL            = "\n";
var VALID_HTML_ID = /^[0-9a-zA-Z_]+$/;
var IS_ERROR      = function (o) { return (_.isObject(o) && o.constructor == Error); };
var funcs_scope   = this;

var E = exports.Sanitize = function (str) {
  if (!_.isString(str))
    return null;
  return special( _s.escapeHTML( _s.unescapeHTML( HTML_E.decode( str , 2) ) ) );
};

// ****************************************************************
// ****************** Sanitize Tag Attributes and content *********
// ****************************************************************


E.uri = function (raw) {
  if (!_.isString(raw))
    return null;
  var url = HTML_E.decode(raw, 2);
  var parse = URI_js.parse(url);
  if (parse.errors.length)
    return null
  return URI_js.normalize(url);
};

E.string = function (raw_val) {
  return (_.isString(raw_val)) ?
    _.trim(raw_val) :
    null;
};

E.button_type = function (raw_val) {
  var v = E.string(raw_val);
  if (v === 'text' || v === 'button')
    return v;
  return null;
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

E.name = function (raw_val) { return E.id(raw_val); };

E.id   = function (raw_val) {
  if (!_.isString(raw_val))
    return null;

  var v = _.trim(raw_val);
  if (!v.match(VALID_HTML_ID))
    return null;
  return v;
};

E.href = function (raw_val) { return E.action(raw_val); }

E.action = function (raw_val) {
  if (!_.isString(raw_val))
    return null;

  var v = _.trim(raw_val);
  if (_.isEmpty(v))
    return null;

  return E.uri(v);
};

E.num_of_lines = function (raw_val) {
  if (!_.isNumber(raw_val) || _.isNaN(raw_val))
    return null;

  if (raw_val < 1 || raw_val > 250)
    return null;

  return raw_val;
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

E.string_body = function (unk) {
  var flatten = _.flatten([unk]);
  var l       = flatten.length;
  if (l === 1 && _.isString(flatten[0]))
    return flatten[0];
  return null;
};

E.opt = function (func) {
  var new_func    = function (raw_val) { return func(raw_val); };
  new_func.is_opt = true;
  new_func.name   = func.name;
  return new_func;
}

// ****************************************************************
// Add .name to sanitize/validation functions
// that will be used in error messages.
// ****************************************************************
for (prop_name in E) {
  var temp = E[prop_name];
  if (_.isFunction(temp) &&
      !temp.hasOwnProperty('name') &&
        prop_name !== 'opt') {
    temp.name = prop_name;
    E['opt_' + prop_name] = E.opt(temp);
  }
}

E.args = function args(reqs, args) {
  var args_l = standardize_arg_length(reqs, args);
  var err = null;

  if (args_l.error)
    return args_l;

  args = args_l.update;
  var final = {};

  _.find(reqs, function (r, i) {
    var valid =  (_.isFunction(r)) ?  r(args[i]) : validate_named_args(r, args[i]);
    if (valid.error) {
      err = valid;
      return err;
    }
    final = _.extend(final, valid.update);
  });

  if (err)
    return err;

  return {update: final};
}

E.named_args = function (reqs, args) {
  if (_.isObject(args))
    return {error: new Error('Named args not in an object: ' + JSON.stringify(args))};

  var final = {};
  var err   = null;

  _.find(reqs, function (r, name) {
    var results = r(args[name]);
    if (results.error) {
      err = results;
      return err;
    }

    final[name] = results.update;
  });

  if (err)
    return err;

  return {update: final};
}



// ****************************************************************
// ****************** Potentially Obsolete ************************
// ****************************************************************




function find_err(raw_val) {
  var err = null;
  var val = {update: raw_val};
  _.each(_.toArray(arguments).slice(1), function (f) {
    var result = f(val.update);
    if (result.error)
      err = result;
    val = result;
    return err;
  });

  if (err)
    return err;
  return val;
}


function standardize_arg_length(reqs, args) {
  if (!_.isArray(args))
    args = [args];

  var args_l = args.length;
  var reqs_l = reqs.length;

  if (args_l === reqs_l)
    return {update: args};

  if (args_l > reqs_l)
    return {error: new Error('Too many args: ' + JSON.stringify(args))};

  var args = args.slice();
  var last_req = _.last(reqs);
  var last_arg = _.last(args);
  if (_.isObject(last_req) && !_.isObject(last_arg))
    args.push({});
  else
    args.push(undefined);

  return standardize_arg_length(reqs, args);
}

