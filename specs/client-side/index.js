
"use strict";

/* global QUnit */
/* global WWW_Applet */
/* global _ */

// ==================================================================
QUnit.module("WWW_Applet");
// ==================================================================

QUnit.test( "it runs the code", function ( assert ) {
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



// ==================================================================
QUnit.module("less or equal");
// ==================================================================

QUnit.test('it places true if: 5 <= 6', function (assert) {
  var o = WWW_Applet.run([
    5, "less or equal", [ 6 ]
  ]);
  assert.equal( _.last(o.stack), true);
});

QUnit.test('it places true if: 6 <= 6', function (assert) {
  var o = WWW_Applet.run([
    6, "less or equal", [ 6 ]
  ]);
  assert.equal( _.last(o.stack), true);
});

QUnit.test('it places false if: 7 <= 6', function (assert) {
  var o = WWW_Applet.run([
    7, "less or equal", [ 6 ]
  ]);
  assert.equal( _.last(o.stack), false);
});

QUnit.test('throws error if first num is not a number', function (assert) {
  assert.throws(function () {
    WWW_Applet.run([
      '5', 'less or equal', [5] 
    ])
  }, /Not numeric: "5"/);
});


QUnit.test('throws error if second num is not a number', function (assert) {
  assert.throws(function () {
    WWW_Applet.run([
      5, 'less or equal', ["6"] 
    ])
  }, /Not numeric: "6"/);
});

