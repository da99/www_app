
require 'mustache'
require 'escape_escape_escape'

class WWW_Applet < BasicObject

  include ::Kernel

  Classes                     = []
  INVALID_ATTR_CHARS          = /[^a-z0-9\_\-]/i
  INVALID_CSS_CLASS_CHARS     = /[^a-z0-9\#\:\_\-\.\ ]/i
  INVALID_CSS_PROP_NAME_CHARS = /[^a-z0-9\-\_]/i

  BANG       = '!'
  NEW_LINE   = "\n"
  SPACE      = ' '
  BODY       = 'body'
  UNDERSCORE = '_'

  Document_Template  = ::File.read(__FILE__).split("__END__").last.strip

  Methods    = {
    :elements => %w[

      body  div

      b      em     i  strong  u  a 
      abbr   blockquote 
      br     cite   code 
      ul     ol     li  p  pre  q 
      sup    sub 
      form   input  button

    ].map(&:to_sym),

    :attributes => {
      :all         => [:id, :class],
      :a           => [:href],
      :blockquote  => [:cite],
      :form        => [:action, :method, :accept_charset],
      :input       => [:type, :name, :value],
      :style       => [:type],
      :script      => [:type, :src, :language],
      :link        => [:rel, :type, :sizes, :href, :title],
      :meta        => [:name, :http_equiv, :property, :content, :charset],
      :html        => [:lang]
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
    @title         = nil
    @style         = {}
    @scripts       = []
    @body          = []
    @compiled      = nil
    @cache         = {}
    @is_doc        = false
    @default_ids   = {}

    @state         = [:create]
    @ids           = {}

    @tag_arr          = []
    @current_tag_index = @tag_arr.size - 1
    @mustache          = nil

    open_tag(:head)
    @head = tag!
    close_tag

    open_tag(:body)
    @body = tag!
    close_tag

    files.each { |file_name|
      eval ::File.read(file_name), nil, file_name
    }

    if block_given?
      instance_eval(&(::Proc.new))
    end

    @mustache = ::Mustache.new
    @mustache.template = to_mustache

  end # === def new_class

  def render *args
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
  # so tag methods over-write them,
  # just in case there are duplicates.
  Methods[:css][:properties].each { |name|
    str_name = name.to_s.gsub('_', '-')
    eval %^
      def #{name} *args
        css_property('#{str_name}'.freeze, *args) { 
          yield if block_given?
        }
      end
    ^
  }

  Methods[:elements].each { |name|
    eval %^
      def #{name} *args
        results = open_tag(:#{name}, *args)

        if block_given?
          close_tag { yield }
        else
          results
        end
      end
    ^
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
    @is_doc
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
  #
  def dom_id *args

    case
    when args.empty?
      use_default = false

    when args.size == 1 && args.first == :default
      use_default = true

    else
      fail "Unknown args: #{args.inspect}"
    end

    id = tag![:attrs][:id]
    return id if id
    return nil unless use_default

    tag![:default_id] ||= begin
                           key = tag![:tag]
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
  #    css_id 'my_class'  -> same as 'css_id()' except
  #                          'my_class' overrides :class attribute of current
  #                          element.
  #
  #
  def css_id str_class = nil

    if !str_class && parent[:css_id]
      return parent[:css_id]
    end

    start    = @tag_arr.size - 1
    i        = start
    id_given = false
    classes  = []

    while i > -1
      curr      = @tag_arr[i]
      id        = dom_id(curr)
      css_class = if start == i && str_class
                    str_class
                  else
                    curr[:attrs][:class].first
                  end

      temp_id = case
                when id && css_class
                  "##{id}.#{css_class}"
                when id
                  "##{id}"
                when css_class
                  "#{curr[:tag]}.#{css_class}"
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

    classes.join SPACE
  end

  def parents
    fail "not done"
  end

  def parent? sym_tag
    parent && parent[:tag] == sym_tag
  end

  def parent
    @tag_arr[tag![:parent_index]]
  end

  def tag!
    @tag_arr[@current_tag_index]
  end

  def tag? sym_tag
    tag![:tag] == sym_tag
  end

  def tag sym_name, *args
    e = {
      type:   :html,
      tag:    sym_name,
      attrs:  {:class=>[]},
      text:   nil,
      childs: [],
      args:   args,
      parent_index: nil,
      is_closed: false,
      tag_index: @tag_arr.size
    }

    @tag_arr << e
    e
  end

  def slash_tag t
    if block_given?
      results = yield
      if results.is_a?(::String)
        t[:text] = results
      end
    end

    t[:is_closed] = true
    t
  end

  def in_tag t
    orig = @current_tag_index
    @current_tag_index = t[:tag_index]
    yield
    @current_tag_index = orig
    self
  end

  def open_tag *args
    new_tag = tag(*args)

    if @tag_arr.empty?
      # do nothing else.
    else
      new_tag[:parent_index] = @tag_arr.size - 1
      tag![:childs] << new_tag
    end

    @current_tag_index = @tag_arr.size - 1
    self
  end

  def close_tag

    if block_given?
      slash_tag(tag!) { yield }
    else
      slash_tag tag!
    end

    if tag![:parent_index]
      @current_tag_index = tag![:parent_index]
    end

    self
  end

  def page_title
    return super unless tag?(:body)

    @is_doc = true
    in_tag(@head) {
      open_tag(:title)
      close_tag { yield }
    }

    self
  end

  def meta *args
    fail "Not allowed outside of :head" unless tag?(:body)
    c = tag(:meta, *args)
    @head[:childs].push c
    c
  end

  def script *args, &blok
    fail "Not allowed outside of :head" unless parent?(:body)
    c = tag(:script, *args, &blok)
    @head[:childs].push c
    c
  end

  def array_to_text a
    hash_to_text(:type=>:html, :childs=>a)
  end

  def hash_to_text h
    case h[:type]

    when :html
      if h[:tag] == :style
        return %^
          <style type="text/css">
            #{style_classes_to_text(h[:attrs])}
          </style>
        ^
      end

      html = h[:childs].map { |c|
        "#{hash_to_text c}"
      }.join NEW_LINE

      if h[:text] && !(h[:text].strip).empty?
        if html.empty?
          html = h[:text]
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
      %^#{k.to_s.gsub(INVALID_CSS_PROP_NAME_CHARS, '_')}: #{v};^
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
        %^#{k.to_s.gsub(INVALID_ATTR_CHARS,'_')}="#{::Escape_Escape_Escape.inner_html(v)}"^
      }.join SPACE

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

    orig          = parent[:css_id]
    orig_selector = parent[:selector_id]

    parent[:css_id] = css_id(name)
    parent[:parent_selector] = selector_id()

    results = yield

    parent[:css_id]          = orig
    parent[:parent_selector] = orig_selector

    results
  end

  def to_mustache

    return @compiled  if @compiled

    final = if is_doc?
              # Remember: to use !BODY first, because
              # :head content might include a '!HEAD'
              # value.
              no_title unless @page_title
              if !@style.empty?
                @head[:childs] << tag(:style, @style)
              end

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
      open_tag(:input).type(args[0]).name(args[1]).value(args[2])
      close_tag
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
