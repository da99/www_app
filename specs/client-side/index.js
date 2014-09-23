
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
  }, /Not numeric: String: 5/);
});

QUnit.test('throws error if second num is not a number', function (assert) {
  assert.throws(function () {
    WWW_Applet.run([
      5, 'less or equal', ["6"] 
    ])
  }, /Not numeric: String: 6/);
});


// ==================================================================
QUnit.module("bigger or equal");
// ==================================================================

QUnit.test('it places true if: 6 >= 4', function (assert) {
  var o = WWW_Applet.run([
    6, "bigger or equal", [ 4 ]
  ]);
  assert.equal( _.last(o.stack), true);
});

QUnit.test('it places true if: 6 >= 6', function (assert) {
  var o = WWW_Applet.run([
    6, "bigger or equal", [ 6 ]
  ]);
  assert.equal( _.last(o.stack), true);
});

QUnit.test('it places false if: 6 >= 7', function (assert) {
  var o = WWW_Applet.run([
    6, "bigger or equal", [ 7 ]
  ]);
  assert.equal( _.last(o.stack), false);
});

QUnit.test('throws error if first num is not a number', function (assert) {
  assert.throws(function () {
    WWW_Applet.run([
      '3', 'bigger or equal', [5] 
    ])
  }, /Not numeric: String: 3/);
});

QUnit.test('throws error if second num is not a number', function (assert) {
  assert.throws(function () {
    WWW_Applet.run([
      5, 'bigger or equal', ["9"] 
    ])
  }, /Not numeric: String: 9/);
});


// ==================================================================
QUnit.module('bigger');
// ==================================================================

QUnit.test('it places true on stack if: 6 > 1', function (assert) {
  var o = WWW_Applet.run([
    6, 'bigger', [1]
  ]);
  assert.equal(_.last(o.stack), true);
});


QUnit.test('it places false on stack if: 6 > 6', function (assert) {
  var o = WWW_Applet.run([
    6, 'bigger', [6]
  ]);
  assert.equal(_.last(o.stack), false);
});


// ==================================================================
QUnit.module('less');
// ==================================================================

QUnit.test('it places true on stack if: 1 < 6', function (assert) {
  var o = WWW_Applet.run([
    1, 'less', [6]
  ]);
  assert.equal(_.last(o.stack), true);
});


QUnit.test('it places false on stack if: 6 < 6', function (assert) {
  var o = WWW_Applet.run([
    6, 'less', [6]
  ]);
  assert.equal(_.last(o.stack), false);
});

QUnit.test('it places false on stack if: 6 < 1', function (assert) {
  var o = WWW_Applet.run([
    6, 'less', [1]
  ]);
  assert.equal(_.last(o.stack), false);
});


// ==================================================================
QUnit.module('equal');
// ==================================================================

QUnit.test('it places true on stack if: 1 === 1', function (assert) {
  var o = WWW_Applet.run([
    1, 'equal', [1]
  ]);
  assert.equal(_.last(o.stack), true);
});

QUnit.test('it places true on stack if: \'a\' === \'a\'', function (assert) {
  var o = WWW_Applet.run([
    "a", 'equal', ["a"]
  ]);
  assert.equal(_.last(o.stack), true);
});

QUnit.test('it places false on stack if: \'5\' === 5', function (assert) {
  var o = WWW_Applet.run([
    "5", 'equal', [5]
  ]);
  assert.equal(_.last(o.stack), false);
});


QUnit.test('it places false on stack if: 6 === \'6\'', function (assert) {
  var o = WWW_Applet.run([
    6, 'equal', ["6"]
  ]);
  assert.equal(_.last(o.stack), false);
});





