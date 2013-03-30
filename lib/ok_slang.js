
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

var Ok = exports.Ok = function (arr) {
  var page = Ok.Page.new(arr);
  if (IS_ERROR(page))
    return page;
  return page.compile();
};

Ok.escape = function (str) {
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

Ok.escape_attrs = function (raw_attrs, tag) {
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

Ok.escape_attr = function (k, v, tag) {
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

Ok.string_body = function (unk) {
  var flatten = _.flatten([unk]);
  var l       = flatten.length;
  if (l === 1 && _.isString(flatten[0]))
    return flatten[0];
  return null;
};

var DSL = function(val) {

  var page     = DSL.Page.new(val);
  var last_ele = null;
  var err      = null;

  while (!page.is_fin && !err) {
    var tag = page.shift();
    var is_event = tag.indexOf('on_') === 0;

    var result = (is_event) ?
      DSL.event(   tag, page.shift(), last_ele) :
      DSL.element( tag, page.shift(), page.shift());

    if (IS_ERROR(result)) {
      err = result;
    } else {
      page.push(result);
      if (!is_event)
        last_ele = result;
    }
  }

  var html = DSL.compile(page.childs);

  if (err)
    return {error: err, raw_html: html};

  return {html: html, js: ""};

};



DSL.element = function (tag, attrs, childs) {
  var err = null;

  if (!DSL[tag])
    return new Error('Unknown element: ' + tag);

  if (!attrs)
    return new Error('No attributes defined for: ' + tag);

  if (!childs)
    return new Error('No content or elements defined for: ' + JSON.stringify([tag, attrs]));

  attrs = Stardardize_Childs(attrs);
  childs = Stardardize_Childs(childs);

  var tag_as_element = DSL[tag](attrs, childs);

  if (IS_ERROR(tag_as_element))
    return tag_as_element;

  return tag_as_element;
};

DSL.event = function (name, stuff_to_do) {
  return new Error('not implemented: ' + name + ' : ' + stuff_to_do);
};

DSL.form = function (e) {
  var attrs  = e.raw_attrs;
  var childs = e.childs;

  if (!_.isArray(childs))
    return new Error('Invalid content for form: ' + JSON.stringify(childs));
  if (_.isEmpty(childs))
    return new Error('No content for form: ' + JSON.stringify(['form', attrs]));

  var id     = (attrs.length === 1) ? e.origin().generate_id('form') : attrs[0];
  var action = _.last(attrs);
  var attrs = {
    id      : id,
    action  : action
  };

  var attrs  = Ok.escape_attrs(attrs, e.tag);
  var childs = e.childs;
};

DSL.text_box = function (attrs) {
  var name         = attrs[0];
  var default_text = attrs[1];

  return New_Element('input', {id: name, name: name, type: "text", ok_type: 'text_box'}, (default_text || ""));
};

DSL.button = function (attrs, childs) {
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

DSL.link = function (raw_attrs, childs) {
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


DSL.on_click = function (attrs, ele) {
  if (!ele)
    return new Error('on_click: Unable to find a previously defined element.');
  return new Error('smet')
};

// ****************************************************************
// ****************** DSL Page *******************************
// ****************************************************************


Ok.Page = function () {};
Ok.Page.new = function (str_or_arr, parent) {

  if (!arguments.length)
    return this;

  var arr = null;

  if (_.isString(str_or_arr))
    arr = JSON.parse(str_or_arr);

  if (_.isArray(str_or_arr))
    arr = str_or_arr;

  if (!arr)
    return { error: new Error("Value must be either string or array: " + JSON.stringify(str_or_arr)) };

  if (!_.isArray(arr))
    return { error: new Error("Value must be an array: " + JSON.stringify(arr)) };

  var p            = new Ok.Page;
  p.raw            = arr;
  p.working_tokens = arr.slice();
  p.elements       = [];
  p.is_fin         = false;
  p.parent         = parent;
  p.id_counts      = {};
  return p;
};

Ok.Page.prototype.origin = function () {
  var me = this;
  if (!this.parent)
    return me;
  return this.parent.origin();
};

Ok.Page.prototype.generate_id = function (tag) {
  var ids = this.origin().id_counts;
  if (!ids[tag])
    ids[tag] = 0;
  ids[tag] = ids[tag] + 1;
  return tag + '_' + ids[tag];
};

Ok.Page.prototype.shift = function () {
  var token = this.working_tokens.shift();
  if (!token || this.working_tokens.length === 0) {
    this.is_fin = true;
  }
  return token;
};

Ok.Page.prototype.push = function (ele) {
  this.childs.push(ele);
  return this;
};

Ok.Page.prototype.last = function () {
  return _.last(this.childs);
};

Ok.Page.prototype.compile = function () {
  var me = this;

  while (me.working_tokens.length && !me.is_fin) {
    var tag     = me.working_tokens.shift();
    var attrs   = me.working_tokens.shift();
    var content = me.working_tokens.shift();
    var e       = Ok.Element.new(tag, attrs, content, me);
    if(IS_ERROR(e)) {
      me.error = e;
      me.is_fin = true;
    } else {
      me.elements.push(e);
    }
  }

  me.html = _.map(me.elements, function (e) {
    return e.compile().html;
  }).join(NL);

  return me;
};

// ****************************************************************
// ****************** Element *************************************
// ****************************************************************

Ok.Element = function () {}
Ok.Element.new = function (raw_tag, raw_attrs, raw_content, page) {
  var string_body = Ok.string_body(raw_content);
  var err         = null;
  var e           = new Ok.Element();
  e.parent        = page;
  e.tag           = Ok.escape(raw_tag);
  e.attrs         = {};
  e.raw_attrs     = raw_attrs;

  if (string_body) {
    e.text    = string_body;
    e.childs  = [];
  } else {
    e.childs = raw_content;
  }

  if (!DSL[e.tag])
    return new Error('Unknown tag: ' + e.tag);

  var results = DSL[e.tag](e);
  if (IS_ERROR(results))
    return results;

  return e;
};

Ok.Element.prototype.origin = function () {
  return this.parent.origin();
};

Ok.Element.prototype.compile = function () {
  var me = this;
  var $ = cheerio.load('<' + me.tag + '>');
  var e = $(me.tag);

  _.each(me.attrs, function (a_text, a_name) {
   e.attr( a_name, a_text );
  });


  if (me.text) {
    e.text(me.text);
  } else {
    e.html( Ok.Page.new(e.childs, me).compile().html );
  }

  return $.html();

};







