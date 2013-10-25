
// require jquery
// require underscore


// ================================================================
//                    Define Container
// ================================================================

var WWW_Applet = function () {};

// ================================================================
//                    Helpers
// ================================================================

WWW_Applet.SPACES           = /\ +/g;
WWW_Applet.quote            = function (str) { return '"' + str + '"'; }
WWW_Applet.standardize_name = function (s) { return $.trim(s).toUpperCase(); };


// ================================================================
//                    Main Stuff
// ================================================================

WWW_Applet.new = function (source, funcs, app) {

  var me = new WWW_Applet;
  me.source   = source;
  me.stack    = [];
  me.data_bag = {};


  if (app) {

    me.vars    = app.vars;
    me.parent  = app;

  } else {

    me.vars    = {};

    me.def_vars(WWW_Applet.Base_Funcs);
    if (funcs)
      me.def_vars(funcs);

  } // === if !app

  return me;
};

WWW_Applet.prototype.data = function (k, v) {
  var me = this;
  var bag = me.top().data_bag;
  if (arguments.length == 1)
    return bag[k];

  bag[k] = v;
  return v;
};

WWW_Applet.prototype.top = function () {
  var me = this;
  if (me.parent)
    return me.parent.top();
  else
    return me;
};

WWW_Applet.prototype.read_var = function (raw_name) {
  var name = WWW_Applet.standardize_name(raw_name);
  if (this.vars.hasOwnProperty(name))
    return this.vars[name];
  return this.top().vars[name];
};

WWW_Applet.prototype.local_def_var = function (name, val) {
  this.vars[WWW_Applet.standardize_name(name)] = val;
  return this;
};

WWW_Applet.prototype.def_var = function (name, val) {

  var me = this.top();

  me.vars[WWW_Applet.standardize_name(name)] = val;

  return me;
};

WWW_Applet.prototype.def_vars = function (funcs) {

  var me = this;

  _.each(funcs, function (v, k) {
    me.def_var(k, v);
  }); // === _.each

  return me;
};

WWW_Applet.prototype.clone = function () {
  var me = WWW_Applet.new([], null, this);
  return me;
};

WWW_Applet.prototype.eval = function (args) {
  var a = WWW_Applet.new(args, null, this);
  a.run();
  return a;
};

WWW_Applet.prototype.run = function () {
  var me        = this;
  var code      = me.source;
  var l         = code.length;
  var i         = 0;
  var next      = null;
  var results   = [];


  while(i < l) {

    var func_name = code[i];
    i = i + 1;

    // === if we are evaluating arguments:
    if (me.parent) {

      // === Push on to stack and continue, if:
      //       not a string
      //       or end of code
      //       or next is not an Array
      // =======================================
      if (!_.isString(func_name) || i == l || !_.isArray(code[i])) {
        me.stack.push(func_name);
        continue;
      }

    } // === if me.parent

    var func_args = code[i];
    i = i + 1;

    // === Check for valid function call.
    if (!_.isString(func_name))
      throw (new Error("Invalid input: " + func_name));
    func_name = $.trim(func_name);

    if (func_name.length == 0)
      throw (new Error("Empty string used for function name. Args: " + func_args));

    // === Check for valid function arguments.
    if (!_.isArray(func_args))
      throw (new Error("Invalid input. Func: " + func_name + " Args: " + func_args));

    // === Find function.
    var func = me.read_var(func_name);

    if (!func)
      throw (new Error("Function not found: " + func_name));


    var func_env = {
      name: func_name,
      args: func.use_raw ? func_args : me.eval(func_args).stack,
      func: func,
      app:  me
    };

    // === Run function.
    if (_.isArray(func)) { // === User-defined function

      var result = me.eval(func).stack;

    } else { // === Programmer-defined function.

      if (!_.isFunction(func))
        throw (new Error('Not a function: Name: ' + func_name + ' Value: ' + func));
      var result = func(func_env, me.clone());

    }


    if (me.parent)
      me.stack.push(result);

  } // === while


  return me;
}; // === WWW_Applet.prototype.run


// ================================================================
//                    Base Funcs
// ================================================================

WWW_Applet.Base_Funcs = {
  'var' : function (env, app) {
    if (env.args.length == 1)
      return app.read_var(env.args[0]);
    else
      return app.def_var(env.args[0], env.args[1]);
  },
  'function'   : function (env, app) {
    return env.args;
  },
  'log'        : function (env, app) {
    console['log'].apply(console['log'], env.args);
  }
};

WWW_Applet.Base_Funcs['function'].use_raw = true;




