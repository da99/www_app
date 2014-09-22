
"use strict";

QUnit.test( "it runs the code", function( assert ) {
  WWW_Applet.run([
    "focus on", ['#box_1'],
    "add class", ['class_1']
  ]);
  assert.ok( $('#box_1').hasClass('class_1') === true, "Passed!" );
});

