
require 'sanitize'

class WWW_Applet

  Classes                     = []
  INVALID_ATTR_CHARS          = /[^a-z0-9\_\-]/i
  INVALID_CSS_CLASS_CHARS     = /[^a-z0-9\#\:\_\-\.\ ]/i
  INVALID_CSS_PROP_NAME_CHARS = /[^a-z0-9\-\_]/i

  Document_Template  = File.read(__FILE__).split("__END__").last.strip

  Sanitize_Config    = {

    :allow_doctype   => true,
    :allow_comments  => false,
    :remove_contents => true,

    :elements => %w[

      html  head  title  meta  style  link 
      body  div

      b      em     i  strong  u  a 
      abbr   blockquote 
      br     cite   code 
      ul     ol     li  p  pre  q 
      sup    sub 
      form   input  button

    ],

    :attributes => {
      :all         => ['id', 'class'],
      'a'          => ['href'],
      'blockquote' => ['cite'],
      'form'       => ['action', 'method', 'accept-charset'],
      'input'      => ['type', 'name', 'value'],
      'style'      => ['type'],
      'script'     => ['type', 'src', 'language'],
      'link'       => ['rel', 'type', 'sizes', 'href', 'title'],
      'meta'       => ['name', 'http-equiv', 'property', 'content', 'charset'],
      'html'       => ['lang']
    },

    :protocols=> {
      'a'          => {'href'=>['ftp', 'http', 'https', :relative]},
      'blockquote' => {'cite'=>[:relative]},
      'form'       => {'action'=>[:relative]},
      'script'     => {'src'=>[:relative]},
      'link'       => {'href'=>[:relative]}
    },

    :css => {
      :allow_comments => false,
      :allow_hacks    => false,
      :at_rules       => [ 'font-face', 'media' ],
      :protocols      => [ :relative ],
      :properties     => Sanitize::Config::RELAXED[:css][:properties]
    }

  }

  class << self # ===================================================

    def new
      fail "Not implemented."
    end

    def new_class *files

      name = "Rand_#{Classes.size}"

      eval <<-EOF.strip
        class #{name} << BasicObject
          include ::WWW_Applet::Mod
          include ::WWW_Applet::Customized_Tags
        end
      EOF
      o = self.class.const_get name

      meth_names = []
      files.each_with_index { |file_name, i|

        meth_name = "generate_scroll_#{i}"
        meth_names << meth_name

        eval <<-EOF.strip, nil, file_name, 1-3
          class #{name}
            def #{meth_name}
              #{file_name ? ::File.read(file_name) : ''}
            end
          end
        EOF

      }

      eval <<-EOF.strip
        class #{name}
          def generate_the_scroll
            #{meth_names.join "\n".freeze}
          end
        end
      EOF

      if block_given?
        blok = Proc.new
        o.class_eval {
          define_method :run do
            instance_eval &blok
          end
        }
      end

      Classes << o
      o
    end # === def new_class

  end # === class self ==============================================

  module Mod # ======================================================

    private
    include ::Kernel

    BANG       = '!'
    NEW_LINE   = "\n"
    SPACE      = ' '
    BODY       = 'body'
    UNDERSCORE = '_'

    def initialize data = nil
      @title         = nil
      @style         = {}
      @scripts       = []
      @body          = []
      @data          = data || {}
      @compiled      = nil
      @cache         = {}
      @is_doc        = false
      @default_ids   = {}

      @head          = tag(:head)
      @body          = tag(:body)
      @state         = [:create]
      @ids           = {}

      @tree          = [@head, @body]
      @current_tag   = @body
    end

    ::WWW_Applet::Sanitize_Config[:elements].each { |name|
      next if name == 'html'.freeze
      next if name == 'head'.freeze
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

    ::WWW_Applet::Sanitize_Config[:css][:properties].each { |name|
      eval %^
        def #{name} *args
          if block_given?
            css_property(:#{name}, *args) { yield }
          else
            css_property(:#{name}, *args)
          end
        end
      ^
    }

    Allowed = {
      :attr => {}
    }

    ::WWW_Applet::Sanitize_Config[:attributes].each { |tag, attrs|
      next if tag == :all
      attrs.each { |raw_attr|
        attr_name = raw_attr.gsub('-', '_').to_sym
        Allowed[:attr][attr_name] ||= {}
        Allowed[:attr][attr_name][tag.to_sym] = true
      }
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
      start    = @tree.size - 1
      i        = start
      id_given = false
      classes  = []

      while i > -1
        curr      = @tree[i]
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

      start    = @tree.size - 1
      i        = start
      id_given = false
      classes  = []

      while i > -1
        curr      = @tree[i]
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
      @tree.take(@tree.size - 1)
    end

    def parent? sym_tag
      parent && parent[:tag] == sym_tag
    end

    def parent
      @tree[-2]
    end

    def target temp
      @tree.push temp
      result = yield
      @tree.pop
      result
    end

    def tag!
      @tree.last
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
        in_tree: false
      }

      e
    end

    def open_tag *args
      new_tag = tag(*args)
      new_tag[:in_tree] = true
      new_tag[:parent_index]  = @tree.size - 1
      @current_tag[:childs] << new_tag
      @current_tag = new_tag

      if block_given?
        close_tag { yield }
      else
        self
      end
    end

    def close_tag
      if block_given?
        results = yield
        if results.is_a?(String)
          tag![:text] = results
        end
      end

      if tag![:in_tree]
        @current_tag = @tree[@current_tag[:parent_index]]
      end
      fail
    end

    Allowed[:attrs].each { |name, tags|
      eval %^
        def #{name} val
          allowed = Allowed[:attr][:name]
          allowed = allowed && allowed[tag![:tag]]
          return super unless allowed

          tag![:attrs][:#{name}] = val

          if block_given?
            close_tag { yield }
          else
            self
          end
        end
      ^
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

    def page_title
      return super unless tag?(:body)

      @is_doc = true
      @head[:childs].push tag(:title)
      close_tag { yield }
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
      when :attrs
        final = h[:value].map { |k,raw_v|
          v = raw_v.is_a?(Array) ? raw_v.join(SPACE) : raw_v
          %^#{k.to_s.gsub(INVALID_ATTR_CHARS,'_')}="#{Escape_Escape_Escape.inner_html(v)}"^
        }.join SPACE

        if final.empty?
          ''
        else
          " " << final
        end

      when :styles
        h[:value].map { |k,styles|
          %^#{k.to_s.gsub(INVALID_CSS_CLASS_CHARS, UNDERSCORE)} {
              #{hash_to_text :type=>:style, :value=>styles}
            }
          ^
        }.join.strip

      when :style
        h[:value].map { |k,v|
          %^#{k.to_s.gsub(INVALID_CSS_PROP_NAME_CHARS, '_')}: #{v};^
        }.join("\n").strip

      when :html
        if h[:tag] == :style
          return %^
            <style type="text/css">
              #{hash_to_text(type: :styles, value: h[:attrs])}
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
            <#{h[:tag]}#{h[:attrs] && hash_to_text(:type=>:attrs, :value=>h[:attrs])}>#{html}</#{h[:tag]}>
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

    def run
    end

    public def to_html

      return @compiled  if @compiled

      run

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

      utf_8 = Escape_Escape_Escape.clean_utf8(final)

      @compiled  = if is_doc?
                     Sanitize.document( utf_8 , WWW_Applet::Sanitize_Config )
                   else
                     Sanitize.fragment( utf_8 , WWW_Applet::Sanitize_Config )
                   end
    end # === def to_html

  end # === module Mod ==============================================

  module Customized_Tags # ==========================================

    def input *args
      case
      when args.size === 3
        open_tag(:input).type(args[0]).name(args[1]).value(args[2])
        close_tag
      else
        super
      end
    end

  end # === module Customized_Tags ==================================

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
