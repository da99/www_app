
var _     = require('underscore')
_s        = require('underscore.string')
unhtml    = require('unhtml')
special   = require('special-html')
HTML_E    = require('entities')
URI_js    = require('uri-js')
;

var Ok = exports.Ok = function () {};

var ESCAPE = Ok.escape = function (str) {
  return special( _s.escapeHTML( _s.unescapeHTML( HTML_E.decode( str , 2) ) ) );
};

var NL = "\n";

Ok.escape_uri = function (raw) {
  var url = HTML_E.decode(raw, 2);
  var parse = URI_js.parse(url);
  if (parse.errors.length)
    return null
  return URI_js.normalize(url);
};

Ok.throw = function (err_or_msg) {
  var err = (_.isString(err_or_msg)) ?
    (new Error(str_or_arr)) :
    err_or_msg;

  throw err;
};

Ok.new = function (str_or_arr, on_err) {
  var arr = null;

  if (_.isString(str_or_arr)) {
    arr = JSON.parse(str_or_arr);
  }

  if (_.isArray(str_or_arr)) {
    arr = str_or_arr;
  }

  if (!arr) {
    var msg = "Value must be either string or array: " + JSON.stringify(str_or_arr);
    return this.throw(on_err, new Error(msg));
  }

  if (!_.isArray(arr)) {
    var msg = "Value must be an array: " + JSON.stringify(arr);
    return this.throw(on_err, new Error(msg));
  }

  var ok = new Ok;
  ok.code = arr;
  return ok;
};

Ok.prototype.throw = function (on_err, err) {
  if (on_err)
    return on_err(err);
  return Ok.throw(err);
};

Ok.prototype.to_html = function () {
  var me = this;
  var arr = [];
  _.each(this.code, function (val, i) {
    if (_.isObject(val)) {
      arr.push(O_TO_HTML(val));
    } else {
      arr.push(TO_HTML_DIV(val));
    }
  });

  return arr.join(NL);
};

function O_TO_HTML(val) {
  var errs = [];
  var arr  = [];

  _.each(val, function (props, meth) {
    switch (meth) {
      case 'form':
        arr.push(FORM_TO_HTML(props));
      break;
      case 'text_box':
        arr.push(TEXT_BOX_TO_HTML(props));
        break;
      default:
        errs.push('Unknown tag: ' + meth);
    };
  });

  return arr.join(NL);
}

function TO_HTML_DIV(val) {
  return "<div>" + val + "</div>";
}

function FORM_TO_HTML(form) {
  var arr = [];

  _.each(form, function (o, i) {
    arr.push(O_TO_HTML(o));
  });

  return "<form>" + arr.join(NL) + "</form>";
}


function TEXT_BOX_TO_HTML(props) {
  var name         = props[0];
  var default_text = props[1];

  return "<input name=\"" + name + "\" type=\"text\">" + (default_text || "") + "</input>";
}








