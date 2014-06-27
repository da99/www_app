
WARNING:
------------

To be completed on July 6, 2019.

Ideas to remember, in this order:

  1. the majority of software for the Majority of Humans requires
  customization and settings/options: in other words, configuration
  rather than creating an app. Science and Nintendo-style
  video games require more "power", (ie a programming language).

  2. most of the action in WWW\_Applets is:
  describing things you are doing to the
  stacks... and things you are doing to the 
  values on the stack.

  3. universal problem solving: break up the problems
  into re-usable components by complexing the problem
  and comparing it to similar and different problems.

  4. DSLs/POLs, even if they are a subset of a prog. lang.,
  are stil their own culture/env./prog. lang. Just like
  with anything else, people do not want to learn something
  new unless they see LOTS of other people/companies using it,
  or if it is being talked about a lot (eg XML, Java, etc.).

  5. It doesn't matter if you can play well with others,
  because no one wants to play with you. Hence, the lack of
  good "virtual machine"-based architecture and sandboxing in
  browsers.  Hence, the lack of demand for programming languages
  written using nothing but JSON.

  6. The most important and the most easily mis-understood
  and overlooked: 

    > It's not about solving problems.
    > It's about finding "better" requirements.
    >
    > Micro-optimizing engineers vs. macro-optimizing architects.
    >
    > Hence, "better" is interpreted differently by most people
    > because they want to be engineers, not architects.
    >
    > Most scientists are engineers, not architects. Therefore,
    > most scientists are not scientists.
    >
    > Hence, Austrian economics and Elec. Uni. Theory
    > is ignored. They are architectures, rather than a bag
    > of tricks for engineers to use (eg Neo-Keynsian economists).

I originally wanted this to be an abstraction layer over
HTML, JS, CSS. However, during the development of "www\_applet",
I realized I could do that w/ just Ruby
(hence the creation of www\_script). In other words,
I would not need a sophisticated runtime in the browser.
Most of the work would be on the server (to generate the HTML, CSS)
and the JS would mainly consist of calling functions in the browser
from my own api/libs.

The need for www\_applet was pushed forward, also, because
most people do not need a common way to exchange code in programming
languages. Instead, their needs are configuration,
rather than a programming language or DSL/POL.
This is more higher level than HyperCard:

  > Configure rather than create.

Also, I realized www\_applet can become it's own programming
language with the power to replace PHP. It sounds crazy, but
no more crazy than the popularity of garbage like PHP and Wordpress.
It would only require an extra 2 weeks, but this is still too much
time that I can not afford because I am going broke.
WWW\_Applet:
---------

Using a few simple rules, you can describe a mini-app (ie applet) as JSON.

Currently, this has a Ruby and browser (ie JavaScript) version.

It is inspired from the Factor programming language
and Alan Kay's annnual "pep talk" (ie VMs, sandboxing,
SNMOP: scalable network/message oriented programming)

One benefit is to let the user
be the programmer w/o sacrificing security.
It's an old idea from the pre-1990s:

  the symmetry of consuming/producing media.

Ruby:
--------------

To install:

```ruby
  gem install www_applet
```

To Use:

```ruby
  require "www_applet"

  json = [
    "one", "is", [1],
    "two", "is", [2],
    "three", "is a computer", [
      3
    ],
    "print", [
      "get", ["one"],
      "get", ["two"],
      "three", []
    ]
  ]

  o = WWW_Applet.new json
  # --or--
  o = WWW_Applet.new MultiJson.dump(json)

  o.run

  puts o.console.inspect
```


JavaScript/browser:
-----------------

*Note:* Not done yet.

Rules:
-------

1. Allowed: Strings, numbers, Arrays, and functions.
2. Function calls: a string, followed by an Array:

```javascript
  [ "my func", [1,2,3] ]
```

3. Writing a function: A function gets passed 3 variables:

  1. the runtime as an Object/instance.
  2. the name of the function as a String.
  3. the arguments as an Array.

```ruby
  lambda { |sender, name_of_computer, evaled_args|
  }
```

Fun fact:
-----

[JSON\ Applet](http://github.com/da99/json_applet) was changed to WWW\_Applet.









