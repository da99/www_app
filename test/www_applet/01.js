
var f = {
  hello: function (env, app) {
    console.log(env.name + ", " + env.args[0] + ".");
  }
};

var program = [
  "var create", ['Target', 'World'],
  "Hello", ['var', ['tArGet']]
];

var temp = Applet.new(program, f);
temp.run();
