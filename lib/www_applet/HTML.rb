
require "nokogiri"
require "escape_escape_escape"
require "www_applet/Clean"


class WWW_Applet
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

      def attributes
        @attributes ||= {
          :id              => ["id", :size_between, [1, 100], :match, [/\A[a-z0-9\_\-\ ]{1,100}\Z/i , "id has invalid chars"] ],
          :title           => ["title", :string, :size_between, [1, 200]],
          :max_chars       => ["max-chars", :number_between, [1, 10_000]]
        }
      end

      def elements
        @elements ||= begin
                        Escape_Escape_Escape::CONFIG[:elements].inject({}) { |memo, e|
                          memo[e.to_sym] = [e]
                          memo
                        }.merge({
                          :p                 => ["p", :strip, :not_empty_string],
                          :box               => ["div", {"class"=>"box"}],
                          :form              => ['form'],
                          :password          => ['input', {"type"=>'password'}],
                          :one_line_text_box => ['input', {"type"=>'text', "value"=>''}],
                          :text_box          => ['textarea'],
                          :note              => ["span", {'class'=>'note'}, :not_empty_string],
                          :button            => ['button']
                        })
                      end
      end

    end # === class self ===================================================

    def styles sender, to, args
      rule_name = sender.grab_stack_tail(1, "a name for the style")
      the_styles[rule_name] ||= {}
      args.each { |o|
        case
        when is_style?(o)
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

          {"IS"=>["STYLE"], "NAME"=>css_name, "VALUE"=>clean}

        end
      ^
    }

    attributes.each { |name, props|
      eval %^
        def #{name} sender, to, args
          {"IS"=>["ATTRIBUTE"], "NAME"=>:#{name}, "VALUE"=>args.last}
        end
      ^
    }

    elements.each { |name, props|
      eval %^
        def #{name} sender, to, args
          {"IS"=>["ELEMENT"], "NAME"=>:#{name}, "VALUE"=>args}
        end
      ^
    }


    # ===================================================
    #                    Events
    # ===================================================

    def on_click sender, to, args
      {"IS"=>["ATTRIBUTE"], "NAME"=>standard_key(to), "VALUE"=>args.last}
    end

    def on_hover sender, to, args
      vals = args.select { |o| is_style?(o) }.inject({}) do |memo, s|
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
      the_css = the_styles.inject("") { |memo, (k, v)|
        memo << "
         #{k} {
           #{v.to_a.map { |pair| "#{pair.first}: #{pair.last.is_a?(Array) ? pair.last.join(', ') : pair.last};" }.join "
           " }
         }
      "
        memo
      }

      the_body = ""

      stack.each { |o|
        next unless is_element?(o)
        the_body << element_to_html(o)
      }

      %^<!DOCTYPE html><html lang="en"><head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
        <title>[No Title]</title>
        <style type="text/css"> #{Sanitize::CSS.stylesheet the_css, Escape_Escape_Escape::CONFIG} </style>
      </head>
      <body>#{Escape_Escape_Escape.html the_body}</body></html>^
    end


    private # ==========================================

    def the_doc
      @the_doc ||= Nokogiri::HTML HTML.page
    end

    def the_body
      @the_body ||= the_doc.at('body')
    end

    def element_to_html raw
      meta  = HTML.elements[raw["NAME"]].dup
      tag   = meta.shift.split.first

      custom_attrs = raw["VALUE"].select { |o| is_attribute?(o) }.inject({}) do |memo, hash|
        memo[hash["NAME"]] = hash["VALUE"]
        memo
      end

      attrs  = custom_attrs.merge( meta.first.is_a?(Hash) ? meta.shift : {})

      childs = raw["VALUE"].map { |o|
        next unless is_element?(o)
        element_to_html o
      }.compact

      inner_html = raw["VALUE"].last.is_a?(String) ?
        Escape_Escape_Escape.inner_html(raw["VALUE"].last) :
        nil

      return nil if !inner_html && childs.empty?

      attr_string = attrs.inject("") do |memo, (k,v)|
        case v
        when String
          memo << "#{k}=\"#{Escape_Escape_Escape.inner_html(v)}\""
        when Numeric
          memo << "#{k}=\"#{v}\""
        else
          if k != "ON CLICK"
          fail "Unknown type for HTML encoding/escaping: #{k.inspect} => #{v.inspect}"
          end
        end
        memo
      end


      if childs.empty?
        childs << inner_html
      elsif inner_html
        childs << %^<div class="content"> #{inner_html}</div>^
      end

      %^<#{tag} #{attr_string}>#{childs.join ""}</#{tag}>^
    end

    def the_styles
      @the_stles ||= {}
    end

    def is_applet_object? o
      o.is_a?(Hash) && o["IS"].is_a?(Array)
    end

    def is_style? o
      is_applet_object?(o) && o["IS"].include?("STYLE")
    end

    def is_element? o
      is_applet_object?(o) && o["IS"].include?("ELEMENT")
    end

    def is_style_class? o
      is_applet_object?(o) && o["IS"].include?("STYLE CLASS")
    end

    def is_attribute? o
      is_applet_object?(o) && o["IS"].include?("ATTRIBUTE")
    end

  end # === module HTML

end # === class WWW_Applet







