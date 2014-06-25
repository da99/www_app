

require "differ"

def norm ugly
  ugly.split("\n").map { |s|
    strip = s.strip
    if strip.index("<") == 0
      strip
    else
      s
    end
  }.join("\n")
end

def to_doc o
  tmpl = %^<!DOCTYPE html><html lang="en"><head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title>$TITLE</title>
    <style type="text/css">$STYLE</style>
  </head>
  <body>$BODY</body></html>^
  vals = case o
         when String
           {:title=>'[No Title]', :body=>o}
         when Hash
           {:title=>'[No Title]'}.merge o
         else
           fail "Unknown type: #{o.inspect}"
         end
  tmpl.gsub(/\$([^\ <]+)/) { |sub|
    vals[$1.downcase.to_sym] || ''
  }
end

def input json
  d = WWW_Applet.new("__MAIN__", json)
  d.run
  norm d.to_html
end

def should_eq raw_actual, raw_target
  actual = norm raw_actual
  target = norm raw_target

  if actual != target
    Differ.format = :color
    puts ""
    puts "========  ACTUAL:  =================="
    puts actual
    puts "========  TARGET:  =================="
    puts target
    puts "========== DIFF: ===================="
    puts Differ.diff_by_word(actual, target).to_s
    puts "====================================="
    puts ""
    fail "NOT EQUAL"
  end
  actual.should == target
end

describe "HTML" do

  it "escapes chars in 'href' attributes" do
    actual = input [
      "a", [
        "href", ["& & &"],
        "home"
      ]
    ]

    target = to_doc %^<a href="&amp;%20&amp;%20&amp;">home</a>^

    should_eq actual, target
  end

  it "can set the page title" do
    actual = input [
      "title", ["Hello"]
    ]
    target = to_doc :title=>"Hello"
    should_eq actual, target
  end

end # === describe HTML ===



__END__

json = [

  # ====================================
  #           The Main Computer
  # ====================================

  "bg color"         , [ "#ffc"          ],
  "bg image url"     , [ "THE_IMAGE_URL" ],
  "bg image repeat"  , [ "repeat-all"    ],
  "title"            , [ "megaUNI"       ],

  # ====================================
  #               STYLES
  # ====================================

  "link", "styles", [
    "text color"    , ["#ddd"],
    "on hover" , [
      "text color" , ["#fff"],
      "bg color"   , ["#ddd"]
    ]
  ],

  "box title", "styles", [
    "text size" , ["small"],
    "font"      , ["sans-serif", "italic"]
  ],

  "form field title", "styles", [
    "text color" , ["#fff"],
    "text size"  , ["medium"],
    "font"       , ["sans-serif"]
  ],

  "form field note",   "styles", [
    "text color", ["#ccc"]
  ],

  "form button", "styles", [
    "text size", ["small"]
  ],

  # ====================================
  #             Content
  # ====================================

  "box", [
    "id" , [ "intro" ],
    "p"  , [ "Multi-Life Chat & Publishing." ],
    "p"  , [ "Coming later this year."       ]
  ],

  "box", [
    "title"   , [ "Log-in" ],
    "form", [

      "one line text box", [
        "max chars" , [ 30 ],
        "title", ["Screen Name:"]
      ],

      "password", [
        "max chars" , [ 200 ],
        "title"     , [ "Password:" ],
        "note"      , [ "(spaces are allowed)" ]
      ],

      "button", [
        "title" , [ "Log-In" ],
        "on click" , [ "submit form", [] ]
      ]
    ] # === form
  ], # === box

  "box", [
    "title" ,  [ "Create a new account" ],
    "form", [
      "one line text box", [ "max chars", [30], "title", ["Screen Name:"]],
      "password", [
        "max chars" , [ 200 ],
        "title"      , ["Password"],
        "note"      , ["(for better security, use spaces and words):"]
      ],
      "password", [
        "max chars", [200],
        "title", ["Re-type the password:"]
      ],
      "button", [
        "title", ["Create Account"],
        "on click", ["submit form", []]
      ]

    ] # form
  ], # box

  "box", [
    "id", ["footer"],
    "p", ["(c) 2012-2014. megauni.com. Some rights reserved."],
    "p", ["All other copyrights belong to their respective owners."]
  ]

]

