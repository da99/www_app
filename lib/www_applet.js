
var _         = require('underscore')
, _s          = require('underscore.string')
, JSON_Applet = require('json_applet')
, cheerio     = require('cheerio')
, Escape      = require('okdoki_applet/lib/escape')
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
};

var NOT_READY = function () {throw new Error('not ready');}

function req(func) {
  return function (val) {
    if (!val)
      return {error: new Error(func.name + ' is missing.')};
    return func(val);
  };
}

function standardize_arg_length(reqs, args) {
  var args_l = args.length;
  var reqs_l = reqs.length;

  if (args_l === reqs_l)
    return {update: args};

  if (args_l > reqs_l)
    return {error: new Error('Too many args: ' + JSON.stringify(args))};

  var args = args.slice();
  var last_req = _.last(reqs);
  var last_arg = _.last(args);
  if (_.isObject(last_req) && !_.isObject(last_arg))
    args.push({});
  else
    args.push(undefined);

  return standardize_arg_length(reqs, args);
}

function validate_named_args(reqs, args) {
  if (_.isObject(args))
    return {error: new Error('Named args not in an object: ' + JSON.stringify(args))};

  var final = {};
  var err   = null;

  _.find(reqs, function (r, name) {
    var results = r(args[name]);
    if (results.error) {
      err = results;
      return err;
    }

    final[name] = results.update;
  });

  if (err)
    return err;

  return {update: final};
}

function validate_args(reqs, args) {
  var args_l = standardize_arg_length(reqs, args);
  var err = null;

  if (args_l.error)
    return args_l;

  args = args_l.update;
  var final = {};

  _.find(reqs, function (r, i) {
    var valid =  (_.isFunction(r)) ?  r(args[i]) : validate_named_args(r, args[i]);
    if (valid.error) {
      err = valid;
      return err;
    }
    final = _.extend(final, valid.update);
  });

  if (err)
    return err;

  return {update: final};
}

function to_multi_def(obj) {
  var defs = {};
  _.each(obj, function (v, k) {
    defs[k] = to_run_func(v);
  });
  return defs;
}

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

var DEFS = to_multi_def({
  'parent form' : {
    args    : [req_action, {id: id}],
    content : run_content,
    run     : element
  }

  , 'form . text_input' : {
    args    : [req_name, {id: id, lines: num_of_lines}],
    content : string,
    run     : function (meta, args, content) {
      return element('input', [args, 'id', 'name', {type: "text", ok_type: 'text_box'}], (content || ""));
    }
  }

  , 'button' : {
    args : [id, {type: button_type}],
    content : req_string,
    run : function (meta, args, content) {
      return element('button', [args, 'id', {ok_type: 'button'}], content);
    }
  }

  , 'link' :  {
    args    : [href],
    content : req_string,
    run : function (meta, attrs, content) {
      return element('a', [args, 'href', {ok_type:'link'}], content);
    }
  }
});

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







