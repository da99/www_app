
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

    def new_class file_name = nil
      name = "Rand_#{Classes.size}"

      code = %^
        class #{name} << BasicObject
          include ::WWW_Applet::Mod
          def run
            #{file_name ? ::File.read(file_name) : ''}
          end
        end
      ^.strip

      if file_name
        eval code, nil, file_name, 1-3
      else
        eval code
      end

      o = self.class.const_get name

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
      @html_page     = nil
      @cache         = {}
      @page_title    = false
      @default_ids   = {}

      @head          = tag(:head)
      @body          = tag(:body)
      @parents       = [@body]
      @state         = []
      @ids           = {}
    end

    ::WWW_Applet::Sanitize_Config[:elements].each { |name|
      eval %^
        def #{name} *args
          if block_given?
            tag(:#{name}, *args) { yield }
          else
            tag(:#{name}, *args)
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

    def is_doc?
      @page_title
    end

    def first_class
      return nil unless tag[:attrs]
      return nil unless tag[:attrs][:class]
      tag[:attrs][:class].split.first
    end

    def html_element? e
      e.is_a?(Hash) && e[:type] == :html
    end

    def dom_id?
      tag[:attrs] && tag[:attrs][:id]
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

      id = tag[:attrs][:id]
      return id if id
      return nil unless use_default

      tag[:default_id] ||= begin
                             key = tag[:tag]
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
      start    = parents.size - 1
      i        = start
      id_given = false
      classes  = []

      while i > -1
        curr      = parents[i]
        id        = dom_id(curr)
        tag       = curr[:tag]

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

      start    = parents.size - 1
      i        = start
      id_given = false
      classes  = []

      while i > -1
        curr      = parents[i]
        id        = dom_id(curr)
        css_class = if start == i && str_class
                      str_class
                    else
                      curr[:attrs] && curr[:attrs][:class] && curre[:attrs][:class].split.first
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
      @parents
    end

    def parent? tag
      parent[:tag] == tag
    end

    def parent
      @parents.last
    end

    def target temp
      @parents.push temp
      result = yield
      @parents.pop
      result
    end

    def tag *args
      return parent if args.empty? && !block_given?

      if block_given?
        new_child(:html, *args) { yield }
      else
        new_child(:html, *args)
      end
    end

    def tag name, attrs={}
      e = {
        type:   :html,
        tag:    name,
        attrs:  attrs,
        text:   nil,
        childs: []
      }

      target(e) do
        if block_given
          update_tag(attrs) { yield }
        else
          update_tag(attrs)
        end
      end

      e
    end

    #
    # Example:
    #   div.*('my_id') { }
    #
    def * id
      attrs = (tag[:attrs] ||= {})
      old_id = attrs && attrs[:id]
      fail("Id already set: #{old_id} new: #{id}") if old_id
      attrs[:id] = id
      html
    end

    def attrs key, name
      fail("Id already taken: #{name.inspect}") if ids[name]
      ids[name] = true
      tag[:attrs][:id] = name
    end

    #
    # Example:
    #   div.^(:alert, :red_hot) { 'my content' }
    #
    def ^ *names
      tag[:attrs][:class] ||= []
      tag[:attrs][:class].concat(names).uniq!
    end

    def update_tag attrs={}
      e = parent
      if attrs
        e[:attrs].merge! attrs
      end

      if block_given?
        result = target(e) {
          yield
        }

        e[:text] = result if result.is_a?(String)
      end

      e
    end

    def no_title
      title { 'No title' }
    end

    def title &blok
      @page_title = true

      c = tag(:title, &blok)
      if parent?(:body)
        @head[:childs].push c
      else
        parent[:childs].push c
      end
      c
    end

    def meta *args
      fail "Not allowed outside of :head" unless parent?(:body)
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
            html << hash_to_text(tag(:div, :class=>'text') { h[:text] })
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

    def method_missing name, *args, &blok

      str_name = name.to_s

      case

      when creating_html?

        str_name = name.to_s
        if str_name[BANG] # === id
        else # === css class name
        end

        if !args.empty? || blok
          parent[:childs] << update_html(finish_creating_html, *args, &blok)
        else
          self
        end

      else # not creating_html?

          case

          when args.size == 1 && !blok && ::Sanitize::Config::RELAXED[:css][:properties].include?(css_name = str_name.gsub('_', '-'))
            # set style
            @style[css_id()] ||= {}
            @style[css_id()][css_name] = args.first

          when ::Sanitize::Config::RELAXED[:elements].include?(str_name)
            # === start of creating html:
            case
            when args.empty? && !blok
              @creating_html = tag(name)
            else
              e = tag(name, *args, &blok)
              parent[:childs] << e
            end

          else
            super

          end

      end

      self
    end # === def method_missing

    public def to_html

      return @html_page if @html_page

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

      @html_page = if is_doc?
                     Sanitize.document( utf_8 , WWW_Applet::Sanitize_Config )
                   else
                     Sanitize.fragment( utf_8 , WWW_Applet::Sanitize_Config )
                   end
    end # === def to_html

  end # === module Mod ==============================================

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
