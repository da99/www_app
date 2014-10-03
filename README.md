

WWW\_App:
---------

Create HTML pages using just Ruby: HTML/CSS/JS


Ruby:
--------------

To install:

```ruby
  gem install www_app
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


Security:
-----------

1) Server-side: All data from user should be run through `:render` to
ensure sanitization/escaping.

2) Server-side: All JS meant for :script tags should be escaped before encoded into JSON.

3) Client-side: No untrusted data presented to user: `:inner_html/:inner_text`:
only uses content from the server after it has been sanitized/escaped.

4) Client-side: No client-side sanitization/escaping. Too many bugs and security issues
because of browser incompability/implementations. Content
to be used in client-size JS can only come from the server using "lockboxed vars".

5) Client-side: When using `:inner_html`, check for: `/<script/i` in String.

6) All forms require a CSRF token.


Notes:
-------

1) Blockquotes no longer allow the :cite attribute. Instead use the `cite` tag.
More info at:  [http://html5doctor.com/cite-and-blockquote-reloaded/](http://html5doctor.com/cite-and-blockquote-reloaded/)

2) Originally, this was going to be programs written in 100% JSON. This has changed
because it turns out people do not want to create programs, they just want to customize them:
[https://www.youtube.com/watch?v=9nd9DwCdQR0#t=857](https://www.youtube.com/watch?v=9nd9DwCdQR0#t=857)


Fun fact:
-----

[JSON Applet](http://github.com/da99/json_applet) was changed to WWW\_Applet. WWW\_Applet was then changed to WWW\_App.




