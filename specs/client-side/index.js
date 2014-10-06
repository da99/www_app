
"use strict";

/* global QUnit */
/* global WWW_App */
/* global _ */
/* global expect */
/*jshint multistr:true */


// ==== Helpers: ====================================================
var when_count = 0;
var when_do_this = function (when, do_this) {
  setTimeout(function () {
    if (when()) {
      when_count = 0;
      do_this();
    } else {
      when_count = when_count + 1;
      if (when_count > 20) {
        when_count = 0;
        QUnit.start();
      } else {
        when_do_this(when, do_this);
      }
    }
  }, 100);
}; // when_do_this
// ==================================================================


// ==================================================================
QUnit.module("WWW_App");
// ==================================================================

QUnit.test( "it runs the code", function ( assert ) {
  WWW_App.run([
    "focus on", ['#box_1'],
    "add class", ['weird']
  ]);
  assert.ok( $('#box_1').hasClass('weird') === true, "Passed!" );
});


QUnit.test( "it evals the args as code", function( assert ) {
  var o = WWW_App.run([
    "add to stack", ["array", [1,2,3]]
  ]);
  assert.deepEqual( o.right('all'), [[1,2,3]], "Args are eval'd before run." );
});


QUnit.test("throws error if not enough stack values", function (assert) {
  assert.throws(function () {
    WWW_App.run(['less or equal', [5]]);
  }, /Not enough values in stack/);
});


QUnit.test("throws error if not enough arg values", function (assert) {
  assert.throws(function () {
    WWW_App.run(['less or equal', []]);
  }, /Not enough values in args/);
});


// ==================================================================
QUnit.module("less or equal");
// ==================================================================

QUnit.test('it places true if: 5 <= 6', function (assert) {
  var o = WWW_App.run([
    5, "less or equal", [ 6 ]
  ]);
  assert.equal( o.right('last'), true);
});

QUnit.test('it places true if: 6 <= 6', function (assert) {
  var o = WWW_App.run([
    6, "less or equal", [ 6 ]
  ]);
  assert.equal( o.right('last'), true);
});

QUnit.test('it places false if: 7 <= 6', function (assert) {
  var o = WWW_App.run([
    7, "less or equal", [ 6 ]
  ]);
  assert.equal( o.right('last'), false);
});

QUnit.test('throws error if first num is not a number', function (assert) {
  assert.throws(function () {
    WWW_App.run([
      '5', 'less or equal', [5] 
    ]);
  }, /Value in stack is not a Number: String: 5/);
});

QUnit.test('throws error if second num is not a number', function (assert) {
  assert.throws(function () {
    WWW_App.run([
      5, 'less or equal', ["6"] 
    ]);
  }, /Value in args is not a Number: String: 6/);
});


// ==================================================================
QUnit.module("bigger or equal");
// ==================================================================

QUnit.test('it places true if: 6 >= 4', function (assert) {
  var o = WWW_App.run([
    6, "bigger or equal", [ 4 ]
  ]);
  assert.equal( o.right('last'), true);
});

QUnit.test('it places true if: 6 >= 6', function (assert) {
  var o = WWW_App.run([
    6, "bigger or equal", [ 6 ]
  ]);
  assert.equal( o.right('last'), true);
});

QUnit.test('it places false if: 6 >= 7', function (assert) {
  var o = WWW_App.run([
    6, "bigger or equal", [ 7 ]
  ]);
  assert.equal( o.right('last'), false);
});

QUnit.test('throws error if first num is not a number', function (assert) {
  assert.throws(function () {
    WWW_App.run([
      '3', 'bigger or equal', [5] 
    ]);
  }, /Value in stack is not a Number: String: 3/);
});

QUnit.test('throws error if second num is not a number', function (assert) {
  assert.throws(function () {
    WWW_App.run([
      5, 'bigger or equal', ["9"] 
    ]);
  }, /Value in args is not a Number: String: 9/);
});


// ==================================================================
QUnit.module('bigger');
// ==================================================================

QUnit.test('it places true on stack if: 6 > 1', function (assert) {
  var o = WWW_App.run([
    6, 'bigger', [1]
  ]);
  assert.equal(o.right('last'), true);
});


QUnit.test('it places false on stack if: 6 > 6', function (assert) {
  var o = WWW_App.run([
    6, 'bigger', [6]
  ]);
  assert.equal(o.right('last'), false);
});


