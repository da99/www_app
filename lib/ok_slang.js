
var _     = require('underscore')
_s        = require('underscore.string')
unhtml    = require('unhtml')
special   = require('special-html')
HTML_E    = require('entities')
URI_js    = require('uri-js')
;

var VALID_HTML_ID = /^[0-9a-zA-Z_]+$/;
var NL = "\n";

var Ok = exports.Ok = function () {};

var ESCAPE = Ok.escape = function (str) {
  return special( _s.escapeHTML( _s.unescapeHTML( HTML_E.decode( str , 2) ) ) );
};


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

  ok.throw = function (err) {
    return Ok.throw(err);
  };

  return ok;
};

Ok.prototype.to_html = function (on_err) {

  var me = this;
  var arr = [];

  if (!on_err)
    on_err = me.throw;

  _.each(this.code, function (val, i) {
    if (_.isObject(val)) {
      arr.push(O_TO_HTML(val, on_err));
    } else {
      arr.push(TO_HTML_DIV(val, on_err));
    }
  });

  return arr.join(NL);
};

function O_TO_HTML(val, on_err) {
  var errs = [];
  var arr  = [];

  _.each(val, function (props, meth) {
    switch (meth) {
      case 'form':
        arr.push(FORM_TO_HTML(props, on_err));
      break;
      case 'text_box':
        arr.push(TEXT_BOX_TO_HTML(props, on_err));
        break;
      case 'button':
        arr.push(BUTTON_TO_HTML(props, on_err));
      break;
      default:
        errs.push('Unknown element: ' + meth);
    };
  });

  if (errs.length)
    return on_err(new Error(errs[0]));

  return arr.join(NL);
}

function TO_HTML_DIV(val) {
  return "<div>" + val + "</div>";
}

function FORM_TO_HTML(form, on_err) {
  var arr = [];

  _.each(form, function (o, i) {
    arr.push(O_TO_HTML(o, on_err));
  });

  return "<form>" + arr.join(NL) + "</form>";
}


function TEXT_BOX_TO_HTML(props, on_err) {
  var name         = props[0];
  var default_text = props[1];

  return HTML_Element('input', {id: name, name: name, type: "text", ok_type: 'text_box'}, (default_text || ""), on_err);
}

function BUTTON_TO_HTML(props, on_err) {
  var name = props[0] || "";
  var text = props[1] || "";

  return HTML_Element('button', {id: name, ok_type: 'button'}, text, on_err);
}

function HTML_Element(raw_tag, raw_props, raw_text, on_err) {
  var tag = Ok.escape(raw_tag);
  var text = Ok.escape(raw_text);
  var props = {};

  var ok_type = raw_props.ok_type || "";
  delete raw_props['ok_type'];

  var err_msg = null;
  var err = _.find(raw_props, function (v, k) {
    if (_.contains(['id', 'name', 'type'], k) && !v.match(VALID_HTML_ID)) {
        err_msg = "Invalid chars in " + ok_type + " " + k + ": " + v;
        return true
    }

    if (!k.match(VALID_HTML_ID)) {
      err_msg = "Invalid chars in " + ok_type + " attribute name: " + k;
      return true;
    }

    var safe_name = Ok.escape(k).trim();
    var safe_val  = (k == 'href') ? Ok.escape_uri(v) : Ok.escape(v);
    props[safe_name] = safe_val;
  });

  if (err)
    return on_err(new Error(err_msg));

  var prop_text = _.map(props, function (v, k) {
    return k + '="' + v + '"';
  }).join(' ');

  return "<" + tag + " " + prop_text + ">" + text + "</" + tag + ">";
}






