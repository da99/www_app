
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
  my_json = MultiJson.dump [1, 2, "three", []]
  o = WWW_Applet.new my_json

  o.write_function "three", lambda { |runtime, name, args|
    runtime.stack.concat [3,3,3]
    :ignore_return
  }

  o.run
  puts o.stack.inspect
```


JavaScript/browser:
-----------------

*Note:* Not done yet.

Rules:
-------

1. Strings, numbers, and functions.
2. Function calls: a string, followed by an Array:

```javascript
  [ "my func", [1,2,3] ]
```

3. Writing a function: A function gets passed 3 variables:

  1. the runtime as an Object/instance.
  2. the name of the function as a String.
  3. the arguments as an Array.

```ruby
  lambda { |runtime, name, args|
  }
```

4. Returning from a function: The last value is put on the stack.
   However, if the last value is a symbol, that tells the runtime
   to do special things:

     1. `:ignore_return` : Nothing is placed on the stack.
     2. `:cont`          : Run the next function with same name.
     (Similar to method overloading.)
     3.  `:fin`          : Stop everything and do not place anything
     on the stack.

Fun fact:
-----

[JSON\ Applet](http://github.com/da99/json_applet) was changed to WWW\_Applet.









