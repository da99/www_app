


The Standard
-------------------------

The starting point is an array, not an object (ie "{}"):

    [ "print", ["hello", "world"]]

Function calls: A string followed by one or more arrays.

    [
       "remove" , ["my_form", "my_spouse"], ["some", "other", "args", [ 1, 2, 3 ]]
    ]

Any string followed by another string is considered a function call without arguments:

    [
       "my_func_with_no_args",
       "my_func_with_args", [ 1, 2, 3 ]
    ]

There are no plans for variables or methods because this is JSON applets are not scripts.
There are closer in pedigree to SQL and DSLs/POLs.

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

    var html = "";

    Applet.def('form', function (applet) {
      applet.prev // the previous func call and args: [name, array1, array2, ...]    
      applet.curr // the current func call: ['form', array1, array2]
      applet.data // an object you can use to save and pass around data to other
                  //   func calls.
      Applet.compile(applet.curr[2]); // compile args as if it were a sub-applet.
      return "whatever you want"; // this is ignored.
    });
    
    Applet.def_in('form', 'text_input', function () {}) // text_input only allowed inside form.
    Applet.def_top('form', function () {})              // A form can not be inside another form.

    Applet.compile(source);


History
-------

Formerly called: ok\_slang.






