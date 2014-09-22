
"use strict";

QUnit.test( "it runs the code", function( assert ) {
  WWW_Applet.run([
    "focus on", ['#box_1'],
    "add class", ['weird']
  ]);
  assert.ok( $('#box_1').hasClass('weird') === true, "Passed!" );
});

