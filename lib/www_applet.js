
var _         = require('underscore')
, _s          = require('underscore.string')
, JSON_Applet = require('json_applet').Applet
, cheerio     = require('cheerio')
, Sanitize    = require('www_applet/lib/sanitize').Sanitize
, S           = Sanitize
;

var IS_ERROR      = function (o) { return (_.isObject(o) && o.constructor == Error); };
var DEFS = {};

var OK = exports.Applet = function (source, multi_def) {
  var app = JSON_Applet(source);
  app.data.page = Page.new();
  app.data.eles = [];

  _.extend(app, WWW_EXTS);

  _.each(DEFS, function (v, k) {
    app.def_Tag(k, v);
  });

  app.multi_def(EVENT_DEFS);

  if (multi_def)
    app.multi_def(multi_def);

  return app;
};

var NOT_READY = function () {throw new Error('not ready');}

var WWW_EXTS = {
  def_tag : function (tag, props) {
    var attrs       = props.attrs;
    var opt_func    = props.run;
    var opt_content = props.content;
    var tag_name    = _.last(tag.split(' '));

    var run = function (meta, args, content) {
      NOT_READY();
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

    var def = {};
    def[tag] = run;
    this.multi_def(def);
    return this;
  }
};


var DEFS = {
  'parent form' : {
    args    : {to: S.action, id: S.opt_id}
  }

  , 'text_input' : {
    args    : {name: S.name, id: S.opt_id, lines: S.opt_num_of_lines},
    content : S.opt_string,
    run     : function (meta, args, content) {
      return element('input', [args, 'id', 'name', {type: "text", ok_type: 'text_box'}], (content || ""));
    }
  }

  , 'button' : {
    args : {id: S.opt_id},
    content : S.string,
    run : function (meta, args, content) {
      return element('button', [args, 'id', {ok_type: 'button'}], content);
    }
  }

  , 'link_button' : {
    args : {id: S.opt_id},
    content : S.string,
    run : function (meta, args, content) {
      return element('a', [args, 'id', {ok_type: 'link_button'}], content);
    }
  }

  , 'link' :  {
    args    : {to: S.href},
    content : S.string,
    run : function (meta, attrs, content) {
      return element('a', [args, 'href', {ok_type:'link'}], content);
    }
  }
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







