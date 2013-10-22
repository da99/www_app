
var f = {
  hello: function (env) {
    console.log(env.name + ", World.");
  }
};

Applet.new(["Hello", []], f).run();
