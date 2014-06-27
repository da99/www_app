
Why was this put on hiatus?
---------------------------


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

    Once the requirements change, you have to re-evaluate
    the design/architecture immediately.

  7. It's hard finding better requirements because of
  familiarity and complexity (quantity and quantity).
  Lazyiness and limited resources help you guide you to
  fulfilling the requirements w/efficiency.

  8. Programmers already have a common runtime:
  HTML, CSS, Javascript, and their preferred server-side
  language. They do not want something easier. They
  want something familiar. Also, "write once, run anywhere"
  is not something programmers want because they want to use
  their own preferred language ...above all else... to generate
  HTMl/CSS/JS. That leaves app-to-app messaging (ie JSON over AJAX).

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
