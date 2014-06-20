
require "nokogiri"


module HTML

  class << self

    def unindent s
      s.gsub(/^#{s.scan(/^\s*/).min_by{|l|l.length}}/, "")
    end

    def new_page
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
      @styles ||= begin
                    {
                      :bg_color        => ["background-color"     , :color],
                      :bg_image_url    => ["background-image-url" , :url],
                      :bg_image_repeat => ["background-repeat"    , :upcase, :in, %w{BOTH ACROSS UP/DOWN NO}],

                      :font            => ["font-family"          , :all, :fonts],
                      :text_color      => ["color"                , :color],
                      :text_size       => ["font-size"            , :upcase, :in, %w{SMALL LARGE MEDIUM X-LARGE}],
                    }
                  end
    end

    def propertys
      @propertys ||= begin
                       {
                         :id              => ["id", :dom_id],
                         :title           => ["title", :string, :size_bewtween, [1, 200]],
                         :note            => ["span", :not_empty_string],
                         :max_chars       => [:number_between, [1, 10_000]]
                       }
                     end
    end

  end # === class self ===================================================

  def doc
    @doc ||= Nokogiri::HTML Page::NEW
  end

  def new_element raw
    e = Nokogiri::XML::Node.new(raw[:tag], doc)

    if raw[:content]
      e.content = raw[:content]
    end

    if raw[:childs]
      raw[:childs].each { |raw_child|
        e.add_child new_element(raw_child)
      }
    end

    e
  end

  def styles sender, to, args
    rule_name = sender.grab_stack_tail(1, "a name for the style")
    the_styles[rule_name] ||= {}
    args.each { |o|
      next unless is_a_style?(o)
      the_styles[rule_name][o["NAME"]] = o["VALUE"]
    }
    rule_name
  end

  styles.each { |name, props|
    eval %^
      def #{name} sender, to, args
        clean_as_style :#{name}, to, args
        css_name = HTML.styles[:#{name}].first
        {"IS"=>["STYLE"], "NAME"=>standard_key(css_name), "VALUE"=>actual}
      end
    ^
  }

  private # ===============================================================

  def the_styles
    @the_stles ||= {}
  end

  def clean_as_style name, orig_name, args
    meta     = HTML.styles[name].dup
    meta.shift # css name
    raw      = if meta.include?(:all) 
                 meta.shift
                 args
               else
                 args.last
               end

    actual(orig_name, raw)
    clean_as *meta

    true
  end

  def original_actual
    @original_actual
  end

  def name_of_actual
    return @name_of_actual.inspect unless @name_of_actual[" "]
    @name_of_actual
  end

  def actual *args
    case args.size
    when 2
      @name_of_actual = args.first
      @original_actual = args.last
      actual args.last
    when 1
      @actual = args.first
    when 0
      @actual
    else
      fail "Unknown args: #{args.inspect}"
    end
  end

  def clean_as *args
    if !@name_of_actual
      fail "Name of actual not set."
    end

    begin
      cleaner = args.shift
      if args.first.is_a?(Array)
        send "clean_as_#{cleaner}", *(args.shift)
      else
        send "clean_as_#{cleaner}"
      end
    end while !args.empty?

    true
  end

  def clean_as_not_nil
    if actual.nil?
      fail "Invalid: #{name_of_actual} is required."
    end
    true
  end

  def clean_as_string
    return true if actual.is_a?(String)
    fail "Invalid: #{name_of_actual} must be a String."
  end

  def clean_as_not_empty_string
    clean_as_string
    actual actual.strip
    if actual.empty?
      fail "Invalid: #{name_of_actual} must not be empty."
    end
    true
  end

  def clean_as_upcase
    clean_as_not_empty_string
    actual actual.upcase
    true
  end

  def clean_as_color
    clean_as_not_empty_string
    if !(actual =~ /\A#[A-Z0-9]{3,10}\Z/i)
      fail "Invalid: color for #{name_of_actual}: #{original_actual.inspect}."
    end
    true
  end

  def clean_as_max_length max, msg = nil
    clean_as_not_nil
    if actual.length > 200
      fail(msg || "#{name_of_actual} can not be more than #{max}")
    end
    true
  end

  def clean_as_match regex, msg = nil
    clean_as_string
    if !(actual =~ regex)
      fail(msg || "Invalid: #{name_of_actual} has invalid chars")
    end
    true
  end

  VALID_URL_REGEXP = /\A[a-z0-9\_\-\:\/\?\&\(\)\@\.]{1,200}\Z/i
  def clean_as_url
    max = 200
    clean_as_not_empty_string
    clean_as_max_length max, "#{name_of_actual} needs to be #{max} or less chars."
    clean_as_match VALID_URL_REGEXP
    true
  end

  def clean_as_in *choices
    if !choices.include?(actual)
      fail "Invalid: #{name_of_actual} can't be, #{actual.inspect}, but one of: #{choices.join ", "}"
    end
    true
  end

  def clean_as_map_to cleaner, *args
    vals = actual.dup
    new_vals = []
    actual.each { |v|
      actual v
      send "clean_as_#{cleaner}", *args
      new_vals.push actual
    }
    actual new_vals
    true
  end

  VALID_FONT_REGEXP = /\A[a-z0-9\-\_\ ]{1,100}\Z/i

  def clean_as_fonts
    clean_as_map_to :not_empty_string
    clean_as_map_to :match, VALID_FONT_REGEXP, "only allow 1-100 characters: letters, numbers, spaces, - _"
    true
  end

  def clean_as_number_between min, max
    clean_as_number
    if actual <= min || actual >= max
      fail "Invalid: #{name_of_actual} must be between: #{min} and #{max}"
    end
    true
  end

  public # =================================================================================================

  def id sender, to, args
    val = require_arg(
      to,
      standard_key(args.last),
      [:string, "must be a string"],
      [:not_empty_string, "can't be an empty string"],
      [:max_length, 100, "url needs to be 100 or less chars."],
      [:matches, /\A[a-z0-9\_\-\ ]{1,100}\Z/i , "id has invalid chars"]
    )
    {"IS"=>["PROPERTY"], "NAME"=>standard_key(to), "VALUE"=>val}
  end

  def title sender, to, args
    val = require_arg(
      to, args.last.to_s.strip,
      [:not_empty_string, "can't be empty."]
    )
    {"IS"=>["PROPERTY"], "NAME"=>standard_key(to), "VALUE"=>val}
  end

  def note sender, to, args
    return "note"
    val = require_arg(
      to, args.last.to_s.strip,
      [:not_empty_string, "can't be empty."]
    )
    {"IS"=>["PROPERTY"], "NAME"=>standard_key(to), "VALUE"=>val}
  end

  def max_chars sender, to, args
    return "max_chars"
    val = require_arg(to, args.last, :number, [:max, 200], [:min, 1])
    {"IS"=>["PROPERTY"], "NAME"=>standard_key(to), "VALUE"=>val}
  end


  # ===================================================
  #                    Events
  # ===================================================

  def on_click sender, to, args
    {"IS"=>["PROPERTY"], "NAME"=>standard_key(to), "VALUE"=>args.last}
  end

  def on_hover sender, to, args
    vals = args.select { |o| is_a_style?(o) }
    {"IS"=>["PROPERTY"], "NAME"=>standard_key(to), "VALUE"=>vals}
  end

  # ===================================================
  #                    Actions
  # ===================================================

  def submit_form sender, to, args
    {"IS"=>["PROPERTY"], "NAME"=>standard_key(to), "VALUE"=>args.last}
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

  private 
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

  public

  def the_page
    @the_nodes ||= {
      "STYLE CLASSES" => {},
      "ELEMENTS"      => {}
    }
  end


  def to_html

    return the_styles

    @the_nodes = nil

    org = organize_the_styles(@stack)
    org["STYLE CLASSES"]["BODY"] = (org["STYLE CLASSES"]["BODY"] || {}).merge(org["META"])

    org["STYLE CLASSES"].keys.each { |name|
      org["STYLE CLASSES"][name] = upsert_style_class name, styles
    }

    puts "============================"
    # pp org
  end

  def html_doc
    @html_doc ||= begin
                  end
  end

end # === module HTML







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
require "pp"
pp d.to_html

if ARGV.first == "print"
  File.open "/tmp/n.html", "w+" do |io|
    io.write d.to_html
  end
end