// ==================================================================
QUnit.module('less');
// ==================================================================

QUnit.test('it places true on stack if: 1 < 6', function (assert) {
  var o = WWW_App.run([
    1, 'less', [6]
  ]);
  assert.equal(o.right('last'), true);
});


QUnit.test('it places false on stack if: 6 < 6', function (assert) {
  var o = WWW_App.run([
    6, 'less', [6]
  ]);
  assert.equal(o.right('last'), false);
});

QUnit.test('it places false on stack if: 6 < 1', function (assert) {
  var o = WWW_App.run([
    6, 'less', [1]
  ]);
  assert.equal(o.right('last'), false);
});


// ==================================================================
QUnit.module('equal');
// ==================================================================

QUnit.test('it places true on stack if: 1 === 1', function (assert) {
  var o = WWW_App.run([
    1, 'equal', [1]
  ]);
  assert.equal(o.right('last'), true);
});

QUnit.test('it places true on stack if: \'a\' === \'a\'', function (assert) {
  var o = WWW_App.run([
    "a", 'equal', ["a"]
  ]);
  assert.equal(o.right('last'), true);
});

QUnit.test('it places false on stack if: \'5\' === 5', function (assert) {
  var o = WWW_App.run([
    "5", 'equal', [5]
  ]);
  assert.equal(o.right('last'), false);
});


QUnit.test('it places false on stack if: 6 === \'6\'', function (assert) {
  var o = WWW_App.run([
    6, 'equal', ["6"]
  ]);
  assert.equal(o.right('last'), false);
});


// ==================================================================
QUnit.module('and');
// ==================================================================

QUnit.test('throws error if last value on stack is not a bool', function (assert) {
  assert.throws(function () {
  var o = WWW_App.run([
    1, 'and', [true]
  ]);
  }, /Value in stack is not a Boolean: Number: 1/);
});

QUnit.test('throws if last value of args is not a bool', function (assert) {
  assert.throws(function () {
    var o = WWW_App.run([
      true, 'and', [2]
    ]);
  }, /Value in args is not a Boolean: Number: 2/);
});

QUnit.test('it places true on stack if both conditions are true', function (assert) {
  var o = WWW_App.run([
    true, 'and', [6, 'equal', [6]]
  ]);
  assert.equal(o.right('last'), true);
});

QUnit.test('it places false on stack if first condition is false', function (assert) {
  var o = WWW_App.run([
    false, 'and', [6, 'equal', [6]]
  ]);
  assert.deepEqual(o.right('all'), [false, false]);
});

QUnit.test('it places false on stack if second condition is false', function (assert) {
  var o = WWW_App.run([
    true, 'and', [6, 'equal', [7]]
  ]);
  assert.deepEqual(o.right('all'), [true, false]);
});

QUnit.test('does not evaluate args if right-hand value is false', function (assert) {
  var o = WWW_App.run([
    false, 'and', ['unknown method', []]
  ]);
  assert.deepEqual(o.right('all'), [false, false]);
});


// ==================================================================
QUnit.module('or');
// ==================================================================

QUnit.test('it throws an error if first condition is not a bool', function (assert) {
  assert.throws(function () {
    WWW_App.run(["something", 'or', [false]]);
  }, /Value in stack is not a Boolean: String: something/);
});

QUnit.test('it throws an error if second condition is not a bool', function (assert) {
  assert.throws(function () {
    WWW_App.run([false, 'or', [false, "something"]]);
  }, /Value in args is not a Boolean: String: something/);
});

QUnit.test('it places true on stack if both conditions are true', function (assert) {
  var o = WWW_App.run([
    true, 'or', [6, 'equal', [6]]
  ]);
  assert.deepEqual(o.right('all'), [true, true]);
});

QUnit.test('it places true on stack if: true or false', function (assert) {
  var o = WWW_App.run([
    true, 'or', [9, 'equal', [6]]
  ]);
  assert.deepEqual(o.right('all'), [true, true]);
});

QUnit.test('it places true on stack if: false or true', function (assert) {
  var o = WWW_App.run([
    false, 'or', [9, 'equal', [9]]
  ]);
  assert.deepEqual(o.right('all'), [false, true]);
});

QUnit.test('does not evaluate args if first condition is true', function (assert) {
  var o = WWW_App.run([
    true, 'or', ['no known method', []]
  ]);
  assert.deepEqual(o.right('all'), [true, true]);
});


