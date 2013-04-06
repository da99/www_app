

Why should I love WWW applets?
-------------------------------

Do you want to allow others to script your apps?
Do you want to turn those scripts into little applets of HTML/CSS/JS?
Do you wnat them to be sandboxed? Then try WWW applets.

Note:
-----

WWW applets are
[JSON applets](https://github.com/da99/json_applet)
with certain validations.  There is no pre-defined HTML
tags/elements (eg a, form, p, etc.). Those are up to
you to define.

Example:
---------

Your app users send you this JSON:

    [
      "form", ["my_dom_id", "post", "http://my_url.something/"], [
        "text_input", [ "dom_id_2", {lines: 1} ], [
          "Input your name here."
        ],
        "button", [ "Save" ],
        "on_click", [ "submit_form" ]
      ]
    ]

You then process the above into HTML/CSS/JS... using Ruby, Python, [Factor](http://factorcode.org/), etc.

How?

     var Applet = require('www_applet').Applet;
     var app = Applet(my_source);
     app.def('form', my_func);
     app.def_in('form', 'text_input', my_text_input_func);
     ...

Alternatives:
-------------

* [Adsafe](http://www.adsafe.org/)

The Standard
-------------------------

The starting point is an array:

    [ "form", [...], [ ... ] ]

Function calls: A string followed by one array (or object), followed by an array.

    [
       "a", ['http://www.joelonsoftware.com', {title: "Joel Spolsky's home."}], [
         "Eat at Joe's."
       ]
    ]


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

    var results = Applet(source).results;
    results.html;
    results.js;

If there are any errors, they are returned from `.run` as:

    { error: new Error("the msg") }










