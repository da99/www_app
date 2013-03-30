
Disclaimer:
-----------

Not ready yet for human consumption.


Install & Use
------------

    npm install json_applet

    var Applet = require('json_applet').Applet;

    Applet({
      form: [
        ["text_box", "my_name", "INPUT YOUR NAME", "one line"]
      ]
    });

    // --> outputs:
    //    {
    //      html: '<form><input type="text" name="my_name">INPUT YOUR NAME</input></form>',
    //      js:   ""
    //     }


The Future
-------------------------

Function calls:

    [
       "remove()" , ["my_form", "my_spouse"]
    ]

Variable declaration:

    [
       "my_pet=", "Captain Snuggles",

       "new_width=",
       "add()", [ 4, "my_form.posX()", "px" ]
    ]

Escaping:

    [
       "my_string=", "!! add()",
    ]

    // ==> equal to my_string = "add()";
    //  the "!! " are ignored, including space after "!!"


History
-------

Formerly called: ok\_slang.
