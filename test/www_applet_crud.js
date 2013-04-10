
describe( '.def_tag', function () {
  it( 'turns a null for args def into: { }', function () {
    assert.equal(false, true);
  });

  it( 'accepts an array as an argument instead of array', function () {
    var args = {val: "anything"};
    var results = null;

    var app = Applet.new(['box', args, ["some text"]]);
    app.def_tag('box', ['val'], function (m, tag, attrs, content) {
      dfsdf()
      results = attrs;
      return [tag, attrs, content];
    });
    RUN(app);

    assert.equal(results, args);
  });
}); // === end desc
