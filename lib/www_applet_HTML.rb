


module HTML
end # === module HTML

module JavaScript
end # === module JavaScrip

module Styles

  class << self

    def raw_args
      @raw_args ||= []
    end

  end # === class self

  def styles sender, to, args
    rule_name = sender.grab_stack_tail(1, "a name for the style")
    new_style_class(
      rule_name,
      args.select { |o| is_a_style?(o) }
    )
  end

  # ===================================================
  #                 Properties
  # ===================================================

  def font sender, to, args
    val = args.map { |o|
      require_arg(
        "font",
        o,
        [:string, "can only be a string"],
        [:not_empty_string, "can't be an empty string"],
        [:matches, /\A[a-z0-9\-\_\ ]{1,100}\Z/i, "only allow 1-100 characters: letters, numbers, spaces, - _"]
      )
    }.join ", "
    new_style to, val
  end

  def bg_color sender, to, args
    val = require_arg(
      "bg color",
      args.last,
      [:string, "must be a string"],
      [:not_empty_string, "can't be an empty string"],
      [:matches, /\A[a-z0-9\#]{1,25}\Z/i, "only allow 1-25 characters: letters, numbers and #"],
      :upcase
    )
    new_style to, val
  end

  def text_color sender, to, args
    val = require_arg(
      "text color",
      args.last,
      [:string, "must be a string"],
      [:not_empty_string, "can't be an empty string"],
      [:matches, /\A[a-z0-9\#]{1,25}\Z/i, "allow 1-25 characters: letters, numbers and #"],
      :upcase
    )
    new_style to, val
  end

  def text_size sender, to, args
    val = require_arg(
      "text size",
      args.last,
      [:string, "must be a string"],
      [:not_empty_string, "can't be an empty string"],
      :upcase,
      [:included, %w{SMALL MEDIUM LARGE X-LARGE}, "can only be: small, medium, large, x-large"]
    )

    new_style to, val
  end

  def bg_image_url sender, to, args
    val = require_arg(
      to,
      args.last,
      [:string, "must be a string"],
      [:not_empty_string, "can't be an empty string"],
      [:max_length, 200, "url needs to be 200 or less chars."],
      [:matches, /\A[a-z0-9\_\-\:\/\?\&\(\)\@\.]{1,200}\Z/i , "url has invalid chars"]
    )
    new_style to, val
  end

  def bg_image_repeat sender, to, args
    opts = ["BOTH", "ACROSS", "UP/DOWN", "NO"]
    val = require_arg(
      to,
      standard_key(args.last),
      [:string, "must be a string"],
      [:not_empty_string, "can't be an empty string"],
      [:included, opts, "can only be one of these: #{opts.join ', '}"]
    )
    new_style to, val
  end

  def id sender, to, args
    val = require_arg(
      to,
      standard_key(args.last),
      [:string, "must be a string"],
      [:not_empty_string, "can't be an empty string"],
      [:max_length, 100, "url needs to be 100 or less chars."],
      [:matches, /\A[a-z0-9\_\-\ ]{1,100}\Z/i , "id has invalid chars"]
    )
    new_style to, val
  end

  def title sender, to, args
    val = require_arg(
      to, args.last.to_s.strip,
      [:not_empty_string, "can't be empty."]
    )
    new_style to, val
  end

  def notice sender, to, args
    val = require_arg(
      to, args.last.to_s.strip,
      [:not_empty_string, "can't be empty."]
    )
    new_style to, val
  end

  def max_chars sender, to, args
    val = require_arg(to, args.last, :number, [:max, 200], [:min, 1])
    new_style to, val
  end


  # ===================================================
  #                    Events
  # ===================================================

  def on_click sender, to, args
    new_style to, args.last
  end

  def on_hover sender, to, args
    vals = args.select { |o| is_a_style?(o) }
    new_style to, vals
  end

  # ===================================================
  #                    Actions
  # ===================================================

  def submit_form sender, to, args
    new_style to, args.last
  end

  # ===================================================
  #                    Elements
  # ===================================================

  def p sender, to, args
    val = require_arg(
      to, args.last.to_s.strip,
      [:not_empty_string, "can't be empty."]
    )
    new_element sender, to, [val]
  end

  %w{ p box button form one_line_text_input password }.each { |name|
    eval %^
      def #{name} *args
        new_element *args
      end
    ^
  }

  private # ==========================================

  def new_style_class rule_name, styles
    {"IS"=>["STYLE CLASS"], "NAME"=>standard_key(rule_name), "VALUE"=>styles}
  end

  def new_style name, val
    {"IS"=>["STYLE"], "NAME"=>standard_key(name), "VALUE"=>val}
  end

  def new_element sender, to, args
    e = {
      "IS"    => ["ELEMENT"],
      "NAME"  => standard_key(to),
      "VALUE" => args.select { |o| is_stylish?(o) }
    }
  end

  def is_a_style? o
    o.is_a?(Hash) && o["IS"].is_a?(Array) && o["IS"].include?("STYLE")
  end

  def is_a_element? o
    o.is_a?(Hash) && o["IS"].is_a?(Array) && o["IS"].include?("ELEMENT")
  end

  def is_a_style_class? o
    o.is_a?(Hash) && o["IS"].is_a?(Array) && o["IS"].include?("STYLE CLASS")
  end

  def is_stylish? o
    is_a_style?(o) || is_a_element?(o) || is_a_style_class?(o)
  end

  def require_arg name, raw, *args
    val = raw
    args.each { |o|
      val = case

            when o == :font
            when o == :color
            when o == :text_size
            when o == :url
            when o == :in_array
            when o == :dom_id
            when o == :not_empty_string
            when o == :max_chars

            when o == :upcase
              fail "Invalid: #{name} must be a string: #{val.inspect}" unless val.is_a?(String)
              val.upcase
            when o == :number
              fail "Invalid: #{name} must be a number: #{val.inspect}" unless val.is_a?(Numeric)
              val
            when o.is_a?(Array)
              cmd = o.first
              msg = "Invalid: #{o.last}: #{val.inspect}"
              case cmd
              when :string
                fail msg if !val.is_a?(String)
              when :not_empty_string
                fail "Invalid: #{name} must be a string: #{val.inspect}" unless val.is_a?(String)
                fail msg if val.empty?
              when :included
                fail msg unless o[1].include?(val)
              when :max_length
                fail "Invalid: #{name} must be a string: #{val.inspect}" unless val.is_a?(String)
                fail msg unless val.length <= 200
              when :max
                fail "Invalid: #{name} must be #{o[1]} or less" unless val <= o[1]
              when :min
                fail "Invalid: #{name} must be #{o[1]} or more" unless val >= o[1]
              when :matches
                regex = o[1]
                fail msg unless regex =~ val
              else
                fail "Invalid: unknown option: #{name.inspect} #{val.inspect} #{args.inspect}"
              end

              val
            else
              fail "Invalid: unknown option: #{o.inspect}"
            end
    }
    val
  end

end # === module Styles

module HTML

  def organize_the_styles o
    meta = {
      "META"          => {},
      "STYLE CLASSES" => {},
      "TEXT"          => nil,
      "ELEMENTS"      => [],
    }

    if o.last.is_a? String
      meta["TEXT"] = o.last
    end

    o.each { |v|
      case

      when is_a_style?(v)
        meta["META"][v["NAME"]] = v["VALUE"]

      when is_a_style_class?(v)
        meta["STYLE CLASSES"][v["NAME"]] ||= {}
        target = meta["STYLE CLASSES"][v["NAME"]]
        v["VALUE"].each { |rule|
          target[rule["NAME"]] = rule["VALUE"]
        }

      when is_a_element?(v)
        meta["ELEMENTS"].push v

      end # case
    }

    meta
  end

  def validate_css_color name, raw
    v = raw.strip.upcase
    if !(v =~ /\A#[A-Z0-9]{3,10}\Z/)
      fail "Invalid: color for #{name.inspect}: #{raw.inspect}"
    end
    v
  end

  def validate_text_size name, raw
    v = raw.strip.upcase
    case v
    when 'SMALL'
    when 'LARGE'
    when 'MEDIUM'
    when 'X-LARGE'
    else
      fail "Invalid: #{name.inspect}: #{raw.inspect}"
    end
    v
  end

  def validate_font name, raw
    v = raw.strip
    if !(v =~ /\A[a-z0-9\-\_\ \'\,]{1,100}\Z/i)
      fail "Invalid: #{name.inspect}: #{raw.inspect}"
    end
    v
  end

  def to_css_name k, v
    case k
    when "TEXT SIZE"
      ["font-size", validate_text_size(k, v)]

    when "TEXT COLOR"
      ["color", validate_css_color(k, v)]

    when "FONT"
      ["font-family", validate_font(k, v)]

    when "BG COLOR"
      ["background-color", validate_css_color(k, v)]

    when "BG IMAGE URL"
      ["background-image", "url(#{v})"]

    when 'BG IMAGE REPEAT'
      val = case v
             when "BOTH"
               "repeat"
             when "ACROSS"
               "repeat-x"
             when "UP/DOWN"
               "repeat-y"
             when "NO"
               "no-repeat"
             else
               fail "Invalid: unknown repeat: #{v.inspect}"
             end
      ["background-repeat", "#{val}"]

    when "TITLE"
      nil

    else
      fail "Invalid: unknown css property: #{k.inspect}: #{v.inspect}"

    end
  end

  def to_css scope, styles
    arr = []
    styles.each { |k,v|
      case k
      when "ON HOVER"
        new_scope = "#{scope}:hover"
        org = organize_the_styles(v)
        to_css(new_scope, org["META"])
      else
        name, val = to_css_name(k, v)
        the_nodes["STYLE CLASSES"][scope][name] = v
      end
    }
  end

  def the_page
    @the_nodes ||= {
      "STYLE CLASSES" => {},
      "ELEMENTS"      => {}
    }
  end

  def to_html
    @the_nodes = nil

    org = organize_the_styles(@stack)
    org["STYLE CLASSES"]["BODY"] = (org["STYLE CLASSES"]["BODY"] || {}).merge(org["META"])

    org["STYLE CLASSES"].keys.each { |name|
      org["STYLE CLASSES"][name] = upsert_style_class name, styles
    }

    puts "============================"
    require "pp"
    # pp org
  end

  def html_doc
    @html_doc ||= begin
                  end
  end
end # --- module

require "www_applet"

json = [

  # ====================================
  #           The Main Computer
  # ====================================

  "bg color"         , [ "#ffc"          ],
  "bg image url"     , [ "THE_IMAGE_URL" ],
  "bg image repeat"  , [ "both"          ],
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

  "form field notice", "styles", [
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
        "notice"    , [ "(spaces are allowed)" ]
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
        "notice"    , ["(for better security, use spaces and words):"]
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
d.extend_applet Styles
d.extend HTML
d.run
puts d.to_html

if ARGV.first == "print"
  File.open "/tmp/n.html", "w+" do |io|
    io.write d.to_html
  end
end



