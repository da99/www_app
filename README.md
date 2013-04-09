

The Standard: What you need to do to implement it on your fav. prog. lang.
-------------------------

1) The starting point is an array:

    [ "form", { ... }, [ ... ] ]

2) Function calls: A string followed by object and/or array.

    [ "a", {href: "http://www.joelonsoftware.com"}, [ "Eat at Joe's." ] ]


3) The obj. ({ k: v }) holds the attributes. The object is optional.

    [ "button", [ "Eat at Joe's." ] ]

4) A string followed by another string is considered a function call w/o
   arguments:

    [
       "my_func_with_no_args",
       "my_func_with_args", [ 1, 2, 3 ],
       "another_func_with_args", {}, [ 1, 2, 3 ]
    ]


Example:
---------

Your app users send you this JSON:

    [
      "form", {action: "http://my_url.something/"}, [
        "input_text", [ "Input your name here." ],
        "button", [ "Save" ],
        "on_click", [ "submit_form" ]
      ]
    ]

You then process the above into HTML/JS... using Ruby, Python, [Factor](http://factorcode.org/), etc.

The Future Standard
-------------------

1) There are no plans for variables or methods because JSON applet because
there are closer in pedigree to SQL/DSLs/POLs than to a full scripting/prog. lang.


What can you do with WWW applets?
-------------------------------

Do you want to allow others to script your apps?
Do you want to turn those scripts into little applets of HTML/JS?
Do you wnat them to be sandboxed?
Do you want to allow others to script your apps? In other words: turn your apps into a
platform the quick & easy way?
Do you want them sandboxed?
Do you want to create a simple to use declarative language and pass it around
using JSON?
Do you *not* need CSS in your applets right now?

Then try WWW applets.



Alternatives:
-------------

* [Adsafe](http://www.adsafe.org/)

The End... of the standard.
----------------------------------

From this point onward in this document, I will be talking about the
nodejs/npm implementation that has nothing to do with your own
implementation of the standard.


\* \* \*
--------------------------------

The nodejs/npm implementation:
------------------------------

    npm install json_applet (Currently, it's not on the npm yet.)

    var Applet = require('json_applet').Applet;
    var source = [
      "form", ["my_form"], [
        "input_text", [ "my_name", {lines: 1} ], [
          "Input your name here."
        ],
        "button", [], [ "Save" ],
        "on_click", [ "submit_form" ]
      ]
    ];

    var results = Applet.new(source).run().results;
    results.html;
    results.js;

If there are any errors, they are returned from `.run` as:

    { error: new Error("the msg") }


Events
------

If you want to process your results after calling `.run()`, just add different
callbacks using `.after_run()`

    My_Applet.after_run(function (app) {
      var results = app.results;
      // do something...
      app.results = my_new_results;
    });

    My_Applet.after_run(function (app) {
      // do something...
      app.results = my_other_new_results;
    });

Now, when you call `.run()`, the results are run through the callbacks
you defined in `.after_run`:

    My_Applet.run().results; // results are processed through the callbacks.

There are no more "events" other than `after_run`.

History
-------

Formerly called: ok\_slang.

Originally, there was going to be [json\_applet](https://github.com/da99/json_applet)
for DSL creation, and `www_applet`
would be built on top of `json_applet`. However, I merged the two since I thought it
out as to why json/www applets were not created before: few programmers want others
to script on top of their apps. Which explains why
[greasemonkey](http://en.wikipedia.org/wiki/Greasemonkey)
scripts (in Firefox) continue to be used. Site/web app owners could just add in scripting
to their web apps, but there is not enough demand and business justification. In
other words: programmers do not want to be industrial designers.


A better way:
------------

You have a client (PC, virtual machine, tablet, etc.). You want to
script it using Haskell, but the machine only partys with JavaScript.
How do you solve it?
Make the problem more complicated... What if you have 1 billion people who all use
1 million different languages... and they all want to run code on the machine...

`The Alan Kay Way`: Let the client run
binary code using a sandbox. Then, collect the output
and present the result to the USER or to another process/VM.

The sandbox can decide how much CPU/RAM/etc the binary code can have, how much
access to the screen/speakers/etc it gets, etc.

This way, you can run almost any past/present/future language on the client securely.
This is of course too
radical and not common (despite being Oper. Sys 101).
(And no... JS
ByteArray/ASM.js is not the answer. It's better than nothing, but not what AK was thinking
about.)

For more on Alan Kay, go to youtube and vimeo. His 30+ min lectures are heavenly.



The End
-------

... for now.









