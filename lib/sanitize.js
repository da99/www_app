
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

E.uri = function (raw) {
  if (!_.isString(raw))
    return null;
  var url = HTML_E.decode(raw, 2);
  var parse = URI_js.parse(url);
  if (parse.errors.length)
    return null
  return URI_js.normalize(url);
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







