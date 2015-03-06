

require 'mustache'
require 'escape_escape_escape'


# ===================================================================
# === Symbol customizations: ========================================
# ===================================================================
class Symbol

  def to_mustache meth
    WWW_App::Clean.mustache meth, self
  end

end # === class Symbol
# ===================================================================


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

    def fetch *args
      raise ContextMiss.new("Can't find: #{args.inspect}") if args.size != 2

      meth, key = args

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
# === WWW_App ====================================================
# ===================================================================
class WWW_App < BasicObject
# ===================================================================

  include ::Kernel

  Unescaped         = ::Class.new(::StandardError)
  Not_Unique        = ::Class.new(::StandardError)
  Wrong_Parent      = ::Class.new(::StandardError)
  Invalid_Type      = ::Class.new(::StandardError)
  HTML_ID_Duplicate = ::Class.new(Not_Unique)

  ALWAYS_END_TAGS = [:script]

  SYM_CACHE = { attrs: {}, css_props: {}}

  Classes                     = []
  INVALID_ATTR_CHARS          = /[^a-z0-9\_\-]/i
  IMAGE_AT_END                = /image\z/i

  NEW_LINE   = "\n".freeze
  HASH       = '#'.freeze
  DOT        = '.'.freeze
  BANG       = '!'.freeze
  NEW_LINE   = "\n".freeze
  SPACE      = ' '.freeze
  BLANK      = ''.freeze
  BODY       = 'body'.freeze
  UNDERSCORE = '_'.freeze

  Document_Template  = ::File.read(__FILE__).split("__END__").last.strip

  AT_RULES    = [ 'font-face', 'media' ]
  NO_END_TAGS = [:br, :input, :link, :meta, :hr, :img]

  HTML_TAGS   = %w[
    title
    body   div    span

    img
    b      em     i  strong  u  a 
    abbr   blockquote  cite
    br     cite   code 
    ul     ol     li  p  pre  q 
    sup    sub 
    form   input  button

    link

    script
  ].map(&:to_sym)

  # === From:
  # https://developer.mozilla.org/en-US/docs/Web/CSS/Pseudo-classes
  PSEUDO = %w[
     active checked default dir() disabled
     empty enabled
     first first-child first-of-type fullscreen focus
     hover
     indeterminate in-range invalid
     lang() last-child last-of-type left link
     not() nth-child() nth-last-child() nth-last-of-type() nth-of-type()
     only-child only-of-type optional out-of-range
     read-only read-write required right root
     scope
     target
     valid visited
  ].select { |name| name[/\A[a-z0-9\-]+\Z/] }.map { |name| name.gsub('-', '_').to_sym },

  # From: Sanitize::Config::RELAXED[:css][:properties]
  CSS_PROPERTIES = %w[
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

  ATTRIBUTES = {
    :all         => [:id, :class],
    :a           => [:href, :rel],
    :form        => [:action, :method, :accept_charset],
    :input       => [:type, :name, :value],
    :style       => [:type],
    :script      => [:type, :src, :language],
    :link        => [:rel, :type, :sizes, :href, :title],
    :meta        => [:name, :http_equiv, :property, :content, :charset],
    :img         => [:src, :width, :height]
  }

  ALLOWED_ATTRS = ATTRIBUTES.inject({}) { |memo, (tag, attrs)|
    attrs.each { |a|
      memo[a] ||= []
      memo[a] << tag
    }
    memo
  }

  class << self # ===================================================
  end # === class self ==============================================

  attr_reader :tag, :tags
  def initialize
    # ==== old
    @js              = []
    @style           = {}
    @css_arr         = []
    @css_id_override = nil
    @render_it       = true

    @title       = nil
    @scripts     = []
    @body        = []
    @compiled    = nil
    @cache       = {}
    @is_doc      = false
    @page_title  = nil
    @default_ids = {}

    @state = [:create]
    @ids   = {}

    @tag_arr           = []
    @current_tag_index = nil
    @mustache          = nil

    @html_ids          = {}
    # ==== END old vars

    @tags = []
    @tag  = nil

    create_tag(:body) do
      yield
    end

    @mustache = ::Mustache.new
    @mustache.template = to_mustache

    freeze
  end

  private # ===============================================

  def SPACE indent
    ' '.freeze * indent
  end

  def style
    create :styles, :groups=>true
    close { yield }
    nil
  end

  def find_nearest name
    return @tag if @tag[:type] == name
    find_ancestor name
  end

  def find_ancestor name
    ancestor = @tag && @tag[:parent]
    while ancestor && ancestor[:type] != name
      ancestor = ancestor[:parent]
    end
    ancestor
  end

  def go_up_to_if_exists name
    target = find_ancestor name
    (@tag = target) if target
    self
  end

  def go_up_to name
    go_up_to_if_exists name
    fail "No parent found: #{name.inspect}" unless tag && tag[:type] == name
    self
  end

  def stay_or_go_up_to_if_exists name
    return self if @tag[:type] == name
    target = find_ancestor(name)
    (@tag = target) if target

    self
  end

  def stay_or_go_up_to name
    stay_or_go_up_to_if_exists name
    fail "No parent found: #{name.inspect}" unless tag && tag[:type] == name
    self
  end

  def go_up
    @tag = @tag[:parent]
  end

  HTML_TAGS.each { |name|
    eval <<-EOF, nil, __FILE__, __LINE__ + 1
      def #{name}
        if block_given?
          create_tag(:#{name}) { yield }
        else
          create_tag(:#{name})
        end
      end
      EOF
  }

  PSEUDO.each { |name|
    eval %^
      def _#{name} *args
        if block_given?
          pseudo(:#{name}, *args) { yield }
        else
          pseudo :#{name}, *args
        end
      end
    ^
  }

  CSS_PROPERTIES.each { |name|
    eval <<-EOF, nil, __FILE__, __LINE__ + 1
      def #{name} *args
        css :#{name}, *args
      end
    EOF
  }

  def css name, *args
    @tag[:css] ||= {}
    @tag[:css][name] = args.join(', ')
    self
  end

  def parent name
    js :parent, [name]
  end

  def add_class *classes
    js :add_class, classes.flatten
  end

  def js func, args
    @tag[:js] ||= []
    @tag[:js] << [func, args]
    self
  end

  def pseudo name
    case
    when tag[:closed]
      create :group
      create :__

    when tag[:pseudo] && !tag[:closed]
      go_up_to :group
      create :__

    end # === case

    tag[:pseudo] = name
    if block_given?
      close { yield }
    end
    self
  end

  def in_a_group?
    !!( (@tag && @tag[:type] == :group) || find_ancestor(:group) )
  end

  def parent_tag
    tag && tag[:parent]
  end

  def create_tag name
    if tag && tag[:groups]
      create :group
    else
      stay_or_go_up_to_if_exists(:group) if tag && !tag[:_]
    end

    if block_given?
      create(name) { yield }
    else
      create(name)
    end
    self
  end

  def create name, opts = nil
    old = @tag
    new = {:type=>name}

    if old
      old[:children] ||= []
      old[:children] << new
      new[:parent] = old
    else
      @tags << new
    end

    @tag = new

    @tag.merge!(opts) if opts
    if block_given?
      close { yield }
    end
    self
  end

  def * arg
    tag[:id] = arg
    close { yield } if block_given?
    self
  end

  def / app
    fail "No block allowed here." if block_given?
    self
  end

  def ^ *names
    tag[:class] ||= []
    tag[:class].concat names

    close { yield } if block_given?
    self
  end

  def _
    case
    when tag[:type] == :group
      create :_
    when tag[:groups]
      create :group
      create :_
    else
      tag[:_] = true
    end

    self
  end

  def close
    group = find_nearest(:group)
    if group
      stay_or_go_up_to :group
      final_parent = parent_tag

      # We set :groups=>true because
      # we want tags created in the block to create their own
      # group as a child element.
      @tag[:groups] = true

      @tag[:closed] = true
      yield
      @tag = final_parent
      return self
    end

    @tag[:closed] = true
    final_parent = parent_tag
    yield if block_given?
    @tag = final_parent

    self
  end # === close

  HTML_TAGS = %w{ body div p a button }.map(&:to_sym)

  def to_raw_text
    str    = ""
    indent = 0
    print_tag = lambda { |t|
      info      = t.reject { |n| [:type, :parent, :children].include?( n ) }

      str += "#{" " * indent}#{t[:type].inspect} -- #{info.inspect}\n"
      indent += 1
      if t[:children]
        t[:children].each { |c|
          str << print_tag.call(c)
        }
      end
      indent -= 1
    }

    tags.each { |t| print_tag.call(t) }
    str
  end

  def to_html
    final  = ""
    indent = 0
    todo   = @tags.dup
    last   = nil

    while !todo.empty?
      tag = todo.shift
      case

      when tag == :new_line
        final << NEW_LINE

      when tag == :open
        unless indent.zero?
          final << NEW_LINE << SPACE(indent)
        end
        final << "<#{todo.shift}>"
        last = indent
        indent += 2

      when tag == :close
        indent -= 2
        if last != indent
          final << SPACE(indent)
        end
        last = indent
        final << "</#{todo.shift}>"

      when HTML_TAGS.include?(tag[:type])

        new_todo = [:open, tag[:type]]

        if tag[:children]
          new_todo.concat tag[:children]
          new_todo << :new_line
        end
        new_todo.concat [:close, tag[:type]]
        todo = new_todo.concat(todo)

      when tag[:type] == :style || tag[:type] == :styles
        todo = [:open, tag[:type], :close, tag[:type]].concat(todo)

      else
        fail "Unknown: #{tag.inspect}"
      end # === case
    end # === while

    final
  end # === to_html


  # =====================================================
  # ==== FROM: v.1.x ====================================
  # =====================================================


  def render_if name
    tag(:render_if) { tag![:attrs][:key] = name; yield }
    nil
  end

  def render_unless name
    tag(:render_unless) { tag![:attrs][:key] = name; yield }
    nil
  end

  def to_html raw_data = {}
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
  def * raw_id
    id = ::Escape_Escape_Escape.html_id(raw_id)

    old_id = tag![:attrs][:id]
    fail("Id already set: #{old_id} new: #{id}") if old_id

    fail(HTML_ID_Duplicate, "Id already used: #{id.inspect}, tag index: #{@html_ids[id]}") if @html_ids[id]
    @html_ids[id] = tag![:tag_index]

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

  # =================================================================
  #                    Parent-related methods
  # =================================================================

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

  # =================================================================
  #                 Future features...
  # =================================================================

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


  # =================================================================
  #                 Miscellaneaous Helpers
  # =================================================================

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
      :tag_index    =>  @tag_arr.size,
      :render?      =>  @render_it
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

  public def /
    fail "No block allowed here: :/" if block_given?
    close_tag
  end

  def close_tag
    orig_tag = tag!
    is_script = tag?(:script)

    if block_given?

      results = yield

      results = nil if is_script

      # The :yield may have left some opened tags, :input, :br/
      # So we make sure we are in the original tag/element
      # when we want to make some final changes.
      in_tag(orig_tag) {
        if tag?(:form)
          input(:hidden, :auth_token, :auth_token.to_mustache(:html))
        end

        if (results.is_a?(::Hash) && results[:type] && !results[:tag] && results[:type] != :string)
          fail Invalid_Type, results[:type].inspect
        end

        if (results.is_a?(::Hash) && results[:type] == :string) || results.is_a?(::String) || results.is_a?(::Symbol)
          tag![:text] = results
        end
      }
    end

    orig_tag[:is_closed] = true
    @current_tag_index = orig_tag[:parent_index]

    nil
  end

  # =================================================================
  #                    CSS-related methods
  # =================================================================

  def style
    orig = @render_it
    @render_it = false
    results = yield
    @render_it = orig
    results
  end

  def css_property name, val = nil
    prop = {:name=>name, :value=>val, :parent=>parent? ? parent : nil}

    id = css_id
    @style[:css][id] ||= {}

    @css_arr << prop
    @style[:css][id][@css_arr.map { |c| c[:name] }.join('_').to_sym] = val
    yield if block_given?
    @css_arr.pop
  end

  Methods[:css][:pseudo].each { |name|
    eval <<-EOF, nil, __FILE__, __LINE__ + 1
      public def _#{name}
        orig = @css_id_override
        @css_id_override = ':#{name}'.freeze
        result = yield
        @css_id_override = orig
        result
      end
    EOF
  }

  # =================================================================

  def page_title
    @is_doc = true
    in_tag(@head) {
      tag(:title) { @page_title = yield }
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

  def to_clean_text type, vals, tag = nil
    case

    when type == :javascript && vals.is_a?(::Array)
      clean_vals = vals.map { |raw_x|
        x = case raw_x
            when ::Symbol, ::String
              Clean.html(raw_x.to_s)
            when ::Array
              to_clean_text :javascript, raw_x
            when ::Numeric
              x
            else
              fail "Unknown type for json: #{raw_x.inspect}"
            end
      }

    when type == :to_json && vals.is_a?(::Array)
      ::Escape_Escape_Escape.json_encode(to_clean_text(:javascript, vals))

    when type == :style_classes && vals.is_a?(::Hash)
      h = vals
      h.map { |raw_k,styles|
        k = raw_k.to_s

        <<-EOF
          #{Clean.css_selector k} {
            #{to_clean_text :styles, styles}
          }
        EOF
      }.join.strip

    when type == :styles && vals.is_a?(::Hash)
      h = vals
      h.map { |k,raw_v|
        name  = begin
                  clean_k = ::WWW_App::Clean.css_attr(k.to_s.gsub('_','-'))
                  fail("Invalid name for css property name: #{k.inspect}") if !clean_k || clean_k.empty?
                  clean_k
                end

        raw_v = raw_v.to_s

        v = case

            when name[IMAGE_AT_END]
              case raw_v
              when 'inherit', 'none'
                raw_v
              else
                "url(#{Clean.href(raw_v)})"
              end

            when Methods[:css][:properties].include?(k)
              Clean.css_value raw_v

            else
              fail "Invalid css attr: #{name.inspect}"

            end # === case

        %^#{name}: #{v};^
      }.join("\n").strip

    when type == :attrs && vals.is_a?(::Hash)
      h     = vals[:attrs]
      tag   = vals
      final = h.map { |k,raw_v|

        fail "Unknown attr: #{k.inspect}" if !ALLOWED_ATTRS.include?(k)

        next if raw_v.is_a?(::Array) && raw_v.empty?

        v = raw_v

        attr_name = k.to_s.gsub(::WWW_App::INVALID_ATTR_CHARS, '_')
        fail("Invalid name for html attr: #{k.inspect}") if !attr_name || attr_name.empty?

        attr_val = case
                   when k == :href && tag[:tag] == :a
                     Clean.mustache :href, v

                   when k == :action || k == :src || k == :href
                     Clean.relative_href(v)

                   when k == :class
                     v.map { |n|
                       Clean.css_class_name(n)
                     }.join SPACE

                   when k == :id
                     Clean.html_id v.to_s

                   when ALLOWED_ATTRS[k]
                     Clean.html(v)

                   else
                     fail "Invalid attr: #{k.inspect}"

                   end # === case

        %*#{attr_name}="#{attr_val}"*

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
            WWW_App.compile(
             #{to_clean_text :to_json, h[:content]}
            );
          </script>
        EOF
      end

      html = h[:childs].map { |tag_index|
        to_clean_text(:html, @tag_arr[tag_index])
      }.join(NEW_LINE).strip

      return unless  h[:render?]

      if html.empty? && h[:text]
        html = if h[:text].is_a?(::Symbol)
                 h[:text].to_mustache(:html)
               else
                 if h[:text].is_a?(::Hash)
                   if h[:text][:escape] == false
                     h[:text][:value]
                   else
                     Clean.html(h[:text][:value].strip)
                   end
                 else
                   Clean.html(h[:text].strip)
                 end
               end
      end # === if html.empty?

      (html = nil) if html.empty?

      case
      when h[:tag] == :render_if
        key   = h[:attrs][:key]
        open  = "{{# coll.#{key} }}"
        close = "{{/ coll.#{key} }}"

      when h[:tag] == :render_unless
        key   = h[:attrs][:key]
        open  = "{{^ coll.#{key} }}"
        close = "{{/ coll.#{key} }}"

      when Methods[:elements].include?(h[:tag])
        open  = "<#{h[:tag]}#{to_clean_text(:attrs, h)}"
        if NO_END_TAGS.include?(h[:tag])
          open += ' />'
          close = nil
        else
          open += '>'
          close = "</#{h[:tag]}>"
        end

      else
        fail "Unknown html tag: #{h[:tag].inspect}"

      end # === case h[:tag]

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

    @js << 'create_event'
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

    utf_8 = Clean.clean_utf8(final)

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
    js("add_class", [name])
  end

  class Clean

    MUSTACHE_Regex = /\A\{\{\{? [a-z0-9\_\.]+ \}\}\}?\z/i

    class << self

      def mustache *args
        meth, val = args
        if val.is_a?(Symbol)
          m = "{{{ #{meth}.#{val} }}}"
          fail "Unknown chars: #{args.inspect}" unless m[MUSTACHE_Regex]
        else
          m = ::Escape_Escape_Escape.send(meth, val)
        end
        m
      end

      def method_missing name, *args
        if args.last.is_a?(::Symbol)
          args.push(args.pop.to_s)
        end
        ::Escape_Escape_Escape.send(name, *args)
      end

    end # === class << self
  end # === class Clean

end # === class WWW_App ==========================================

__END__
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    !HEAD
  </head>
  !BODY
</html>
