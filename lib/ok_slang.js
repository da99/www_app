
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

    var result = HTML_ify(val);

    if (IS_ERROR(result)) {
      err = result;
      return err;
    }

    arr.push(result);

  });

  if (err)
    return me.throw(err);

  return arr.join(NL);
};

var HTML_ify = function(val) {
  var err = null;
  var arr = [];

  if (_.isString(val))
    val = {string: val};

  _.find(val, function (props, meth) {
    var temp = null;
    if (!HTML_ify[meth])
        temp = new Error('Unknown element: ' + meth);
    else
       temp = HTML_ify[ meth ](props);

    if (IS_ERROR(temp)) {
      err = temp;
      return err;
    }

    arr.push(temp);

  });

  if (err)
    return err;

  return arr.join(NL);
};

HTML_ify.string = function (val) { return HTML_Element('div', {},  val); };

HTML_ify.form = function (form) {
  var arr = [];
  var err = null;
  var temp = null;

  _.find(form, function (o, i) {
    temp = HTML_ify(o);
    if (IS_ERROR(temp)) {
      err = temp;
      return err;
    }
    arr.push(temp);
  });

  if (err)
    return err;

  return "<form>" + arr.join(NL) + "</form>";
};


HTML_ify.text_box = function (props) {
  var name         = props[0];
  var default_text = props[1];

  return HTML_Element('input', {id: name, name: name, type: "text", ok_type: 'text_box'}, (default_text || ""));
};

HTML_ify.button = function (props) {
  var name = props[0] || "";
  var text = props[1] || "";

  return HTML_Element('button', {id: name, ok_type: 'button'}, text);
};

HTML_ify.link = function (raw_props) {
  var props = raw_props.slice();
  var name  = (props.length === 2) ?  null : props.shift();
  var link  = props.shift();
  var text  = props.shift();
  var ele   = cheerio.load('<a>');
  var attrs = {ok_type: 'link', 'href': link};
  if (name)
    attrs.id = name;
  return HTML_Element('a', attrs, text);
};

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

    if ( _.contains(['href', 'action'], k)) {
      var safe_val  = Ok.escape_uri(v);
      if (!safe_val) {
        err = new Error('Invalid link address: ' + v);
        return err;
      }
    } else {
      var safe_val  = Ok.escape(v);
    }

    props[safe_name] = safe_val;
  });

  if (IS_ERROR(err))
    return err;

  var prop_text = _.map(props, function (v, k) {
    return k + '="' + v + '"';
  }).join(' ');

  return "<" + tag + " " + prop_text + ">" + text + "</" + tag + ">";
}






