
require 'mustache'
require 'escape_escape_escape'

class Symbol

  def to_html_attr_name
    WWW_Applet::SYM_CACHE[:attrs][self] ||= begin
                                      str = to_s.gsub(WWW_Applet::INVALID_ATTR_CHARS, '_')
                                      return str unless str.empty?
                                      fail "Invalid name for html attr: #{self.inspect}" 
                                    end
  end # === def to_html_attr_name

  def to_css_prop_name
    WWW_Applet::SYM_CACHE[:css_props][self] ||= begin
                                      str = to_s.gsub(WWW_Applet::INVALID_CSS_PROP_NAME_CHARS, '-')
                                      return str unless str.empty?
                                      fail "Invalid name for css property name: #{self.inspect}" 
                                    end
  end

end # === class Symbol

class WWW_Applet < BasicObject

  include ::Kernel

  SYM_CACHE = { attrs: {}, css_props: {}}

  Classes                     = []
  INVALID_ATTR_CHARS          = /[^a-z0-9\_\-]/i
  INVALID_CSS_CLASS_CHARS     = /[^a-z0-9\#\:\_\-\.\ ]/i
  INVALID_CSS_PROP_NAME_CHARS = /[^a-z0-9-]/i

  HASH       = '#'
  DOT        = '.'
  BANG       = '!'
  NEW_LINE   = "\n"
  SPACE      = ' '
  BODY       = 'body'
  UNDERSCORE = '_'

  Document_Template  = ::File.read(__FILE__).split("__END__").last.strip

  Methods    = {
    :elements => %w[

      body   div    span

      b      em     i  strong  u  a 
      abbr   blockquote 
      br     cite   code 
      ul     ol     li  p  pre  q 
      sup    sub 
      form   input  button

    ].map(&:to_sym),

    :attributes => {
      :all         => [:id, :class],
      :a           => [:href, :rel],
      :blockquote  => [:cite],
      :form        => [:action, :method, :accept_charset],
      :input       => [:type, :name, :value],
      :style       => [:type],
      :script      => [:type, :src, :language],
      :link        => [:rel, :type, :sizes, :href, :title],
      :meta        => [:name, :http_equiv, :property, :content, :charset]
    },

    :protocols=> {
      :a          => {:href=>['ftp', 'http', 'https', :relative]},
      :blockquote => {:cite=>['http', 'https', :relative]},
      :form       => {:action=>[:relative]},
      :script     => {:src=>[:relative]},
      :link       => {:href=>[:relative]}
    },

    :css => {
      :at_rules       => [ 'font-face', 'media' ],
      :protocols      => [ :relative ],

      # From: Sanitize::Config::RELAXED[:css][:properties]
      :properties     => %w[
        background                 bottom                     font_variant_numeric       position
        background_attachment      box_decoration_break       font_variant_position      quotes
        background_clip            box_shadow                 font_weight                resize
        background_color           box_sizing                 height                     right
        background_image           clear                      hyphens                    tab_size
        background_origin          clip                       icon                       table_layout
        background_position        clip_path                  image_orientation          text_align
        background_repeat          color                      image_rendering            text_align_last
        background_size            column_count               image_resolution           text_combine_horizontal
        border                     column_fill                ime_mode                   text_decoration
        border_bottom              column_gap                 justify_content            text_decoration_color
        border_bottom_color        column_rule                left                       text_decoration_line
        border_bottom_left_radius  column_rule_color          letter_spacing             text_decoration_style
        border_bottom_right_radius column_rule_style          line_height                text_indent
        border_bottom_style        column_rule_width          list_style                 text_orientation
        border_bottom_width        column_span                list_style_image           text_overflow
        border_collapse            column_width               list_style_position        text_rendering
        border_color               columns                    list_style_type            text_shadow
        border_image               content                    margin                     text_transform
        border_image_outset        counter_increment          margin_bottom              text_underline_position
        border_image_repeat        counter_reset              margin_left                top
        border_image_slice         cursor                     margin_right               touch_action
        border_image_source        direction                  margin_top                 transform
        border_image_width         display                    marks                      transform_origin
        border_left                empty_cells                mask                       transform_style
        border_left_color          filter                     mask_type                  transition
        border_left_style          float                      max_height                 transition_delay
        border_left_width          font                       max_width                  transition_duration
        border_radius              font_family                min_height                 transition_property
        border_right               font_feature_settings      min_width                  transition_timing_function
        border_right_color         font_kerning               opacity                    unicode_bidi
        border_right_style         font_language_override     order                      unicode_range
        border_right_width         font_size                  orphans                    vertical_align
        border_spacing             font_size_adjust           overflow                   visibility
        border_style               font_stretch               overflow_wrap              white_space
        border_top                 font_style                 overflow_x                 widows
        border_top_color           font_synthesis             overflow_y                 width
        border_top_left_radius     font_variant               padding                    word_break
        border_top_right_radius    font_variant_alternates    padding_bottom             word_spacing
        border_top_style           font_variant_caps          padding_left               word_wrap
        border_top_width           font_variant_east_asian    padding_right              z_index
        border_width               font_variant_ligatures     padding_top
      ].map(&:to_sym)
    }

  }

  class << self # ===================================================
  end # === class self ==============================================

  def initialize *files
    @style   = {}
    @css_arr = []
    @css_id_override = nil

    @title       = nil
    @scripts     = []
    @body        = []
    @compiled    = nil
    @cache       = {}
    @is_doc      = false
    @default_ids = {}

    @state = [:create]
    @ids   = {}

    @tag_arr           = []
    @current_tag_index = nil
    @mustache          = nil

    tag(:head) {

      @head = tag!

      tag(:style) {
        @style = tag!
        @style[:css] = {}
      }

    } # === tag :head

    tag(:body) {

      @body = tag!

      files.each { |file_name|
        eval ::File.read(file_name), nil, file_name
      }

      instance_eval(&(::Proc.new)) if block_given?
    }

    @mustache = ::Mustache.new
    @mustache.template = to_mustache

  end # === def new_class

  def render *args
    (args << {}) if args.empty?
    @mustache.render *args
  end

  Allowed = {
    :attr => {}
  }

  Methods[:attributes].each { |tag, attrs|
    next if tag == :all
    attrs.each { |raw_attr|
      attr_name = raw_attr.to_s.gsub('-', '_').to_sym
      Allowed[:attr][attr_name] ||= {}
      Allowed[:attr][attr_name][tag.to_sym] = true
    }
  }

  Allowed[:attr].each { |name, tags|
    eval <<-EOF, nil, __FILE__, __LINE__ + 1
      def #{name} val
        allowed = Allowed[:attr][:#{name}]
        allowed = allowed && allowed[tag![:tag]]
        return super unless allowed

        tag![:attrs][:#{name}] = val

        if block_given?
          close_tag { yield }
        else
          self
        end
      end
    EOF
  }

  #
  # Example:
  #   div.*('my_id') { }
  #
  def * id
    old_id = tag![:attrs][:id]
    fail("Id already set: #{old_id} new: #{id}") if old_id
    tag![:attrs][:id] = id

    if block_given?
      close_tag { yield }
    else
      self
    end
  end

  #
  # Example:
  #   div.^(:alert, :red_hot) { 'my content' }
  #
  def ^ *names
    tag![:attrs][:class].concat(names).uniq!

    if block_given?
      close_tag { yield }
    else
      self
    end
  end

  private # =========================================================

  #
  # NOTE: Properties are defined first,
  # so :elements methods can over-write them,
  # just in case there are duplicates.
  Methods[:css][:properties].each { |name|
    str_name = name.to_s.gsub('_', '-')
    eval <<-EOF, nil, __FILE__, __LINE__ + 1
      def #{name} *args
        css_property(:#{name}, *args) { 
          yield if block_given?
        }
      end
    EOF
  }

  Methods[:elements].each { |name|
    eval <<-EOF, nil, __FILE__, __LINE__ + 1
      def #{name} *args
        if block_given?
          tag(:#{name}, *args) { yield }
        else
          tag(:#{name}, *args)
        end
      end
    EOF
  }

  # -----------------------------------------------
  def section
    fail
  end

  def on_top_of
    fail
  end

  def in_middle_of
    fail
  end

  def at_bottom_of
    fail
  end
  # -----------------------------------------------

  def is_doc?
    @is_doc || !@style[:css].empty?
  end

  def first_class
    tag![:attrs][:class].first
  end

  def html_element? e
    e.is_a?(Hash) && e[:type] == :html
  end

  def dom_id?
    tag![:attrs][:id]
  end

  #
  # Examples
  #    dom_id             -> the current dom id of the current element
  #    dom_id :default    -> if no dom it, set/get default of current element
  #    dom_id {:element:} -> dom id of element: {:type=>:html, :tag=>...}
  #
  def dom_id *args

    use_default = false

    case
    when args.empty?
      e = tag!
      # do nothing else

    when args.size == 1 && args.first == :default
      e = tag!
      use_default = true

    when args.size == 1 && args.first.is_a?(::Hash) && args.first[:type]==:html
      e = args.first

    else
      fail "Unknown args: #{args.inspect}"
    end

    id = e[:attrs][:id]
    return id if id
    return nil unless use_default

    e[:default_id] ||= begin
                           key = e[:tag]
                           @default_ids[key] ||= -1
                           @default_ids[key] += 1
                         end
  end # === def dom_id

  #
  # Examples
  #    selector_id   -> a series of ids and tags to be used as a JS selector
  #                     Example:
  #                        #id tag tag
  #                        tag tag
  #
  #
  def selector_id
    start    = @tag_arr.size - 1
    i        = start
    id_given = false
    classes  = []

    while i > -1
      curr      = @tag_arr[i]
      id        = dom_id(curr)

      temp_id = case
                when id
                  "##{id}"
                else
                  curr[:tag]
                end

      if temp_id == :body && !classes.empty?
        # do nothing because
        # we do not want 'body tag.class tag.class'
      else
        classes.unshift temp_id
      end

      break if id_given
      i = i - 1
    end

    return 'body' if classes.empty?
    classes.join SPACE
  end

  #
  # Examples
  #    css_id             -> current css id of element.
  #                          It uses the first class, if any, found.
  #                          #id.class     -> if #id and first class found.
  #                          #id           -> if class is missing and id given.
  #                          #id tag.class -> if class given and ancestor has id.
  #                          #id tag tag   -> if no class given and ancestor has id.
  #                          tag tag tag   -> if no ancestor has class.
  #
  #    css_id :my_class   -> same as 'css_id()' except
  #                          'my_class' overrides :class attribute of current
  #                          element.
  #
  #
  def css_id *args

    str_class = nil

    case args.size
    when 0
      fail "Not in a tag." unless tag!
      str_class = @css_id_override
    when 1
      str_class = args.first
    else
      fail "Unknown args: #{args.inspect}"
    end

    start    = tag![:tag_index]
    i        = start
    id_given = false
    classes  = []

    while i > -1
      e           = @tag_arr[i]
      id          = dom_id e
      first_class = e[:attrs][:class].first

      if id
        id_given = true
        if str_class
          classes.unshift(
            str_class.is_a?(::Symbol) ?
            "##{id}.#{str_class}" :
            "##{id}#{str_class}"
          )
        else
          classes.unshift "##{id}"
        end

      else # no id given
        if str_class
          classes.unshift(
            str_class.is_a?(::Symbol) ?
            "#{e[:tag]}.#{str_class}" :
            "#{e[:tag]}#{str_class}"
          )
        elsif first_class
          classes.unshift "#{e[:tag]}.#{first_class}"
        else
          if e[:tag] != :body || (classes.empty?)
            classes.unshift "#{e[:tag]}"
          end
        end # if first_class

      end # if id

      break if id_given
      i = e[:parent_index]
      break if !i || (i == @body[:tag_index] && !classes.empty?)
    end

    classes.join SPACE
  end

  # =================================================================
  #                    Parent-related methods
  # =================================================================

  def css_parent?
    !@css_arr.empty?
  end

  def parents
    fail "not done"
  end

  def parent? *args
    return(tag! && !tag![:parent_index].nil?) if args.empty?
    fail("Unknown args: #{args.first}") if args.size > 1
    return false unless parent

    sym_tag = args.first

    case sym_tag
    when :html, :css, :script
      parent[:type] == sym_tag
    else
      parent[:tag] == sym_tag
    end
  end

  def parent
    fail "Not in a tag." unless tag!
    fail "No parent: #{tag![:tag].inspect}, #{tag![:tag_index]}" if !tag![:parent_index]
    @tag_arr[tag![:parent_index]]
  end

  # =================================================================
  #                    Tag (aka element)-related methods
  # =================================================================

  def tag!
    return nil unless @current_tag_index.is_a?(::Numeric)
    @tag_arr[@current_tag_index]
  end

  def tag? sym_tag
    tag![:tag] == sym_tag
  end

  def tag sym_name
    e = {
      :type         =>  :html,
      :tag          =>  sym_name,
      :attrs        =>  {:class=>[]},
      :text         =>  nil,
      :childs       =>  [],
      :parent_index =>  @current_tag_index,
      :is_closed    =>  false,
      :tag_index    =>  @tag_arr.size
    }

    @tag_arr << e
    @current_tag_index = e[:tag_index]

    if parent?
      parent[:childs] << e[:tag_index]
    else
      if !([:head, :body].include? e[:tag])
        fail "No parent found for: #{sym_name.inspect}"
      end
    end

    if block_given?
      close_tag { yield }
    else
      self
    end
  end

  def in_tag t
    orig = @current_tag_index
    @current_tag_index = t[:tag_index]
    yield
    @current_tag_index = orig
    nil
  end

  def close_tag
    if block_given?
      results = yield
      (tag![:text] = results) if results.is_a?(::String)
    end

    tag![:is_closed] = true
    @current_tag_index = tag![:parent_index]

    nil
  end

  # =================================================================
  #                    CSS-related methods
  # =================================================================

  def css_property name, val = nil
    prop = {:name=>name, :value=>val, :parent=>parent? ? parent : nil}

    id = css_id
    @style[:css][id] ||= {}

    @css_arr << prop
    @style[:css][id][@css_arr.map { |c| c[:name] }.join('_').to_sym] = val
    yield if block_given?
    @css_arr.pop
  end


  # =================================================================

  def page_title
    @is_doc = true
    in_tag(@head) {
      tag(:title) { yield }
    }
    self
  end

  def meta *args
    fail "No block allowed." if block_given?
    fail "Not allowed here." unless tag?(:body)
    c = nil
    in_tag(@tag) { c = tag(:meta, *args) }
    c
  end

  def script *args
    fail "No block allowed for now." if block_given?
    fail "Not allowed here." unless parent?(:body)
    s = nil
    in_tag(@head) { s = tag(:script, *args) }
    s
  end

  def array_to_text a
    a.map { |tag_index|
      hash_to_text(@tag_arr[tag_index])
    }.join NEW_LINE
  end

  def hash_to_text h
    case h[:type]

    when :html
      if h[:tag] == :style
        return %^
          <style type="text/css">
            #{style_classes_to_text(h[:css])}
          </style>
        ^
      end

      html = h[:childs].map { |tag_index|
        "#{hash_to_text @tag_arr[tag_index]}"
      }.join NEW_LINE

      if h[:text] && !(h[:text].strip.empty?)
        if html.empty?
          html = ::Escape_Escape_Escape.html(h[:text])
        else
          html << hash_to_text(tag(:div, :class=>:text) { h[:text] })
        end
      end

      if h[:tag]
        %^
          <#{h[:tag]}#{tag_attrs_to_text(h[:attrs])}>#{html}</#{h[:tag]}>
        ^.strip
      else
        html
      end

    when :script
      fail "Not ready yet."

    else
      fail "Unknown type: #{h[:text].inspect}"
    end
  end

  def styles_to_text h
    h.map { |k,v|
      %^#{k.to_css_prop_name}: #{::Escape_Escape_Escape.css v};^
    }.join("\n").strip
  end

  def style_classes_to_text h
    h.map { |k,styles|
      %^#{k.to_s.gsub(INVALID_CSS_CLASS_CHARS, UNDERSCORE)} {
          #{styles_to_text styles}
        }
      ^
    }.join.strip
  end

  def tag_attrs_to_text h
    final = h.map { |k,raw_v|
      next if raw_v.is_a?(::Array) && raw_v.empty?
      v = raw_v.is_a?(::Array) ? raw_v.join(SPACE) : raw_v
      %^#{k.to_html_attr_name}="#{
        case k
        when :href
          ::Escape_Escape_Escape.href(v)
        else
          ::Escape_Escape_Escape.html(v.to_s)
        end
      }"^
    }.compact.join SPACE

    if final.empty?
      ''
    else
      " " << final
    end
  end

  def in_html?
    @state.last == :html
  end

  def creating_html?
    @state.last == :create_html
  end

  def on name, &blok
    fail "Block required." unless blok

    orig             = @css_id_override
    @css_id_override = name
    results          = yield
    @css_id_override = orig

    results
  end

  def to_mustache

    return @compiled  if @compiled

    final = if is_doc?
              # Remember: to use !BODY first, because
              # :head content might include a '!HEAD'
              # value.
              (page_title { 'Unknown Page Title' }) unless @page_title

              Document_Template.
                sub('!BODY', hash_to_text(@body)).
                sub('!HEAD', array_to_text(@head[:childs]))
            else
              array_to_text(@body[:childs])
            end

    utf_8 = ::Escape_Escape_Escape.clean_utf8(final)

    @compiled  = utf_8
  end # === def to_mustache


  def input *args
    case
    when args.size === 3
      tag(:input).type(args[0]).name(args[1]).value(args[2])
    else
      super
    end
  end

end # === class WWW_Applet ==========================================

__END__
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    !HEAD
  </head>
  !BODY
</html>