// ==================================================================
QUnit.module('if true');
// ==================================================================

QUnit.test('throws an error if righ hand value is not a bool', function (assert) {
  assert.throws(function () {
    WWW_App.run([
      6, "if true", [5]
    ]);
  }, /Value in stack is not a Boolean: Number: 6/);
});

QUnit.test('does not place a value on stack', function (assert) {
  var o = WWW_App.run([
    true, "if true", [
      100
    ]
  ]);

  assert.deepEqual(o.right('all'), [true]);
});

QUnit.test('does not run tokens if stack value is false', function (assert) {
  var o = WWW_App.run([
    false, "if true", [
      "something unknown", []
    ]
  ]);

  assert.deepEqual(o.right('all'), [false]);
});


// ==================================================================
QUnit.module('if false');
// ==================================================================

QUnit.test('throws an error if righ hand value is not a bool', function (assert) {
  assert.throws(function () {
    WWW_App.run([
      7, "if false", [5]
    ]);
  }, /Value in stack is not a Boolean: Number: 7/);
});

QUnit.test('does not place a value on stack', function (assert) {
  var o = WWW_App.run([
    false, "if false", [ 100 ]
  ]);

  assert.deepEqual(o.right('all'), [false]);
});

QUnit.test('does not run tokens if stack value is true', function (assert) {
  var o = WWW_App.run([
    true, "if false", [ "something unknown", [] ]
  ]);

  assert.deepEqual(o.right('all'), [true]);
});


// ==================================================================
QUnit.module('on click button');
// ==================================================================

QUnit.test('adds event to element', function (assert) {

  $('#event').html(
    '\
      <div class="the_box">                       \
        <div><div>                                \
          <button class="red">Red</button>  \
          <button class="blue">Blue</button>  \
        </div></div>                              \
      </div>                                      \
    '
  );

  var event = WWW_App.run([
    '/red/div.the_box', 'does', [ 'add class', ['red'] ]
  ]); // ======================

  $('#event button.red').trigger('click');
  assert.equal($('#event div.the_box').hasClass('red'), true);

}); // === adds event to element


// ==================================================================
QUnit.module('on click "a" link');
// ==================================================================

QUnit.test('adds event to element', function (assert) {

  $('#event').html(
    '\
      <div class="the_box">                \
        <div><div>                         \
          <a href="#white">White</button>  \
          <a href="#blue">Blue</button>    \
        </div></div>                       \
      </div>                               \
    '
  );

  var event = WWW_App.run([
    '/red/div.the_box', 'does', [ 'add class', ['white'] ]
  ]); // ======================

  $('#event a.white').trigger('click');
  assert.equal($('#event div.the_box').hasClass('white'), true);

}); // === adds event to element


// ==================================================================
QUnit.module('allow (event)');
// ==================================================================

QUnit.test('adds event to element', function (assert) {

  $('#event').html(
    '\
      <div class="the_box">                \
        <div><div>                         \
          <div class="blue"></div>         \
        </div></div>                       \
      </div>                               \
    '
  );

  var event = WWW_App.run([
    'div.the_box div.blue', 'allows' [ 'mousedown' ],
    '/blue/div.the_box', 'does', [ 'add class', ['blue'] ]
  ]); // ======================

  $('#event div.the_box div.blue').trigger('mousedown');
  assert.equal($('#event div.the_box').hasClass('blue'), true);

}); // === adds event to element

QUnit.test('runs multiple defined "does"', function (assert) {

  $('#event').html(
    '\
      <div class="the_box">                \
        <div><div>                         \
          <div class="orange"></div>       \
        </div></div>                       \
      </div>                               \
    '
  );

  var event = WWW_App.run([
    'div.the_box div.orange', 'allows', [ 'mousedown' ],
    '/orange/div.the_box', 'does', [ 'add class', ['orange'] ],
    '/orange/div.the_box', 'does', [ 'add class', ['white']  ],
    '/orange/div.the_box', 'does', [ 'add class', ['black']  ]
  ]); // ======================

  $('#event div.the_box div.orange').trigger('mousedown');
  assert.equal($('#event div.the_box').attr('class'), 'the_box orange white black');
});

