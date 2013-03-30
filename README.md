
Disclaimer:
-----------

Not ready yet for human consumption.


Install & Use
------------

    npm install ok_slang

    var Ok = require('ok_slang').Ok;

    Ok({
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
       "remove:" , ["my_form", "my_spouse"]
    ]

Variables:

    [
       "var:" , ["my_pet", "Captain Snuggles"]
    ]

Running code:

    [
        "var:", [
          "new_width",
          "add:", [ 4, "my_form.posX:[]", "px" ]
        ]
    ]
