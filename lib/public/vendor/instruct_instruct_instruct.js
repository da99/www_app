"use strict";

/* jshint undef: true, unused: true */
/* global _ */ 

var instruct_instruct_instruct = function (funcs) {
  this.funcs = _.merge(instruct_instruct_instruct.base, funcs);
  this.stack = null;
  return this;
};


// === Scope
(function () {
  var I = instruct_instruct_instruct;
  var jquery_proxy = $('body');

  function log() {
    if (window.console)
      console['log'].apply(console, arguments);
  }

  function is_numeric(val) {
    return _.isNumber(val) && !_.isNaN(val);
  }

  function concat() {
    var args = _.toArray(arguments);
    var base = _.first(args);
    var arrs = _.rest(args);
    _.each(arrs, function (v) {
      _.each(v, function (val) {
        base.push(val);
      });
    });
    return base;
  }

  function inspect(o) {
    return '(' + typeof(o) + ') "' + o + '"' ;
  }

  instruct_instruct_instruct.base = {
    'add to stack': function (iii) {
      concat(iii.stack, iii.shift('all'));
    },
    '$': function (iii) {
      var args = iii.shift('all');
      if (_.isEmpty(args))
        return $(iii.pop('string'));
      else
        return $.apply($, args);
    },
    'array': function (iii) {
      return iii.shift('all');
    },
    "or": function (iii) {
      var left = iii.pop('boolean');
      if (left)
        return true;
      return iii.shift('boolean');
    },
    'and': function (iii) {
      var left = iii.pop('boolean');
      if (left)
        return left === iii.shift('boolean');
      else
        return false;
    },
    'if true': function (iii) {
      var left = iii.pop('boolean');
      if (!left)
        return left;
      iii.shift('all');
      return left;
    },
    'if false': function (iii) {
      var left = iii.pop('boolean');
      if (left)
        return left;
      iii.shift('all');
      return left;
    },
    'less or equal': function (iii) {
      var left = iii.pop('number');
      var right = iii.shift('number');
      return left <= right;
    },
    'bigger or equal': function (iii) {
      var left = iii.pop('number');
      var right = iii.shift('number');
      return left >= right;
    },
    'bigger': function (iii) {
      return iii.pop('number') > iii.shift('number');
    },
    'less': function (iii) {
      return iii.pop('number') < iii.shift('number');
    },
    'equal': function (iii) {
      var left  = iii.pop();
      var right = iii.shift();
      var l_type = typeof(left);
      var r_type = typeof(right);

      if (l_type !== r_type)
        throw new Error("Type mis-match: " + inspect(left) + ' !== ' + inspect(right));
      return left === right;
    }
  };

  I.prototype.spawn = function () {
    var funcs = _.clone(this.funcs);
    return new instruct_instruct_instruct(funcs);
  }; // function

  I.prototype.run = function (raw_code) {
    var self      = this;
    var left      = [];
    var code      = _.clone(raw_code);
    var o         = null;
    var last_o    = null;
    var func_name = null;
    var result    = null;
    var jquery    = null;

    var env = {
      stack: left,
      run_args : function () {
        if (!_.isUndefined(this.raw_args))
          this.args = self.spawn().run(this.raw_args).stack;
        this.raw_args = undefined;

        return this.args;
      },

      pop: function (type) {
        var val;
        var is_empty = _.isEmpty(left);

        if (is_empty) {
          if (type)
            throw new Error("Left Stack underflow while popping for " + type + '.');
          else
            throw new Error("Left Stack underflow while popping.");
        }

        val = left.pop();

        switch (type) {
          case 'number':
            if (!is_numeric(val))
              throw new Error("Left Stack popped value is not a number: " + inspect(val));
            break;

          case 'string':
            if (!_.isString(val))
              throw new Error("Left Stack popped value is not a string: " + inspect(val));
            break;

          case 'boolean':
            if (!_.isBoolean(val))
              throw new Error("Left Stack popped value is not a boolean: " + inspect(val));
            break;

          default:
            if (type !== undefined)
              throw new Error("Unknown type for .pop(): " + inspect(type));
        } // === switch

        return val;
      },

      shift: function (type) {
        this.run_args();
        if (type === 'all') {
          var vals = this.args;
          this.args = [];
          return vals;
        }

        if (_.isEmpty(this.args)) {
          if (type)
            throw new Error("Argument Stack underflow while shifting for " + type + ".");
          else
            throw new Error("Argument Stack underflow.");
        }

        var val = this.args.shift();

        switch (type) {
          case 'number':
            if (!is_numeric(val))
              throw new Error("Argument Stack shifted value is not a number: " + inspect(val));
            break;
          case 'string':
            if (!_.isString(val))
              throw new Error("Argument Stack shifted value is not a string: " + inspect(val));
            break;
          case 'boolean':
            if (!_.isBoolean(val))
              throw new Error("Argument Stack shifted value is not a boolean: " + inspect(val));
            break;

          default:
            if (type !== undefined)
              throw new Error("Unknown type for .shift(): " + inspect(type));
        } // === switch

        return val;
      }
    };

    while (!_.isEmpty(code)) {
      o = code.shift();
      if (_.isString(o) || is_numeric(o) || _.isBoolean(o)) {
        left.push(o);
      } else if (_.isArray(o)) {
        if (!_.isString(last_o)) {
          throw new Error('Invalid data type for function name: ' + inspect(last_o));
        }
        env.raw_args = o;
        func_name    = left.pop();
        if (!this.funcs[func_name]) {
          if (!jquery_proxy[func_name])
            throw new Error("Func not found: " + func_name);
          jquery = _.last(left)[func_name] ? left.pop() : $(env.pop('string'));
          result = jquery[func_name].apply(jquery, env.shift('all'));
        } else {
          result = this.funcs[func_name](env);
        }
        if (result !== undefined)
          left.unshift( result );
      } else {
        throw new Error("Invalid data type: " + inspect(o));
      }

      last_o = o;
    } // === while i < size

    return {
      code: raw_code,
      stack: left
    };
  }; // function run

})(); // === scope
