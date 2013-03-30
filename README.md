
Disclaimer:
-----------

Not ready yet for human consumption.


Install & Use
------------

    npm install json_applet

    var Applet = require('json_applet').Applet;

    Applet([
      "form ()", ["my_form"], [
        "text_box ()", [ "my_name", {lines: 1} ], [
          "Input your name here."
        ],
        "button ()", [], "Save",
        "on_click ()", [
          "submit_form ()"
        ]
      ]
    ]);

    // --> outputs:
    //    {
    //      html: '<form><input type="text" name="my_name">INPUT YOUR NAME</input></form>',
    //      js:   "
    //        Applet.current('button_1');
    //        Applet.on_click(['submit', 'nearest_form']);"
    //     }


The Future
-------------------------

Function calls:

    [
       "remove ()" , ["my_form", "my_spouse"]
    ]

Function calls w/o parameters: Don't put any array following it.

    [
       "my_func ()" , "my_other_func ()", ["my string", ":my_var"]
    ]

Method calls:

    [
       ":an_obj some_meth ()", [":my_var"]
    ]

Variable declaration:

    [
       ":my_pet =", "Captain Snuggles",

       "new_width =",
       "add ()", [ 4, ":my_form posX ()", "px" ]
    ]

Using variables:

    [
       ":max =", 4
       ":min =", s
       "add:", [ ":max", ":min" ]
       "add:", [ ":max", ":my_var posX ()" ]
    ]


Escaping:

    [
       ":a_string    =", "!! add:",
       ":another_str =", "!! :my_var"
    ]

    //  the "!! " are ignored, including space after "!!"


History
-------

Formerly called: ok\_slang.
