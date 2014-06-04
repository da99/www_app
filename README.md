
WWW\_Applet:
------------

Using a few simple rules, you can describe a mini-app (ie applet) as JSON.

Currently, this has a Ruby and browser (ie JavaScript) version.

Disclaimer:
------------

This is not done yet. So please don't use it.
Actually, it does work, but I am too lazy to right decent documentation.

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









