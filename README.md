
Why should I love JSON applets?
-------------------------------

Do you want to allow others to script your apps? In other words: turn your apps into a
platform the "quick & dirty" way? And... you want them sandboxed? Then try JSON applets. 


Alternatives:
-------------

* [Adsafe](http://www.adsafe.org/)

The Standard
-------------------------

The starting point is an array:

    [ "print", ["hello", "world"] ]

You have to define what "print" does.

Function calls: A string followed by one or more arrays.

    [
       "remove" , ["my_form", "my_spouse"], ["some", "other", "args", [ 1, 2, 3 ]]
    ]

Any string followed by another string is considered a function call without arguments:

    [
       "my_func_with_no_args",
       "my_func_with_args", [ 1, 2, 3 ]
    ]

There are no plans for variables or methods because JSON applet because
there are closer in pedigree to SQL/DSLs/POLs than to a full scripting/prog. lang.

The nodejs/npm implementation:
------------------------------

    npm install json_applet (Currently, it's not on the npm yet.)

    var Applet = require('json_applet').Applet;
    var source = [
      "form", ["my_form"], [
        "text_input", [ "my_name", {lines: 1} ], [
          "Input your name here."
        ],
        "button", [], [ "Save" ],
        "on_click", [ "submit_form" ]
      ]
    ];

    var HTML = Applet(source);

    HTML.def('form', function (this_call) {
      this_call.name   // 'form'
      this_call.prev   // the previous func call and args: [name, array1, array2, ...]
      this_call.curr   // the current func call: ['form', array1, array2]
      this_call.data   // an object you can use to save and pass around data to other
                       //   func calls.
      this_call.app.run(this_call.curr[2]); // compile args as if it were a sub-this_call.
      return "<form> ... </form>";
    });

    HTML.def_in('form', 'text_input', function () {}) // text_input only allowed inside form.
    HTML.def_parent('form', function () {})           // A form can not be inside another form.
    HTML.run(source);                                 // The returns of the ".def" functions.


History
-------

Formerly called: ok\_slang.






