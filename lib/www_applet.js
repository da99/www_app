
var _         = require('underscore')
, _s          = require('underscore.string')
, cheerio     = require('cheerio')
, Sanitize    = require('www_applet/lib/sanitize').Sanitize
, S           = Sanitize
;


// ****************************************************************
// ****************** Helpers *************************************
// ****************************************************************

function quote(str) { return '"' + str + '"'; }

function nest_error(curr) {
  var name      = curr.name;
  var func_meta = curr.meta;
  var nest      = curr.app.nesting;
  var child_of  = func_meta.child_of;
  var is_parent = func_meta.is_parent;

  if (!child_of && !is_parent)
    return false;

  if (child_of && !_.contains(nest, child_of))
    return new Error(name + ': can only be used within ' + quote(child_of) + '.');

  if (is_parent && _.where(nest, name).length > 1)
    return new Error(name + ": can not be used within another " + quote(name) + '.');

  return false;
}

function def(app, name, func, props) {
  props = (props) ? props : {};
  app.funcs[name] = {
    child_of  : props.child_of  || null,
    is_parent : props.is_parent || false,
    func      : func
  };
  return app;
};

function tag_run(run, args, content) {
  var tag      = run.name;
  var tag_meta = run.app.data.tags[tag];

  // Unknown attrs.
  var unk = _.compact(_.map(args, function (v, k) {
    if (!tag_meta.args[k])
      return k;
    return null;
  }));

  if (unk.length)
    return run.error(new Error(tag + ': unknown attributes: "' + unk.join(', ') + '"'));

  // Run tag .on_run func if exists.
  if (tag_meta.on_run) {
    var new_props = tag_meta.on_run(run, tag, args, content);
    if (run.error())
      return run.error();
    if (!new_props || !new_props.length)
      return run.error(new Error(tag + ': function does not return a [tag, args, content] array: ' + tag_meta.on_run.toString()));
    tag     = new_props[0];
    args    = new_props[1];
    content = new_props[2];
  }

  // Sanitize tag
  tag = S.tag(tag);
  if (S.is_error(tag))
    return run.error(tag);

  // Sanitize attrs.
  var clean_attrs = {};
  for (var name in tag_meta.args) {
    var valid = tag_meta.args[name](args[name]);
    if (valid && valid.message)
      return run.error(valid);
    clean_attrs[name] = valid;
  }


  var $ = cheerio.load('<' + tag + '>');
  var e = $(tag);
  _.each(clean_attrs, function (v, k) {
    e.attr(S.html(k), S.html(v));
  });


  // Sanitize content.
  var clean_content = (tag_meta.content) ? tag_meta.content(content, tag) : content;
  if (clean_content && S.is_error(clean_content))
    return run.error(clean_content);

  if (S.is_string_in_array(content)) {
    clean_content = clean_content[0];
    e.text(S.html(clean_content));
  } else {
    clean_content = run.app.run(content);
    if (S.is_error(clean_content))
      return run.error(clean_content);
    if (clean_content && clean_content.error)
      return run.error(clean_content.error);
    clean_content = clean_content.results.join("\n");
    e.html(clean_content);
  }

  var html = $.html();

  if (!run.app.is_nested())
    run.app.data.html.push(html);
  return html;
};


// ****************************************************************
// ****************** Main Stuff **********************************
// ****************************************************************

var Applet = exports.Applet = function (source, funcs) {};

Applet.default_tags = [
  [ 'def_tag_parent' , 'form',       ['action']],
  [ 'def_tag'        , 'input_text', ['name']  ],
  [ 'def_tag'        , 'button',     []        ],
  [ 'def_tag'        , 'a',          ['href']  ]
];

Applet.default_js = [
  [ 'def_js', 'on_click', function (meta, content) {
  meta.data.js.push(_.last(meta.data.eles), 'on_click', content);
  return "";
}]
];


Applet.new = function (source, defs) {
  var me     = new Applet;
  me.is_www_applet = true;
  me.source  = source;
  me.funcs   = {};
  me.error   = null;
  me.nesting = [];
  me.data    = {
    html    : [],
    js      : [],
    tags    : {},
    page    : Page.new()
  };

  var defaults = Applet.default_tags.concat(Applet.default_js).concat(defs || []);

  _.each(defaults, function (line) {
    me[line[0]].apply(me, line.slice(1));
  });

  me.after_run(function (app) {
    app.results = {
      html    : app.data.html.join("\n"),
      js      : app.data.js.join("\n")
    };
  });

  return me;
};

Applet.prototype.def_tag_parent = function (name, req_args, on_run) {
  var on_run_parent_check = function () {
    NOT_READY();
    return on_run.apply(arguments);
  };
  return this.def_tag(name, req_args, on_run_parent_check);
};

Applet.prototype.def_tag = function (json_name, req_args, on_run, nesting) {
  var app = this;
  var props = {
    args : req_args,
    on_run: on_run
  };
  app.data.tags[json_name.trim()] = props;

  def(json_name, function () {
    return tag_run.apply(null,arguments);
  });

  return app;
};

Applet.prototype.after_run = function (func) {
  var me = this;
  if (!me.after_runs)
    me.after_runs = [];
  me.after_runs.push(func);
  return me;
};

Applet.prototype.save_error = function (err) {
  this.error = err;
  return this;
};

Applet.prototype.is_nested = function () { return this.nesting.length > 1; };

Applet.prototype.run = function (source) {
  var me        = this;
  var code      = S.to_applet_func_calls( (arguments.length === 0) ? me.source : (source || []) );
  if (S.is_error(code))
    return me.save_error(code);
  var l         = code.length;
  var i         = 0;
  var token     = null;
  var next      = null;
  var func_meta = null;
  var results   = [];
  var prev      = null;
  var curr      = null;
  var line      = null;

  if (!source && me.is_busy)
    return me.save_error(new Error('Applet already running.'));

  if (!source)
    me.is_busy = true;

  while(i < l) {
    line  = code[i];
    i     = i + 1;
    next  = code[i];
    token = line[0];

    func_meta = me.funcs[token];

    if (!func_meta)
      return me.save_error( new Error("Function not found: " + token) );

    curr = {
      prev: prev,
      name: token,
      args: line.slice(1),
      meta: func_meta,
      data: me.data,
      app:  me,
      error: function (err) {
        if (!err)
          return me.error;
        else {
          me.error = err;
          return me;
        }
      }
    };

    me.nesting.push(token);

    me.error = nest_error(curr);
    if (me.error)
      return me;

    results.push(func_meta.func.apply(null, [curr].concat(curr.args)));
    me.nesting.pop();

    if (me.error)
      return me;

    prev = curr;
  }

  if (source) {
    return {results: results};
  } else {
    me.data.results = me.data.results.concat(results);
  }

  me.is_busy = false;
  me.results = results;

  if (me.after_runs) {
    _.each(me.after_runs, function (func) {
      func(me);
    });
  }

  return me;

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









