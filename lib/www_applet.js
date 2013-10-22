
// require jquery
// require underscore


// ================================================================
//                    Define Container
// ================================================================

var Applet = function (source, funcs) {};

// ================================================================
//                    Helpers
// ================================================================

Applet.SPACES   = /\ +/g;
Applet.quote = function (str) { return '"' + str + '"'; }


// ================================================================
//                    Main Stuff
// ================================================================

Applet.new = function (source, funcs) {

  var me = new Applet;

  me.source  = source;
  me.error   = null;
  me.vars    = {};

  if (funcs)
    me.multi_def(funcs);

  return me;
}

Applet.prototype.multi_def = function (funcs) {

  var me = this;

  _.each(funcs, function (v, k) {
    me.vars[k] = v;
  }); // === _.each

  return me;
};


Applet.prototype.run = function () {
  var me        = this;
  var code      = me.source;
  var l         = code.length;
  var i         = 0;
  var next      = null;
  var results   = [];


  while(i < l) {

    var func_name = code[i];

    i = i + 1;
    var func_args  = code[i];

    i = i + 1;

    if (!_.isString(func_name))
      throw (new Error("Invalid input: " + func_name));
    func_name = $.trim(func_name);
    if (func_name.length == 0)
      throw (new Error("Empty string used for function name. Args: " + func_args));

    if (!_.isArray(func_args))
      throw (new Error("Invalid input: " + func_args));

    var func = me.vars[func_name];

    if (!func)
      throw (new Error("Function not found: " + func_name));

    var func_env = {
      name: func_name,
      args: func_args,
      func: func,
      app:  me
    };

    func(func_env);

  } // === while


  return me;
}; // === Applet.prototype.run







