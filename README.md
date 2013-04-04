
Why should I love JSON applets?
-------------------------------

Do you want to allow others to script your apps? In other words: turn your apps into a
platform the quick & easy way? And... you want them sandboxed? Then try JSON applets.

Do you want to create a simple to use declarative language and pass it around
using JSON? Then try JSON applets.

Example:
---------

    [
      "form", ["my_form"], [
        "text_input", [ "my_name", {lines: 1} ], [
          "Input your name here."
        ],
        "button", [], [ "Save" ],
        "on_click", [ "submit_form" ]
      ]
    ];


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

    HTML.def('form', function (args_array, call_meta) {
      call_meta.name   // 'form'
      call_meta.prev   // the previous func call and args: [name, array1, array2, ...]
      call_meta.curr   // the current func call: ['form', array1, array2]
      call_meta.data   // an object you can use to save and pass around data to other
                       //   func calls.
      call_meta.app.run(call_meta.curr[2]); // compile args as if it were a sub-call_meta.
      return "<form> ... </form>";
    });

    HTML.def_in('form', 'text_input', function () {}) // text_input only allowed inside form.
    HTML.def_parent('form', function () {})           // A form can not be inside another form.
    HTML.run(source);                                 // The returns of the ".def" functions.


History
-------

Formerly called: ok\_slang.


Genius Time!
------------

You have a client (PC, virtual machine, tablet, etc.) You want to
script it using Forth, but the machine only partys with JavaScript.
How do you solve it?
Make the problem more complicated... What if you have 1 billion people who all use
1 million different languages... and they all want to run code on the machine...

The Alan "Process Science Genius" Kay Way: Let the client run
binary code using a sandbox. Then, collect the output
and present the result to the USER or to another process/VM.

You have to decide how much CPU/RAM/etc. the sandbox is allowed to have, how much
access to the screen/speakers/etc it gets, etc.

This way, you can run almost any past/present/future language on the client. This is of course too
radical and not common. Which is why no one listens to poor Alan Kay.

Ignore Alan Kay at your peril!

For more on Alan Kay, go to youtube and vimeo. His 30+ min lectures are heavenly.