QUnit.test('is ignored if called before on the same element', function (assert) {
  $('#event').html(
    '\
      <div class="the_box">                \
        <div></div>                        \
        <div></div>                        \
        <div></div>                        \
      </div>                               \
    '
  );

  var event = WWW_App.run([
    'div.the_box', 'allows', ['click'],
    'div.the_box', 'allows', ['click'],
    'div.the_box', 'allows', ['click'],
    'div.the_box', 'allows', ['click'],
    '/click/div.the_box', 'does', ['remove', ['div:first']]
  ]);

  $('#event div.the_box').trigger('click');
  assert.equal($('#event div.the_box div').length, 2);
});

QUnit.test('runs "does" on child elements of event target', function (assert) {

  $('#event').html(
    '\
      <div class="the_box">                \
        <div><div>                         \
          <div class="grey">               \
            <div><div class="child"></div></div> \
          </div>                           \
        </div></div>                       \
      </div>                               \
    '
  );

  var event = WWW_App.run([
    'div.the_box div.grey', 'allows', [ 'mousedown' ],
    '/grey/div.child', 'does', [ 'add class', ['one']    ],
    '/grey/div.child', 'does', [ 'add class', ['two']    ]
  ]); // ======================

  $('#event div.the_box div.grey').trigger('mousedown');
  assert.equal($('#event div.the_box div.grey div.child').attr('class'), 'child one two');
});

QUnit.test('runs "does" on event target itself', function (assert) {

  $('#event').html(
    '\
      <div class="the_box">                \
        <div><div>                         \
          <div class="grey">               \
            <div><div class="child"></div></div> \
          </div>                           \
        </div></div>                       \
      </div>                               \
    '
  );

  var event = WWW_App.run([
    'div.the_box div.grey', 'allows', [ 'mousedown' ],
    'grey', 'does', [ 'add class', ['three']   ],
    'grey', 'does', [ 'add class', ['four']    ]
  ]); // ======================

  $('#event div.the_box div.grey').trigger('mousedown');
  assert.equal($('#event div.the_box div.grey').attr('class'), 'grey three four');
});

QUnit.test('allows to specify event name with selector', function (assert) {

  $('#event').html(
    '\
      <div class="the_box">              \
        <div class="grey one"></div>     \
        <div class="grey two"></div>     \
      </div>                             \
    '
  );

  var event = WWW_App.run([
    'div.the_box div.grey', 'allows', [ 'mousedown' ],
    '/.the_box/div.grey:first  , div.the_box', 'does', [ 'add class', ['one']  ],
    '/.the_box/div.grey:second , div.the_box', 'does', [ 'add class', ['two']  ]
  ]); // ======================

  $('#event div.the_box div.grey.one').trigger('mousedown');
  assert.equal($('#event div.the_box').attr('class'), 'the_box one');

  $('#event div.the_box div.grey.two').trigger('mousedown');
  assert.equal($('#event div.the_box').attr('class'), 'the_box one two');
});

// ==================================================================
QUnit.module('forms');
// ==================================================================

QUnit.test('throws error if url contains invalid char: :', function (assert) {
  $('#form_1').attr('action', 'javascrip://alert');
  assert.throws(function () {
    $('#form_1 button.post').trigger('click');
  }, /Invalid chars in #form_1 action: javascrip:/);
});

QUnit.test('throws error if url contains invalid char: &', function (assert) {
  $('#form_1').attr('action', 'javascript&amp//alert');
  assert.throws(function () {
    $('#form_1 button.post').trigger('click');
  }, /Invalid chars in #form_1 action: javascript&amp/);
});

QUnit.test('throws error if url contains invalid char: ;', function (assert) {
  $('#form_1').attr('action', 'http;amp//alert');
  assert.throws(function () {
    $('#form_1 button.post').trigger('click');
  }, /Invalid chars in #form_1 action: http;amp/);
});


QUnit.asyncTest('submits form values', function (assert) {
  expect(1);

  $('#form_1').attr('action', '/repeat/vals');

  var env = WWW_App.run([
    'success -> #form_1', 'does', [
      'log', ['get', ['data']]
    ]
  ]);

  var when = function () {
    return $('#form_1').hasClass('submitted');
  }; // function

  var do_this = function () {
    assert.deepEqual(_.last(env.log), {val_1: '1', val_2: '2', val_3: '3'});
    QUnit.start();
  }; // function

  $('#form_1 button.post').trigger('click');
  when_do_this(when, do_this);
});





