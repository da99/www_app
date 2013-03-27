
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

var Ok = exports.Ok = {};

var ESCAPE = Ok.escape = function (str) {
  if (!_.isString(str))
    return null;
  return special( _s.escapeHTML( _s.unescapeHTML( HTML_E.decode( str , 2) ) ) );
};

Ok.escape_uri = function (raw) {
  if (!_.isString(raw))
    return null;
  var url = HTML_E.decode(raw, 2);
  var parse = URI_js.parse(url);
  if (parse.errors.length)
    return null
  return URI_js.normalize(url);
};

Ok.to_app = function (str_or_arr) {
  var arr = null;

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

  return HTML_ify(arr);
};

var HTML_ify = function(val) {

  var page     = HTML_ify.Page.new(val);
  var last_ele = null;
  var err      = null;

  while (!page.is_fin && !err) {
    var tag = page.shift();
    var is_event = tag.indexOf('on_') === 0;

    var result = (is_event) ?
      HTML_ify.event(   tag, page.shift(), last_ele) :
      HTML_ify.element( tag, page.shift(), page.shift());

    if (IS_ERROR(result)) {
      err = result;
    } else {
      page.push(result);
      if (!is_event)
        last_ele = result;
    }
  }

  var html = HTML_ify.compile(page.childs);

  if (err)
    return {error: err, raw_html: html};

  return {html: html, js: ""};

};

HTML_ify.element = function (tag, attrs, childs) {
  var err = null;

  if (!attrs)
    return new Error('No attributes defined for: ' + tag);
  if (!childs)
    return new Error('No child elements defined for: ' + childs);
  if (!HTML_ify[tag])
    return new Error('Unknown element: ' + tag);

  if (!_.isArray(attrs))
    attrs = [attrs];
  if (!_.isArray(childs)) // "some text" => [ "some text" ]
    childs = [childs];
  if (childs.length && !_.isArray(childs[0])) // ["button", ...] => [ ["button", ...] ];
    childs = [childs];

  var tag_as_element = HTML_ify[tag](attrs, childs);

  if (IS_ERROR(tag_as_element))
    return tag_as_element;

  _.each(childs, function (c, i) {
    tag_as_element.childs.push(HTML_ify.element( c[0], c[1], c[2] ));
  });

  return tag_as_element;
};

HTML_ify.event = function (name, stuff_to_do) {
  return new Error('not implemented: ' + name + ' : ' + stuff_to_do);
};

HTML_ify.form = function (attrs) {
  var id     = attrs[0];
  var action = attrs[1];

  return New_Element('form', {id: id, action: action, ok_type: 'form'});
};

HTML_ify.text_box = function (attrs) {
  var name         = attrs[0];
  var default_text = attrs[1];

  return New_Element('input', {id: name, name: name, type: "text", ok_type: 'text_box'}, (default_text || ""));
};

HTML_ify.button = function (attrs, childs) {
  var name = attrs[0] || "";
  if (!childs.length)
    return new Error('No text defined for button.');
  if (childs.length != 1 )
    return new Error('Button only accepts text: ' + JSON.stringify(childs));

  var text = childs[0];

  if (_.isArray(text) && _.isString(text[0]))
    text = text[0];

  if (!_.isString(text))
    return new Error('Button only accepts text: ' + JSON.stringify(text));

  return New_Element('button', {id: name, ok_type: 'button'}, text);
};

HTML_ify.link = function (raw_attrs, childs) {
  if (childs.length > 1)
    return new Error('Too many elements for link: ' + JSON.stringify(childs));
  if (childs.length < 1)
    return new Error('No text defined for link: ' + JSON.stringify(['link', raw_attrs]));
  if (!_.isString(childs[0]))
    return new Error('links only accept text: ' + JSON.stringify(childs[0]));

  var attrs = raw_attrs.slice();
  var name  = (attrs.length > 1) ? attrs.shift() : null;
  var link  = attrs.shift();
  var text  = childs[0];
  var ele   = cheerio.load('<a>');
  var attrs = {ok_type: 'link', 'href': link};
  if (name)
    attrs.id = name;
  return New_Element('a', attrs, text);
};


HTML_ify.on_click = function (attrs, ele) {
  if (!ele)
    return new Error('on_click: Unable to find a previously defined element.');
  return new Error('smet')
};

function New_Element(raw_tag, raw_props, raw_text) {
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

  return { tag: tag, attrs: props,  text: text, childs: [] };
}

HTML_ify.compile = function (vals) {
  return _.map(vals, function (raw) {
    return HTML_ify.compile_element(raw);
  }).join(NL);
};

HTML_ify.compile_element = function (raw) {

  var $ = cheerio.load('<' + raw.tag + '>');
  var e = $(raw.tag);

  _.each(raw.attrs, function (a_text, a_name) {
   e.attr( a_name, a_text );
  });


  if (raw.text) {
    e.text(raw.text);
  } else {
    e.html( _.map(raw.childs, function (ele, i) {
      return HTML_ify.compile_element(ele);
    }).join(NL) );
  }

  return $.html();

};

// ****************************************************************
// ****************** HTML_ify Page *******************************
// ****************************************************************


HTML_ify.Page = function () {};
HTML_ify.Page.new = function (arr) {
  var p    = new HTML_ify.Page;
  p.origin = arr;
  p.working_tokens = arr.slice();
  p.childs = [];
  p.default_ids = {};
  p.is_fin = false;
  return p;
};

HTML_ify.Page.prototype.generate_id = function (tag) {
  var ids = this.default_ids;
  if (!ids[tag])
    ids[tag] = 0;
  ids[tag] = ids[tag] + 1;
  return tag + '_' + ids[tag];
};

HTML_ify.Page.prototype.shift = function () {
  var token = this.working_tokens.shift();
  if (!token || this.working_tokens.length === 0) {
    this.is_fin = true;
  }
  return token;
};

HTML_ify.Page.prototype.push = function (ele) {
  this.childs.push(ele);
  return this;
};

HTML_ify.Page.prototype.last = function () {
  return _.last(this.childs);
};

HTML_ify.Page.Element = {};
HTML_ify.Page.Element.new = function (ele) {
  if (!ele.tag)
    ele.tag = function () { return this[0] && this[0].name; };
  return ele;
};






