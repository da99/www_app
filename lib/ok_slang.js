
var _     = require('underscore')
_s        = require('underscore.string')
unhtml    = require('unhtml')
special   = require('special-html')
HTML_E    = require('entities')
URI_js    = require('uri-js')
;

var NL            = "\n";
var VALID_HTML_ID = /^[0-9a-zA-Z_]+$/;
var IS_ERROR      = function (o) { return (_.isObject(o) && o.prototype === Error); };

var Ok = exports.Ok = function () {};

var ESCAPE = Ok.escape = function (str) {
  return special( _s.escapeHTML( _s.unescapeHTML( HTML_E.decode( str , 2) ) ) );
};

Ok.throw = function (o) { throw o.err; };

Ok.escape_uri = function (raw) {
  var url = HTML_E.decode(raw, 2);
  var parse = URI_js.parse(url);
  if (parse.errors.length)
    return null
  return URI_js.normalize(url);
};

Ok.to_html = function (str_or_arr, on_err) {
  var arr = null;
  var ok  = new Ok;
  ok.on_err = on_err;

  if (_.isString(str_or_arr)) {
    arr = JSON.parse(str_or_arr);
  }

  if (_.isArray(str_or_arr)) {
    arr = str_or_arr;
  }

  if (!arr) {
    var msg = "Value must be either string or array: " + JSON.stringify(str_or_arr);
    ok.err = new Error(msg);
    return this.throw(ok);
  }

  if (!_.isArray(arr)) {
    var msg = "Value must be an array: " + JSON.stringify(arr);
    ok.err = new Error(msg);
    return this.throw(ok);
  }

  ok.code = arr;

  ok.throw = function (err) {
    ok.err = err;
    return Ok.throw(ok);
  };

  return ok.to_html();
};

Ok.prototype.to_html = function () {

  var me             = this;
  var arr            = [];
  var method_to_html = null;
  var temp           = null;
  var err            = null;

  _.find(this.code, function (val, i) {

    method_to_html = (_.isObject(val)) ?  O_TO_HTML : STRING_TO_HTML;
    var result = method_to_html(val);

    if (result.prototype == Error) {
      err = result;
      return err;
    }

    arr.push(result);

  });

  if (err)
    return me.throw(err);

  return arr.join(NL);
};

function O_TO_HTML(val) {
  var err = null;
  var arr = [];
  var temp = null;

  _.find(val, function (props, meth) {

    switch (meth) {
      case 'form':
        temp = FORM_TO_HTML(props);
      break;
      case 'text_box':
        temp = TEXT_BOX_TO_HTML(props);
        break;
      case 'button':
        temp = BUTTON_TO_HTML(props);
      break;
      case 'link':
        temp = LINK_TO_HTML(props);
        break;
      default:
        temp = new Error('Unknown element: ' + meth);
    };

    if (meth.prototype === Error) {
      err = temp;
      return err;
    }

    arr.push(temp);

  });

  if (err)
    return err;

  return arr.join(NL);
}

function STRING_TO_HTML(val) {
  return HTML_Element('div', {},  val);
}

function FORM_TO_HTML(form) {
  var arr = [];
  var err = null;
  var temp = null;

  _.find(form, function (o, i) {
    temp = O_TO_HTML(o);
    if (IS_ERROR(temp)) {
      err = temp;
      return err;
    }
    arr.push(temp);
  });

  if (err)
    return err;

  return "<form>" + arr.join(NL) + "</form>";
}


function TEXT_BOX_TO_HTML(props) {
  var name         = props[0];
  var default_text = props[1];

  return HTML_Element('input', {id: name, name: name, type: "text", ok_type: 'text_box'}, (default_text || ""));
}

function BUTTON_TO_HTML(props) {
  var name = props[0] || "";
  var text = props[1] || "";

  return HTML_Element('button', {id: name, ok_type: 'button'}, text);
}

function HTML_Element(raw_tag, raw_props, raw_text) {
  var tag   = Ok.escape(raw_tag);
  var text  = Ok.escape(raw_text);
  var props = {};
  var err   = null;

  var ok_type = raw_props.ok_type || "";
  delete raw_props['ok_type'];

  _.find(raw_props, function (v, k) {
    if (_.contains(['id', 'name', 'type'], k) && !v.match(VALID_HTML_ID)) {
        err = new Error("Invalid chars in " + ok_type + " " + k + ": " + v);
        return err;
    }

    if (!k.match(VALID_HTML_ID)) {
      err = new Error("Invalid chars in " + ok_type + " attribute name: " + k);
      return err;
    }

    var safe_name = Ok.escape(k).trim();
    var safe_val  = (k == 'href') ? Ok.escape_uri(v) : Ok.escape(v);
    props[safe_name] = safe_val;
  });

  if (IS_ERROR(err))
    return err;

  var prop_text = _.map(props, function (v, k) {
    return k + '="' + v + '"';
  }).join(' ');

  return "<" + tag + " " + prop_text + ">" + text + "</" + tag + ">";
}






