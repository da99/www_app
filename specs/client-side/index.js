
"use strict";

/* global QUnit */
/* global WWW_App */
/* global _ */
/* global expect */
/*jshint multistr:true */


// ==== Helpers: ====================================================
var when_count = 0;
var do_this = function (do_f) {
  return {
    when: function (when_f) {
      return setTimeout(function () {
        if (when_f()) {
          when_count = 0;
          do_f();
        } else {
          when_count = when_count + 1;
          if (when_count > 15) {
            when_count = 0;
            QUnit.start();
          } else {
            do_this(do_f).when(when_f);
          }
        }
      }, 100);
    }
  };
}; // do_this

// ==================================================================


// ==================================================================
QUnit.module("WWW_App");
// ==================================================================





// ==================================================================
describe('on click button');
// ==================================================================

it('only runs specified callback', function (assert) {

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

  var event = iii.run([
    '/red/div.the_box', 'does', [ 'add class', ['red'] ],
    '/red/div.the_box', 'does', [ 'add class', ['red_two'] ],
    '/blue/div.the_box', 'does', [ 'unknown func', ['blue'] ],
  ]); // ======================

  $('#event button.red').trigger('click');
  assert.equal($('#event div.the_box').hasClass('red'), true);
  assert.equal($('#event div.the_box').hasClass('red_two'), true);

}); // === only runs one callback

it('adds event to element', function (assert) {

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

  var event = iii.run([
    '/red/div.the_box', 'does', [ 'add class', ['red'] ],
    '/blue/div.the_box', 'does', [ 'reove class', ['red'], 'ad clss', ['blue'] ],
  ]); // ======================

  $('#event button.red').trigger('click');
  assert.equal($('#event div.the_box').hasClass('red'), true);

}); // === adds event to element


// ==================================================================
describe('on click "a" link');
// ==================================================================

it('adds event to element', function (assert) {

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

  var event = iii.run([
    '/white/div.the_box', 'does', [ 'add class', ['white'] ]
  ]); // ======================

  $('#event a[href="#white"]').trigger('click');
  assert.equal($('#event div.the_box').hasClass('white'), true);

}); // === adds event to element


// ==================================================================
describe('allow (event)');
// ==================================================================

it('adds event to element', function (assert) {

  $('#event').html(
    '\
      <div class="the_box">                \
        <div><div>                         \
          <div class="blue"></div>         \
        </div></div>                       \
      </div>                               \
    '
  );

  var event = iii.run([
    'div.the_box div.blue', 'allows', [ 'mousedown' ],
    '/blue/div.the_box', 'does', [ 'add class', ['blue'] ]
  ]); // ======================

  $('#event div.the_box div.blue').trigger('mousedown');
  assert.equal($('#event div.the_box').hasClass('blue'), true);

}); // === adds event to element

it('runs multiple defined "does"', function (assert) {

  $('#event').html(
    '\
      <div class="the_box">                \
        <div><div>                         \
          <div class="orange"></div>       \
        </div></div>                       \
      </div>                               \
    '
  );

  var event = iii.run([
    'div.the_box div.orange', 'allows', [ 'mousedown' ],
    '/orange/div.the_box', 'does', [ 'add class', ['orange'] ],
    '/orange/div.the_box', 'does', [ 'add class', ['white']  ],
    '/orange/div.the_box', 'does', [ 'add class', ['black']  ]
  ]); // ======================

  $('#event div.the_box div.orange').trigger('mousedown');
  assert.equal($('#event div.the_box').attr('class'), 'the_box orange white black');
});

it('is ignored if called before on the same element', function (assert) {
  $('#event').html(
    '\
      <div class="the_box">                \
        <div></div>                        \
        <div></div>                        \
        <div></div>                        \
      </div>                               \
    '
  );

  var event = iii.run([
    'div.the_box', 'allows', ['click'],
    'div.the_box', 'allows', ['click'],
    'div.the_box', 'allows', ['click'],
    'div.the_box', 'allows', ['click'],
    '/click/div.the_box', 'does', ['remove', ['div:first']]
  ]);

  $('#event div.the_box').trigger('click');
  assert.equal($('#event div.the_box div').length, 2);
});

it('runs "does" on child elements of event target', function (assert) {

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

  var event = iii.run([
    'div.the_box div.grey', 'allows', [ 'mousedown' ],
    '/grey/div.child', 'does', [ 'add class', ['one']    ],
    '/grey/div.child', 'does', [ 'add class', ['two']    ]
  ]); // ======================

  $('#event div.the_box div.grey').trigger('mousedown');
  assert.equal($('#event div.the_box div.grey div.child').attr('class'), 'child one two');
});

it('runs "does" on event target itself: /grey', function (assert) {

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

  var event = iii.run([
    'div.the_box div.grey', 'allows', [ 'mousedown' ],
    '/grey', 'does', [ 'add class', ['three']   ],
    '/grey', 'does', [ 'add class', ['four']    ]
  ]); // ======================

  $('#event div.the_box div.grey').trigger('mousedown');
  assert.equal($('#event div.the_box div.grey').attr('class'), 'grey three four');
});

