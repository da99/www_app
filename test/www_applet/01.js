

// ================================================================
// Test 1
// ================================================================


var program = [
  "var create", ['One', 'test 1'],
  "Hello", ['var', ['ONE']]
];

var temp = Applet.new(program, {
  hello: function (env, app) {
    console.log(env.name + ", " + env.args[0] + ".");
  }
});

temp.run();


// ================================================================
// Test 2
// ================================================================

var program = [
  "var create", ["hello world", 'function', [
    "log", ['Hello', 'Test 2']
  ]],
  "hello world", []
];

var temp = Applet.new(program);

temp.run();

