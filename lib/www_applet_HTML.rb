
require "nokogiri"
require "www_applet"
require "www_applet/Clean"


module HTML

  class << self

    def unindent s
      s.gsub(/^#{s.scan(/^\s*/).min_by{|l|l.length}}/, "")
    end

    def page
      @page ||= unindent <<-EOHTML
        <!DOCTYPE html>
        <html lang="en">
          <head>
            <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
            <title>[No Title]</title>
            <style type="text/css">
            </style>
          </head>
          <body>
          </body>
        </html>
      EOHTML
    end # === new_page

    def styles
      @styles ||= {
        :bg_color        => ["background-color"     , :color],
        :bg_image_url    => ["background-image-url" , :url],
        :bg_image_repeat => [
          "background-repeat",
          :downcase,
          :in, [
            "repeat-all",
            "repeat-x",
            "repeat-y",
            "none"
          ]
        ],
        :font            => ["font-family"          , :all, :fonts],
        :text_color      => ["color"                , :color],
        :text_size       => [
          "font-size",
          :upcase,
          :in, %w{SMALL LARGE MEDIUM X-LARGE}
        ],
      }
    end

    def propertys
      @propertys ||= {
        :id              => ["id", :dom_id],
        :title           => ["title", :string, :size_bewtween, [1, 200]],
        :note            => ["span", :not_empty_string],
        :max_chars       => ["max-chars", :number_between, [1, 10_000]]
      }
    end

    def elements
      @elements ||= {
        :p                   => ["p", :strip, :not_empty_string],
        :box                 => ["div", {"class"=>"box"}],
        :form                => ['form'],
        :one_line_text_input => ['input', {"type"=>'text'}],
        :password            => ['input', {"type"=>'password'}],
        :button              => ['button']
      }
    end

  end # === class self ===================================================

  def styles sender, to, args
    rule_name = sender.grab_stack_tail(1, "a name for the style")
    the_styles[rule_name] ||= {}
    args.each { |o|
      case
      when is_style_value?(o)
        the_styles[rule_name][o["NAME"]] = o["VALUE"]
      when is_style_class?(o)
        the_styles["#{rule_name}:#{o["NAME"]}"] = o["VALUE"]
      end
    }
    rule_name
  end

  styles.each { |name, props|
    eval %^
      def #{name} sender, to, args

        meta     = HTML.styles[:#{name}].dup
        css_name = meta.shift
        raw      = if meta.include?(:all) 
                   meta.shift
                   args
                 else
                   args.last
                 end

        clean = WWW_Applet::Clean.new(to, raw).clean_as(*meta).actual

        {"IS"=>["STYLE VALUE"], "NAME"=>css_name, "VALUE"=>clean}

      end
    ^
  }

  elements.each { |name, props|
    eval %^
      def #{name} sender, to, args

        {"IS"=>["ELEMENT VALUE"], "NAME"=>:#{name}, "VALUE"=>args}
      end
    ^
  }

  def id sender, to, args
    val = WWW_Applet::Clean.new( to, standard_key(args.last)).
      string.
      not_empty_string.
      max_length(100).
      match(/\A[a-z0-9\_\-\ ]{1,100}\Z/i , "id has invalid chars").
      actual

    {"IS"=>["ATTRIBUTE VALUE"], "NAME"=>standard_key(to), "VALUE"=>val}
  end

  def title sender, to, args
    val = WWW_Applet::Clean.new( to, args.last.to_s.strip ).
      not_empty_string.
      actual
    {"IS"=>["ATTRIBUTE VALUE"], "NAME"=>standard_key(to), "VALUE"=>val}
  end

  def note sender, to, args
    return "note"
    val = WWW_Applet::Clean.new( to, args.last.to_s.strip ).
      not_empty_string.
      actual
    {"IS"=>["ATTRIBUTE VALUE"], "NAME"=>standard_key(to), "VALUE"=>val}
  end

  def max_chars sender, to, args
    val = WWW_Applet::Clean.new(to, args.last).
      number_between(1, 200).
      actual
    {"IS"=>["ATTRIBUTE VALUE"], "NAME"=>standard_key(to), "VALUE"=>val}
  end


  # ===================================================
  #                    Events
  # ===================================================

  def on_click sender, to, args
    {"IS"=>["ATTRIBUTE VALUE"], "NAME"=>standard_key(to), "VALUE"=>args.last}
  end

  def on_hover sender, to, args
    vals = args.select { |o| is_style_value?(o) }.inject({}) do |memo, s|
      memo[s["NAME"]] = s["VALUE"]
      memo
    end

    {"IS"=>["STYLE CLASS"], "NAME"=>standard_key(to).sub("ON ", '').downcase, "VALUE"=>vals}
  end

  # ===================================================
  #                    Actions
  # ===================================================

  def submit_form sender, to, args
    {"IS"=>["PROPERTY"], "NAME"=>standard_key(to), "VALUE"=>args.last}
  end

  def to_html
    the_doc.at("html head style").content = the_styles.inject("") { |memo, (k, v)|
      memo << "
       #{k} {
         #{v.to_a.map { |pair| "#{pair.first}: #{pair.last.is_a?(Array) ? pair.last.join(', ') : pair.last};" }.join "
         " }
       }
    "
      memo
    }

    stack.each { |o|
      next unless is_element_value?(o)
      the_body.add_child new_element(o)
    }

    the_doc.to_xhtml
  end


  private # ==========================================

  def the_doc
    @the_doc ||= Nokogiri::HTML HTML.page
  end

  def the_body
    @the_body ||= the_doc.at('body')
  end

  def new_element raw
    meta = HTML.elements[raw["NAME"]].dup
    tag = meta.shift.split.first
    attrs = meta.first.is_a?(Hash) ? meta.shift : nil
    e = Nokogiri::XML::Node.new(tag, the_doc)

    content = raw["VALUE"].last
    if content && content.is_a?(String)
      e.content = content
    end

    if attrs
      attrs.each { |k,v|
        e[k] = v
      }
    end

    raw["VALUE"].each { |o|
      case
      when is_element_value?(o)
        e.add_child new_element(o)
      when is_attribute_value?(o)
        e[o["NAME"].downcase] = o["VALUE"]
      end
    }

    e
  end

  def the_styles
    @the_stles ||= {}
  end


  def is_applet_object? o
    o.is_a?(Hash) && o["IS"].is_a?(Array)
  end

  def is_style_value? o
    is_applet_object?(o) && o["IS"].include?("STYLE VALUE")
  end

  def is_element_value? o
    is_applet_object?(o) && o["IS"].include?("ELEMENT VALUE")
  end

  def is_sub_style_class? o
    is_applet_object?(o) && o["IS"].include?("SUB STYLE CLASS")
  end

  def is_style_class? o
    is_applet_object?(o) && o["IS"].include?("STYLE CLASS")
  end

  def is_attribute_value? o
    is_applet_object?(o) && o["IS"].include?("ATTRIBUTE VALUE")
  end

end # === module HTML








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

      "one line text input", [
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
      "one line text input", [ "max chars", [30], "title", ["Screen Name:"]],
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
# =======================
#     end json
# =======================

d = WWW_Applet.new "__MAIN__", json
d.extend_applet HTML
d.run
puts d.to_html

if ARGV.first == "print"
  File.open "/tmp/n.html", "w+" do |io|
    io.write d.to_html
  end
end



