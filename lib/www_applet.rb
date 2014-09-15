

require 'mustache'
require 'escape_escape_escape'
require 'multi_json'


# ===================================================================
# === Mustache customizations: ======================================
# ===================================================================
Mustache.raise_on_context_miss = true

class Mustache

  def render(data = template, ctx = {})
    ctx = data
    tpl = templateify(template)

    begin
      context.push(ctx)
      tpl.render(context)
    ensure
      context.pop
    end
  end # === def render

  class Context

    def find *args
      fail "No longer needed."
    end

    def fetch meth, key
      @stack.each { |frame|
        case
        when frame.is_a?(Hash) && meth == :coll && !frame.has_key?(key)
          return false

        when frame.is_a?(Hash) && meth == :coll && frame.has_key?(key)
            target = frame[key]
            if target == true || target == false  || target == nil || target.is_a?(Array) || target.is_a?(Hash)
              return target
            end
            fail "Invalid value: #{key.inspect} (#{key.class})"

        when frame.is_a?(Hash) && frame.has_key?(key)
          return ::Escape_Escape_Escape.send(meth, frame[key])

        end
      }

      raise ContextMiss.new("Can't find .#{meth}(#{key.inspect})")
    end

    alias_method :[], :fetch

  end # === class Context

  class Generator

    alias_method :w_syms_on_fetch, :on_fetch

    def on_fetch(names)
      if names.length == 2
        "ctx[#{names.first.to_sym.inspect}, #{names.last.to_sym.inspect}]"
      else
        w_syms_on_fetch(names)
      end
    end

  end # === class Generator

end # === class Mustache
# ===================================================================


# ===================================================================
# === Symbol customizations: ========================================
# ===================================================================
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
                                      str = WWW_Applet::Sanitize.css_attr(self.to_s.gsub('_','-'))
                                      return str unless str.empty?
                                      fail "Invalid name for css property name: #{self.inspect}" 
                                    end
  end

end # === class Symbol
# ===================================================================


