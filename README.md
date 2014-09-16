

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

  > the symmetry of consuming/producing media.

Security:
-----------

1) All data from user should be run through `:render` to
ensure sanitization/escaping.

2) `:inner_html/:inner_text` -- only uses content from the server
after it has been sanitized/escaped.

3) No client-side sanitization/escaping. Too many bugs and security issues
because of browser incompability/implementations. Content
to be used in client-size JS can only come from the server using "lockboxed vars".

Ruby:
--------------

To install:

```ruby
  gem install www_applet
```

To Use:

```ruby
    div {

      border '1px solid #fff'

      on(:click) {
        add_class 'clicked'
      }

     'hello'

    }
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




