
"use strict";

QUnit.test( "it runs the code", function( assert ) {
  WWW_Applet.run([""]);
  assert.ok( 1 === "1", "Passed!" );
});

