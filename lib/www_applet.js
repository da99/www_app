
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
  me.data    = {
    html    : [],
    js      : [],
    results : [],
    tags    : {},
    nesting : {html : [], js: []}
  };

  var defaults = Applet.default_tags.concat(Applet.default_js).concat(defs || []);

  _.each(defaults, function (line) {
    me[line[0]].apply(me, line.slice(1));
  });

  me.after_run(function (app) {
    app.results = {
      html    : app.data.html.join("\n"),
      js      : app.data.js
    };
  });

  return me;
};

Applet.prototype.origin = function () {
  if (this.parent)
    return this.parent;
  return this;
};

Applet.prototype.create_id = function (tag) {
  var app = this.origin();
  if (!app.data.auto_ids)
    app.data.auto_ids = {};
  var ids = app.data.auto_ids;
  if (!ids[tag])
    ids[tag] = 0;
  ids[tag] = ids[tag] + 1;
  return 'ok_' + tag + '_' + ids[tag];
};


// ****************************************************************
// ****************** Nesting *************************************
// ****************************************************************

Applet.prototype.push_nest = function (cat, val) {
  if (!this.data.nesting[cat])
    this.data.nesting[cat] = [];
  return this.data.nesting[cat].push(val);
};

Applet.prototype.pop_nest = function (cat) {
  return this.data.nesting[cat].pop();
};

Applet.prototype.nest = function (cat) {
  var parent_nest = [];
  if (this.parent)
    parent_nest = this.parent.nest(cat);
  return parent_nest.concat(this.data.nest[cat]);
};

// ****************************************************************
// ****************** def Funcs ***********************************
// ****************************************************************


Applet.prototype.def_tag = function (raw_name, req_args, on_run) {
  var tag = raw_name.trim();
  var app = this;
  app.data.tags[tag] = {name: raw_name, attrs: ['id', 'class'].concat(req_args || []), on_run: on_run};

  app.funcs[tag] = function (run, attrs, content) {
    app.push_nest('html', tag);
    var meta = run.app.data.tags[tag];

    // Unknown attrs.
    var unk = _.compact(_.map(attrs, function (v, k) {
      if (!meta.attrs[k])
        return k;
      return null;
    }));

    if (unk.length)
      return new Error(tag + ': unknown attributes: "' + unk.join(', ') + '"');

    // Run tag .on_run func if exists.
    if (meta.on_run) {
      var new_props = meta.on_run(run, tag, attrs, content);
      if (S.is_error(new_props))
        return new_props;
      if (!new_props || !new_props.length)
        return new Error(tag + ': function does not return a [tag, args, content] array: ' + meta.on_run.toString());
      tag     = new_props[0];
      attrs   = new_props[1];
      content = new_props[2];
    }

    // Sanitize tag
    tag = S.tag(tag);
    if (S.is_error(tag))
      return tag;

    // Sanitize attrs.
    var clean_attrs = {};
    for (var name in tag_meta.args) {
      var valid = tag_meta.args[name](args[name]);
      if (S.is_error(valid))
        return valid;
      clean_attrs[name] = valid;
    }


    var $ = cheerio.load('<' + tag + '>');
    var e = $(tag);
    _.each(clean_attrs, function (v, k) {
      e.attr(S.html(k), S.html(v));
    });


    // Sanitize content.
    if (S.is_string_in_array(content)) {
      e.text(S.html(content[0]));
    } else {
      content = run.run(content);

      if (S.is_error(content))
        return content;

      e.html(content.results.html.join("\n"));
      app.origin().data.js = app.origin().data.js.concat(content.results.js);
    }

    var html = $.html();
    app.data.html.push(html);
    app.pop_nest('html');

    return html;
  };

  return app;
};

// ****************************************************************
// ****************** Run-related Funcs ***************************
// ****************************************************************

Applet.prototype.after_run = function (func) {
  var me = this;
  if (!me.after_runs)
    me.after_runs = [];
  me.after_runs.push(func);
  return me;
};

Applet.prototype.run = function () {
  if (arguments.length)
    return new Error(".run does not accept any arguments: " + JSON.stringify(_.toArray(arguments)));

  var me        = this;
  var code      = S.to_applet_func_calls( me.source );
  if (S.is_error(code)) {
    me.error = code;
    return code;
  }
  var l         = code.length;
  var i         = 0;
  var token     = null;
  var next      = null;
  var func_meta = null;
  var results   = [];
  var prev      = null;
  var curr      = null;
  var line      = null;

  if (!source && me.is_busy) {
    me.error = new Error('Applet already running.');
    return me.error;
  }

  if (!source)
    me.is_busy = true;

  while (i < l) {
    line  = code[i];
    i     = i + 1;
    next  = code[i];
    token = line[0];

    func_meta = me.funcs[token];

    if (!func_meta)
      return new Error("Function not found: " + token);

    curr = {
      prev : prev,
      name : token,
      args : line.slice(1),
      meta : func_meta,
      data : me.data,
      app  :  me,
      run  : function (source) {
        var app = Applet.new(source);
        app.parent = me;
        return app.run();
      }
    };

    var on_run_result = func_meta.func.apply(null, [curr].concat(curr.args));
    results.push(on_run_result);

    if (S.is_error(on_run_result))
      me.error = on_run_result;

    if (me.error)
      return me;

    prev = curr;
  }

  if (source)
    return results;

  me.data.results = me.data.results.concat(results);
  me.is_busy      = false;
  me.results      = results;

  _.each(me.after_runs || [], function (func) {
    func(me);
  });

  return me;
};









