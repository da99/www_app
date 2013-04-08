
var _         = require('underscore')
, _s          = require('underscore.string')
, JSON_Applet = require('www_applet/lib/json_applet').Applet
, cheerio     = require('cheerio')
, Sanitize    = require('www_applet/lib/sanitize').Sanitize
, S           = Sanitize
;

var IS_ERROR      = function (o) { return (_.isObject(o) && o.constructor == Error); };

JSON_Applet.prototype.def_tag = function (json_name, args, content, on_run) {
  var app = this;
  var props = {
    args : args,
    content : content,
    on_run: on_run
  };
  app.data.tags[json_name.trim().split(' ').pop()] = props;
  app.def(json_name, function () {
    OK.tag_run.apply(null,arguments);
  });
  return app;
};

var OK = exports.Applet = function () {};


OK.new = function (source, multi_def) {
  var app = JSON_Applet.new(source);
  app.data.page = Page.new();
  app.data.tags = {};

  _.each(OK.tags, function (args, k) {
    app.def_tag.apply(app, [k].concat(args));
  });

  app.multi_def(EVENT_DEFS);

  if (multi_def)
    app.multi_def(multi_def);

  return app;
};

OK.tag_run = function (run, args, content) {
  var tag_meta = run.app.data.tags[run.name];

  // Unknown attrs.
  var unk = _.compact(_.map(args, function (v, k) {
    if (!tag_meta.args[k])
      return k;
    return null;
  }));

  if (unk.length)
    return run.error(new Error('Unknown attributes: ' + unk.join(', ')));

  // Sanitize attrs.
  var clean_attrs = {};
  for (var name in tag_meta.args) {
    var valid = tag_meta.args[name](args[name]);
    if (valid && valid.message)
      return run.error(valid);
    clean_attrs[name] = valid;
  }

  // conso.log(clean_attrs[id].toString())
  NOT_READY();
  return OK.Element.new(tag, args, content);
};

var NOT_READY = function () {throw new Error('not ready');}

OK.tags = {
  'parent form' : [
    {action: S.action, id: S.opt_id}
  ]

  , 'text_input' : [
    {name: S.name, id: S.opt_id, lines: S.opt_num_of_lines},
    S.opt_string,
    function (meta, args, content) {
      return element('input', [args, 'id', 'name', {type: "text", ok_type: 'text_box'}], (content || ""));
    }
  ]

  , 'button' : [
    {id: S.opt_id},
    S.string,
    function (meta, args, content) {
      return element('button', [args, 'id', {ok_type: 'button'}], content);
    }
  ]

  , 'a_button' : [
    {id: S.opt_id},
    S.string,
    function (meta, args, content) {
      return element('a', [args, 'id', {ok_type: 'link_button'}], content);
    }
  ]

  , 'a' :  [
    {id: S.opt_id, href: S.href},
    S.string,
    function (meta, attrs, content) {
      return element('a', [args, 'href', {ok_type:'link'}], content);
    }
  ]
};

var EVENT_DEFS = {
  'on_click' : function (meta, content) {
    meta.data.js.push(_.last(meta.data.eles), 'on_click', content);
    return "";
  }
};


// ****************************************************************
// ****************** Helpers *******************************
// ****************************************************************

var Page = function () {};
Page.new = function () {
  var p = new Page;
  p.ids = {};
  p.eles = [];
  return p;
};

Page.prototype.create_id = function (tag) {
  var ids = this.ids;
  if (!ids[tag])
    ids[tag] = 0;
  ids[tag] = ids[tag] + 1;
  return 'ok_' + tag + '_' + ids[tag];
};


// ****************************************************************
// ****************** Element *************************************
// ****************************************************************

var Element = {};
Element = function () {}
Element.new = function (raw_tag, raw_attrs, raw_content, page) {
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

Element.prototype.origin = function () {
  return this.parent.origin();
};

Element.prototype.compile = function () {
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







