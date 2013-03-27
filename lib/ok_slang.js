
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

Ok.escape_uri = function (raw) {
  var url = HTML_E.decode(raw, 2);
  var parse = URI_js.parse(url);
  if (parse.errors.length)
    return null
  return URI_js.normalize(url);
};

Ok.to_app = function (str_or_arr, on_err) {
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
    return { error: new Error(msg) };
  }

  if (!_.isArray(arr)) {
    var msg = "Value must be an array: " + JSON.stringify(arr);
    return { error: new Error(msg) };
  }

  ok.code = arr;

  return ok.to_app();
};

Ok.prototype.to_app = function () {

  var me             = this;
  var arr            = [];
  var method_to_html = null;
  var temp           = null;
  var err            = null;

  return HTML_ify(this.code);
};

var HTML_ify = function(val, raw_page) {

  if (_.isArray(val)) {
    var page = raw_page ? raw_page : HTML_ify.Page.new(val);
    var err = null;

    _.find(val, function (raw_ele, i) {

      var result = HTML_ify(raw_ele, page);

      if (IS_ERROR(result)) {
        err = result;
        return result;
      }
      page.push(result);

    });

    var html = HTML_ify.compile(page.childs);

    if (err)
      return {error: err, raw_html: html};

    return {html: html, js: ""};
  };

  var err = null;
  var arr = [];
  var page = raw_page;

  if (_.isString(val))
    val = {string: val};

  _.find(val, function (props, meth) {

    var temp = null;
    var html_meth = HTML_ify[meth];

    if (!html_meth)
        temp = new Error('Unknown element: ' + meth);
    else
       temp = html_meth(props, page);

    if (IS_ERROR(temp)) {
      err = temp;
      return err;
    }
    arr.push(temp);

  });

  if (err)
    return err;

  if (arr.length == 0)
    return new Error("Empty element: " + JSON.stringify(val));

  if (arr.lenght > 1)
    return new Error("More than one element defined: " + JSON.stringify(val));

  return arr[0];
};

HTML_ify.string = function (val) { return HTML_Element('div', {},  val); };

HTML_ify.form = function (arr) {
  var id     = arr[0];
  var action = arr[1];

  return HTML_Element('form', {id: id, action: action},  arr.join(NL));
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


HTML_ify.on_click = function (raw_props, page) {
  var prev = page && page.last();

  if (!prev)
    return new Error('on_click: Unable to find a previously defined HTML element.');
  var ele = prev.attrs.id;
  console.log(ele)
  return new Error('smet')
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

  return { tag: tag, attrs: props,  text: text };
}

HTML_ify.compile = function (vals) {
  return _.map(vals, function (raw) {
    return HTML_ify.compile_element(raw);
  }).join(NL);
};

HTML_ify.compile_element = function (raw) {
  var $ = cheerio.load('<' + raw.tag + '>');
  var e = $(raw.tag);
  e.text(raw.text);
  _.each(raw.attrs, function (a_text, a_name) {
   e.attr( a_name, a_text );
  });
  return $.html();
};

// ****************************************************************
// ****************** HTML_ify Page *******************************
// ****************************************************************


HTML_ify.Page = function () {};
HTML_ify.Page.new = function (arr) {
  var p    = new HTML_ify.Page;
  p.origin = arr;
  p.childs = [];
  p.default_ids = {};
  return p;
};

HTML_ify.Page.prototype.generate_id = function (tag) {
  var ids = this.default_ids;
  if (!ids[tag])
    ids[tag] = 0;
  ids[tag] = ids[tag] + 1;
  return tag + '_' + ids[tag];
};

HTML_ify.Page.prototype.push = function (ele) {
  this.childs.push(ele);
  return this;
};

HTML_ify.Page.prototype.last = function () {
  return _.last(this.childs);
};

HTML_ify.Page.Element = function () { };
HTML_ify.Page.Element.new = function (ele) {
  if (!ele.tag)
    ele.tag = function () { return this[0] && this[0].name; };
  return ele;
};






