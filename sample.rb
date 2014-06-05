
require "nokogiri"


class String
  def unindent 
    gsub(/^#{scan(/^\s*/).min_by{|l|l.length}}/, "")
  end
end

module HTML

  def title sender, to, args
    content = args.last || "My Page"
    top.html_doc.at_css("html head title").content = content
    content
  end

  def p sender, to, args
    content = args.last || ""
    doc = top.html_doc
    paragraph = Nokogiri::XML::Node.new "p", doc
    paragraph.content = content
    doc.at_css("html body").add_child paragraph
    content
  end

  protected
  def html_doc
    @html_doc ||= begin
                    Nokogiri::HTML <<-EOHTML.unindent
                      <!DOCTYPE html>
                      <html lang="en">
                        <head>
                          <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
                          <title>My Page</title>
                          <style type="text/css">
                          </style>
                        </head>
                        <body></body>
                      </html>
                    EOHTML
                  end
  end
end # --- module

require "www_applet"
class WWW_Applet
  def to_html
    html_doc.to_html
  end
end

json = [

  "link", "style is", [
    "color", ["#ddd"]
    "on hover", [
      "color"    , ["#fff"],
      "bg color" , ["#ddd"]
    ]
  ],

  "box title", "style is", [
    "text size" , ["small"],
    "font"      , ["sans-serif", "italic"]
  ],

  "form field title", "style is", [
    "color"     , ["#fff"],
    "text size" , ["medium"],
    "font"      , ["sans-serif"]
  ],

  "form field notice", "style is", [
    "color", ["#ccc"]
  ],

  "form button", [
    "text size", ["small"]
  ],

  "The page", [
    "bg color"         , [ "#ffc"          ],
    "bg image url"     , [ "THE IMAGE URL" ],
    "bg image pattern" , [ "repeat all"    ],
    "title"            , [ "megaUNI"       ]
  ],

  "box", [
    "id" , [ "intro" ],
    "p"  , [ "Multi-Life Chat & Publishing." ],
    "p"  , [ "Coming later this year."       ]
  ],

  "box", [
    "title"   , [ "Log-in" ],
    "form", [

      "one line text input", [
        "max chars" , [ 30 ],
        "text"      , [ "Screen Name:" ]
      ],

      "password", [
        "max chars" , [ 200 ],
        "text"      , [ "Password:" ],
        "notice"    , [ "(spaces are allowed)" ]
      ],

      "button", [
        "text" , [ "Log-In" ],
        "on click" , [ "submit form", [] ]
      ]
    ] # === form
  ], # === box

  "box", [
    "title" ,  [ "Create a new account" ],
    "form", [
      "one line text input", [ "max chars", [30], "text", ["Screen Name:"]],
      "password", [
        "max chars" , [ 200 ],
        "text"      , ["Password"],
        "notice"    , ["for better security, use spaces and words):"]
      ],
      "password", [
        "max chars", [200],
        "text", ["Re-type the password:"]
      ],
      "button", [
        "text", ["Create Account"],
        "on click", ["submit form", []]
      ]

    ] # form
  ], # box

  "box", [
    "id", "is", ["footer"],
    "p", ["(c) 2012-2014. megauni.com. Some rights reserved."],
    "p", ["All other copyrights belong to their respective owners."]
  ]

] # === end json
d = WWW_Applet.new "__MAIN__", json
d.extend HTML
d.run
puts d.to_html
File.open "/tmp/n.html", "w+" do |io|
  io.write d.to_html
end