it('accepts path with /event_name/target/selector', function (assert) {

  $('#event').html(
    '\
      <div class="the_box">              \
        <div class="grey one"></div>     \
        <div class="grey two"></div>     \
      </div>                             \
    '
  );

  var event = iii.run([
    'div.the_box div.grey', 'allows', [ 'mousedown' ],
    '/mousedown/div.grey:first/div.the_box', 'does', [ 'add class', ['one']  ],
    '/mousedown/div.grey:last/div.the_box', 'does', [ 'add class', ['two']  ]
  ]); // ======================

  $('#event div.the_box div.grey.one').trigger('mousedown');
  assert.equal($('#event div.the_box').attr('class'), 'the_box one');

  $('#event div.the_box div.grey.two').trigger('mousedown');
  assert.equal($('#event div.the_box').attr('class'), 'the_box one two');
});

// ==================================================================
describe('forms');
// ==================================================================

it('throws error if url contains invalid char: :', function (assert) {
  $('#form_1').attr('action', 'javascrip://alert');
  assert.throws(function () {
    $('#form_1 button.submit').trigger('click');
  }, /Invalid chars in form action url: :/);
});

it('throws error if url contains invalid char: &', function (assert) {
  $('#form_1').attr('action', 'javascript&amp//alert');
  assert.throws(function () {
    $('#form_1 button.submit').trigger('click');
  }, /Invalid chars in form action url: &/);
});

it('throws error if url contains invalid char: ;', function (assert) {
  $('#form_1').attr('action', 'http;amp//alert');
  assert.throws(function () {
    $('#form_1 button.submit').trigger('click');
  }, /Invalid chars in form action url: ;/);
});


QUnit.asyncTest('submits form values', function (assert) {
  expect(1);

  $('#form_1').attr('action', '/repeat/vals');

  var env = iii.run([
    '/success/#form_1', 'does', [
      'log', ['get', ['data']]
    ]
  ]);

  var has_class = function () {
    return $('#form_1').hasClass('complete');
  }; // function

  var run_tests = function () {
    assert.deepEqual(_.last(env.log), {val_1: '1', val_2: '2', val_3: '3'});
    QUnit.start();
  }; // function

  $('#form_1 button.submit').trigger('click');
  do_this(run_tests).when(has_class);
});


QUnit.asyncTest('displays success msg', function (assert) {
  expect(1);
  $('#form_1').attr('action', '/repeat/success_msg');
  var env = iii.run([]);


  var has_class = function () {
    return $('#form_1').hasClass('complete');
  }; // function

  var run_tests = function () {
    assert.equal($('#form_1 div.status_msg.success_msg').text() , 'The success msg.');
    QUnit.start();
  }; // function

  $('#form_1 button.submit').trigger('click');
  do_this(run_tests).when(has_class);
});


QUnit.asyncTest('displays error msg', function (assert) {
  expect(1);
  $('#form_1').attr('action', '/repeat/error_msg');
  var env = iii.run([]);


  var has_class = function () {
    return $('#form_1').hasClass('complete');
  }; // function

  var run_tests = function () {
    assert.equal($('#form_1 div.status_msg.error_msg').text() , 'The error msg.');
    QUnit.start();
  }; // function

  $('#form_1 button.submit').trigger('click');
  do_this(run_tests).when(has_class);
});


// ==================================================================
describe("looping getting/inserting of partials");
// ==================================================================

QUnit.asyncTest('inserts status on top of parent', function (assert) {
  expect(1);

  $('#event').html(
    '\
      <div class="the_box">                                                    \
        <div data-refresh="items top fastest /repeat/item"></div>              \
      </div>                                                                   \
    '
  );

  var loop = iii.run([]);

  var items_status = function () {
    return $('div.the_box div.items_status');
  };

  var has_dom = function () {
    return items_status()().length > 0;
  };

  var the_test = function () {
    assert.equal(items_status().html(), 'More items available. <a href="#show">Show them.</a>');
    QUnit.start();
  };

  do_this(the_test).when(has_dom);

}); // === asyncTest

QUnit.asyncTest('removes status element after showing them', function (assert) {
  expect(1);

  $('#event').html(
    '\
      <div class="the_box">                                                    \
        <div data-refresh="items top fastest /repeat/item"></div>              \
      </div>                                                                   \
    '
  );

  var loop = iii.run([]);

  var items_status = function () {
    return $('div.the_box div.items_status');
  };

  var has_dom = function () {
    return items_status()().length > 0;
  };

  var the_test = function () {
    items_status().find('a').trigger('click');
    assert.equal(items_status().length, 0);
    QUnit.start();
  };

  do_this(the_test).when(has_dom);

}); // === asyncTest






