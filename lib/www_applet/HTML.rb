
require "nokogiri"
require "escape_escape_escape"
require "www_applet/Clean"

class WWW_Applet
  module HTML

    VALUE_GROUPS  = [:Sub_Styles , :Styles , :Attributes , :Elements , :Actions]
    VALUE_CLASSES = [:Sub_Style  , :Style  , :Attribute  , :Element  , :Action]

    VALUE_CLASSES.each { |name|
      Object.class_eval %^
        def #{name.to_s.downcase}?
          false
        end
      ^
    }

    COMPUTERS = {
    }

    Sub_Styles = {
      :on_hover  => [:name, ['hover']]
    }

    Styles = {
      :background_color     => [:color],
      :background_image_url => [:url],
      :background_repeat    => [
        :downcase,
        :in, %w[ repeat-all repeat-x repeat-y none ]
      ],
      :font_family => [:grab_all, :fonts],
      :color       => [:color],
      :font_size   => [
        :downcase,
        :in, %w[ small large medium x-large ]
      ]
    }

    Attributes = {
      :title     => [:allow_in, [:body], :string, :size_between, [1, 200]],
      :max_chars => [:number_between, [1, 10_000]],
      :href      => [:allow_in, [:a], :not_empty_string, :size_between, [1,200]],
      :id        => [
        :size_between, [1, 100],
        :match, [/\A[a-z0-9\_\-\ ]{1,100}\Z/i , "id has invalid chars"] 
      ]
    }

    Elements = {
      :p                 => [:strip, :not_empty_string],
      :box               => [:attr, {"class"=>"box"}],
      :form              => [],
      :password          => [:tag, ['input'], :attr, {"type"=>'password'}],
      :one_line_text_box => [:tag, ['input'], :attr, {"type"=>'text', :value=>''}],
      :text_box          => [:tag, ['textarea']],
      :note              => [:tag, ['span'], :attr, {'class'=>'note'}, :not_empty_string],
      :button            => [:not_empty_string],
      :a                 => [:not_empty_string],
    }

    Actions = {
      :on_click  => []
    }

    START_ON_REGEXP = /^on_/i

    private def new_html_value sender, to, args, meta
    o              = meta.dup
    o[:attributes] = {}
    o[:childs]     = []

    if meta[:grab_all]
      o[:value] = Clean.new(to, args).clean_as(*meta[:cleaners]).actual
      return o
    end

    o[:value] = Clean.new(to, args.last).clean_at(*meta[:cleaners]).actual

    args.each { |raw| # =========================================================

      next unless o.applet_object?
      is_not_allowed = raw[:allow_in] && !raw[:allow_in].include?(o[:tag])
      fail(%^Invalid: "#{raw[:tag]}" not allowed in #{to.inspect}^) if is_not_allowed


      case

      when o.applet?(:sub_style)

      when o.applet?(:style)
        o[:sub_styles] = 

      when o.applet?(:attribute)
        o[:attributes][raw[:name]] = raw[:value] 

      when o.applet?(:element)
        o[:childs] << o if raw.applet?(:element)

      when o.applet?(:action)

      else
        fail "Programmer error: unable to handle: #{o[:is].inspect}"

      end

    } # === .each =============================================================

    if o[:final_attributes]
      o[:attributes] = o[:attributes].merge(o[:final_attributes])
    end

    o
  end

  def styles sender, to, args
    rule_name = sender.grab_stack_tail(1, "a name for the style")
    the_styles[rule_name] ||= {}

    {
      :is    => [:style_class],
      :name  => rule_name,
      :value => args.select { |o|
        case
        when is_element?(o)
          fail "Not allowed: element, #{o[:name].inspect}, inside style list: #{to.inspect}"
        when is_attribute?(o)
          fail "Not allowed: attribute, #{o[:name].inspect}, inside style list: #{to.inspect}"
        when is_style?(o) || is_sub_style?(o) || is_action?(o)
          true
        end
      }
    }
  end


  # ===================================================
  #                    Events
  # ===================================================

  def on_click sender, to, args
    {:is=>["ATTRIBUTE"], :name=>standard_key(to), :value=>args.last}
  end

  def on_hover sender, to, args
    vals = args.select { |o| is_style?(o) }.inject({}) do |memo, s|
      memo[s[:name]] = s[:value]
      memo
    end

    {:is=>["STYLE CLASS"], :name=>standard_key(to).sub("ON ", '').downcase, :value=>vals}
  end

  # ===================================================
  #                    Actions
  # ===================================================

  def submit_form sender, to, args
    {:is=>["PROPERTY"], :name=>standard_key(to), :value=>args.last}
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
        <style type="text/css">#{Sanitize::CSS.stylesheet the_css, Escape_Escape_Escape::CONFIG}</style>
      </head>
      <body>#{Escape_Escape_Escape.html the_body}</body></html>^
  end


  private # ==========================================

  def is_applet_object? o
    o.is_a?(Hash) && o[:is].is_a?(Array)
  end

  [:style, :sub_style, :element, :style_class, :attribute].each { |name|
    eval %^
      def is_#{name}? o
        is_applet_object?(o) && o[:is].include?(:#{name})
      end
    ^
  }

  def the_doc
    @the_doc ||= Nokogiri::HTML HTML.page
  end

  def the_body
    @the_body ||= the_doc.at('body')
  end

  def element_to_html raw
    meta  = HTML.elements[raw[:name]].dup
    tag   = meta.shift.split.first

    custom_attrs = raw[:value].select { |o| is_attribute?(o) }.inject({}) do |memo, hash|
      memo[hash[:name]] = hash[:value]
      memo
    end

    attrs  = custom_attrs.merge( meta.first.is_a?(Hash) ? meta.shift : {})

    childs = raw[:value].map { |o|
      next unless is_element?(o)
      element_to_html o
    }.compact

    inner_html = raw[:value].last.is_a?(String) ?
      Escape_Escape_Escape.inner_html(raw[:value].last) :
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

  class Value < Hash

    [:name, :tag, :cleaners].each { |name|
      eval %^
        def #{name}
          @meta[:#{name}]
        end
      ^
    }

    def allow_in? o
      return true if @meta[:allow_in]
      @meta[:allow_in].include? o[:tag]
    end

    [:sub_style, :style, :attribute, :element, :action].each { |name|
      eval %^
        def #{name}?
          self[:is].include?(:#{name})
        end
      ^
    }

    def render
      case
      when element?
      when style?
      else
        fail "Unknown: render for #{self[:is].inspect}"
      end
    end

  end # === class Value

  # =========================================================================
  class Sub_Style # ie Psuedo-Styles

    def initialize sender, to, args, meta, args
      @meta = meta
      args.each { |o|
        if o.element?
          fail "Not allowed: element, #{o[:name].inspect}, inside sub-style, #{name.inspect}"
        end
      }
    end

  end # === class Sub_Style
  # =========================================================================

  # =========================================================================
  class Style

    def initialize sender, to, args, meta, args
    end

    def style?
      true
    end

  end # === class Style
  # =========================================================================

  # =========================================================================
  class Attribute

    def initialize sender, to, args, meta, args
    end

    def attribute?
      true
    end

  end # === class Attribute
  # =========================================================================

  # =========================================================================
  class Element

    def initialize sender, to, args, meta, args
    end

    def element?
      true
    end

  end # === class Element
  # =========================================================================

  # =========================================================================
  class Action

    def initialize sender, to, args, meta, args
    end

    def action?
      true
    end

  end # === class Action
  # =========================================================================


end # === module HTML

end # === class WWW_Applet







