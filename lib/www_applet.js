
var _         = require('underscore')
, _s          = require('underscore.string')
, JSON_Applet = require('json_applet').Applet
, cheerio     = require('cheerio')
, Escape      = require('www_applet/lib/sanitize').Sanitize
;

var IS_ERROR      = function (o) { return (_.isObject(o) && o.constructor == Error); };
var DEFS = {};

var OK = exports.Applet = function (source, multi_def) {
  var app = JSON_Applet(source);
  app.data.page = Page.new();
  app.data.eles = [];
  app.multi_def(DEFS);
  app.multi_def(EVENT_DEFS);
  if (multi_def)
    app.multi_def(multi_def);

  return app;
};

var NOT_READY = function () {throw new Error('not ready');}

function to_run_func(req) {
  return function (meta, args, content) {
    var valid = validate_args(req.args, args);
    if (valid.error)
      return meta.error( valid.error );
    var args = valid.update;

    valid = req.content(meta, content);
    if (valid.error)
      return meta.error( valid.error );
    var content = valid.update;

    return run(meta, args, content);
  };
}



var DEFS = {
  'parent form' : to_run_func({
    args    : {to: E.action, id: E.opt_id},
    run     : element
  })

  , 'form . text_input' : to_run_func({
    args    : {name: E.name, id: E.opt_id, lines: E.opt_num_of_lines},
    content : E.opt_string,
    run     : function (meta, args, content) {
      return element('input', [args, 'id', 'name', {type: "text", ok_type: 'text_box'}], (content || ""));
    }
  })

  , 'button' : to_run_func({
    args : {id: E.opt_id, type: E.opt_button_type},
    content : req_string,
    run : function (meta, args, content) {
      return element('button', [args, 'id', {ok_type: 'button'}], content);
    }
  })

  , 'link' :  to_run_func({
    args    : {to: E.href},
    content : E.string,
    run : function (meta, attrs, content) {
      return element('a', [args, 'href', {ok_type:'link'}], content);
    }
  })
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







