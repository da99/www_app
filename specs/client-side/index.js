
"use strict";

QUnit.test( "it runs the code", function( assert ) {
  WWW_Applet.run([
    "focus on", ['#box_1'],
    "add class", ['weird']
  ]);
  assert.ok( $('#box_1').hasClass('weird') === true, "Passed!" );
});


QUnit.test( "it evals the args as code", function( assert ) {
  var o = WWW_Applet.run([
    "add to stack", ["array", [1,2,3]]
  ]);
  assert.deepEqual( o.stack, [[1,2,3]], "Args are eval'd before run." );
});


