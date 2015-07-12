
This was an experiment that I have finished (... given up on).
-----------------------
I have decided this is not the right approach to generating HTML + CSS +JS.
Instead, I will be using [Erector](http://erector.github.io/) and [Stylus](http://stylus-lang.com/).

If you still want to use one language for (HTML, CSS, JS) then you should
use [RiotJS](https://muut.com/riotjs/). It's WWW\_App done right... and hugely
must better.

My other alternative:
What I do is "compile" all Erector/Ruby (into HTML) and Stylus (into CSS).
I upload that to the server.
Then I used [Hogan.js](http://twitter.github.io/hogan.js/) on the client-side as
templates with data coming in from AJAX calls.

Thoughts on Ruby for everything:
--------------------------------
1) Using Ruby for CSS is not as easy as writing Stylus or LESS code.
This is a preference. You might fid things differently.

2) Sometimes using a library is better, sometimes it is not.
In this case, Erector is far better than anything I could have written
in terms of usability (as defined by Joel Spolsky in "User Interface Design
    for Programmers").

3) My needs changed: "Pre-compiling" Ruby into HTML on the dev side
lets me not worry about speed and efficiency. In the end, NGINX will
server text/html files, much faster than Ruby or IOjs.

WWW\_App:
---------

Turn Ruby into HTML and CSS.

I was going to put a JS features,
  but I found out that I don't need them
  thanks to [Turu](https://github.com/da99/turu).

Ruby:
--------------

To install:

```ruby
  gem install www_app
```

To Use:

```ruby
WWW_App.new {

  style {
    a._link / a._visited / a._hover { 
      color '#f88'
    }

    a {
      _link / _visited   { color '#fff' }
      _hover { color '#ccc' }
    }

    div.id(:main).__.div.^(:drowsy) / a.^(:excited)._link {
      border '1px dashed grey'
      div.^(:mon) / div.^(:tues) {
        border '1px dashed weekday'
      }
    }

  } # === style

  div.id(:main).^(:css_class_name) {

    border           '1px solid #000'
    background_color 'grey'

    style {
      a._link / a._visited {
        color '#fig'
      }

      _.^(:scary) {
        border           '2px dotted red'
        background_color 'white'
      }
    }

    p { "I'm a paragraph." }

    p {
      text %^
        I'm also
      ^.strip
      br
      text ' a paragraph.'
    }
  }

}.to_html
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

3) [JSON Applet](http://github.com/da99/json_applet) was changed to WWW\_Applet. WWW\_Applet was then changed to WWW\_App.




