

// ================================================================
// Test 1
// ================================================================


var program = [
  "var", ['One', 'test 1'],
  "Hello", ['var', ['ONE']]
];

var temp = WWW_Applet.new(program, {
  hello: function (env, app) {
    console.log(env.name + ", " + env.args[0] + ".");
  }
});

temp.run();


// ================================================================
// Test 2
// ================================================================

var program = [
  "var", ["hello world", 'function', [
    "log", ['Hello', 'Test 2']
  ]],
  "hello world", []
];

var temp = WWW_Applet.new(program);

temp.run();


// ================================================================
// Test 3: Saving data.
// ================================================================

var funcs = {
  'print data' : function (env, app) {
    console['log'](app.data('msg'));
  }
};

var temp = WWW_Applet.new(['print data', []], funcs);
temp.data('msg', 'Hello, World of Data.');
temp.run();