# ===================================================================
# === WWW_Applet ====================================================
# ===================================================================
class WWW_Applet < BasicObject
# ===================================================================

  include ::Kernel

  SYM_CACHE = { attrs: {}, css_props: {}}

  Classes                     = []
  INVALID_ATTR_CHARS          = /[^a-z0-9\_\-]/i
  IMAGE_AT_END                = /image\z/i

  HASH       = '#'
  DOT        = '.'
  BANG       = '!'
  NEW_LINE   = "\n"
  SPACE      = ' '
  BLANK      = ''
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
    @js      = []
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

      tag(:script) {
        tag![:content] = @js
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

    freeze
  end # === def new_class

  def render_if name
    tag(:render_if) { tag![:attrs][:key] = name; yield }
    nil
  end

  def render_unless name
    tag(:render_unless) { tag![:attrs][:key] = name; yield }
    nil
  end

  def render raw_data = {}
    @mustache.render raw_data
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
    @is_doc || !@style[:css].empty? || !@js.empty?
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
    i        = tag![:tag_index]
    id_given = false
    classes  = []

    while !id_given && i && i > -1
      e         = @tag_arr[i]
      id        = dom_id e
      (id_given = true) if id

      if e[:tag] == :body && !classes.empty?
        # do nothing because
        # we do not want 'body tag.class tag.class'
      else
        case
        when id
          classes << "##{id}"
        else
          classes << e[:tag]
        end # === case
      end # === if

      i = e[:parent_index]
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

    i        = tag![:tag_index]
    id_given = false
    classes  = []

    while !id_given && i && i > -1
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

      i = e[:parent_index]
      break if i == @body[:tag_index] && !classes.empty?
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
      (tag![:text] = results) if results.is_a?(::String) || results.is_a?(::Symbol)
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

  def to_clean_text type, vals
    case

    when type == :javascript && vals.is_a?(::Array)
      ::MultiJson.dump(vals, pretty: true)

    when type == :styles && vals.is_a?(::Hash)
      h = vals
      h.map { |k,raw_v|
        name = k.to_css_prop_name
        v = case
            when name[IMAGE_AT_END]
              case raw_v
              when 'inherit', 'none'
                raw_v
              else
                "url(#{Sanitize.href(raw_v)})"
              end
            else
              Sanitize.css_value raw_v
            end
        %^#{name}: #{v};^
      }.join("\n").strip

    when type == :style_classes && vals.is_a?(::Hash)
      h = vals
      h.map { |k,styles|
        <<-EOF
          #{Sanitize.css_selector k.to_s} {
            #{to_clean_text :styles, styles}
          }
        EOF
      }.join.strip

    when type == :attrs && vals.is_a?(::Hash)
      h = vals
      final = h.map { |k,raw_v|
        next if raw_v.is_a?(::Array) && raw_v.empty?
        v = raw_v.is_a?(::Array) ? raw_v.join(SPACE) : raw_v
        <<-EOF.strip
          #{k.to_html_attr_name}="#{
            case k
            when :href
              Sanitize.href(v)
            else
              Sanitize.html(v.to_s)
            end
          }"
        EOF
      }.compact.join SPACE

      final.empty? ?
        '' :
        (" " << final)

    when type == :html && vals.is_a?(::Array)
      a = vals
      a.map { |tag_index|
        to_clean_text(:html, @tag_arr[tag_index])
      }.join NEW_LINE

    when type == :html && vals.is_a?(::Hash)

      h = vals

      fail("Unknown type: #{h.inspect}") if h[:type] != :html

      if h[:tag] == :style
        return <<-EOF
          <style type="text/css">
            #{to_clean_text :style_classes, h[:css]}
          </style>
        EOF
      end

      if h[:tag] == :script && h[:content] && !h[:content].empty?
        return <<-EOF
          <script type="text/css">
            WWW_Applet.compile(
             #{to_clean_text :javascript, h[:content]}
            );
          </script>
        EOF
      end

      html = h[:childs].map { |tag_index|
        "#{to_clean_text :html, @tag_arr[tag_index]}"
      }.join(NEW_LINE).strip

      if html.empty? && h[:text]
        html = Sanitize.html(
          h[:text].is_a?(::Symbol) ?
          h[:text] :
          h[:text].strip 
        )
      end # === if html.empty?

      (html = nil) if html.empty?

      case h[:tag]
      when :render_if
        key   = h[:attrs][:key]
        open  = "{{# coll.#{key} }}"
        close = "{{/ coll.#{key} }}"
      when :render_unless
        key   = h[:attrs][:key]
        open  = "{{^ coll.#{key} }}"
        close = "{{/ coll.#{key} }}"
      else
        open  = "<#{h[:tag]}#{to_clean_text(:attrs, h[:attrs])}>"
        close = "</#{h[:tag]}>"
      end

      if h[:tag]
        [open, html, close].compact.join
      else
        html
      end

    else
      fail "Unknown vals: #{type.inspect}, #{vals.inspect}"

    end # case
  end # def to_clean_text

  def in_html?
    @state.last == :html
  end

  def creating_html?
    @state.last == :create_html
  end

  def js *args
    fail("No js event defined.") if @js.empty?
    if args.empty?
      @js.last
    else
      @js.last.concat args
    end
  end

  def on name, &blok
    fail "Block required." unless blok

    @js << "create_event"
    @js << [selector_id, name]

    orig             = @css_id_override
    @css_id_override = name
    results          = yield
    @css_id_override = orig

    if @js.last.size == 2
      @js.pop
      @js.pop
    end

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
                sub('!BODY', to_clean_text(:html, @body)).
                sub('!HEAD', to_clean_text(:html, @head[:childs]))
            else
              to_clean_text(:html, @body[:childs])
            end

    utf_8 = Sanitize.clean_utf8(final)

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

  def add_class name
    js("add_class", [Sanitize.css_attr(name)])
  end

  class Sanitize
    class << self

      def method_missing name, *args
        case
        when args.size == 1 && args.first.is_a?(Symbol)
          "{{{#{name}.#{args.first}}}}"
        else
          ::Escape_Escape_Escape.send(name, *args)
        end
      end

    end # === class << self
  end # === class Sanitize

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
