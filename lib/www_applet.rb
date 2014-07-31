
require 'sanitize'

class WWW_Applet

  INVALID_ATTR_CHARS          = /[^a-z0-9\_\-]/i
  INVALID_CSS_CLASS_CHARS     = /[^a-z0-9\#\:\_\-\ ]/i
  INVALID_CSS_PROP_NAME_CHARS = /[^a-z0-9\-\_]/i

  Document_Template  = File.read(__FILE__).split("__END__").last.strip
  Sanitize_Config    = {

    :allow_doctype   => true,
    :allow_comments  => false,
    :remove_contents => true,

    :elements => [

      'html', 'head', 'title', 'meta', 'style', 'link',

      'b'    , 'em', 'i', 'strong', 'u', 'a',
      'abbr' , 'blockquote',
      'br'   , 'cite', 'code',
      'ul'   , 'ol', 'li', 'p', 'pre', 'q',
      'sup'  , 'sub',
      'form', 'input', 'button'

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

    def new_class file_name = nil, &blok
      Class.new(BasicObject) {
        include ::WWW_Applet::Mod

        if file_name
          eval(<<-EOF.strip, nil, file_name, 1-1)
            def run
              #{::File.read(file_name)}
            end
          EOF
        else

          define_method :run do
            instance_eval &blok
          end

        end
      }
    end # === def new_class

  end # === class self ==============================================

  module Mod # ======================================================

    attr_accessor :is_doc, :has_title
    private

    BANG     = '!'
    NEW_LINE = "\n"
    SPACE    = ' '

    def initialize data = nil
      @title     = nil
      @curr_id   = -1
      @style     = {}
      @scripts   = []
      @parent    = nil
      @body      = []
      @data      = data || {}
      @html_page = nil
      @cache     = {}
      @is_doc    = false
      @has_title = false

      @head      = new_html(:head)
      @body      = new_html(:body)
      @parent    = @body
      @in        = nil
    end

    def fail *args
      ::Object.new.send :fail, *args
    end

    def in?
      !!@in
    end

    def pop
      e = @in
      @in = nil
      e
    end

    def next_id
      "e_#{@curr_id += 1}"
    end

    def parent c
      origin = @parent
      @parent = c
      result = yield
      @parent = origin
      result
    end

    def capture &blok
      h = {:childs=>[]}
      parent(h, &blok)
      h[:childs]
    end

    def title string
      @title = string
    end

    def style h
      @style = h
    end

    def scripts
      @scripts
    end

    def new_html *args, &blok
      new_child :html, *args, &blok
    end

    def new_style *args, &blok
      new_html :style, *args, &blok
    end

    def new_child type, tag, attrs=nil, &blok
      e = {
        type:   type,
        tag:    tag,
        attrs:  attrs,
        text:   nil,
        childs: []
      }

      update_html e, attrs, blok

      e
    end

    def add_id html, id
      attrs = (html[:attrs] ||= {})
      old_id = attrs && attrs[:id]
      fail("Id already set: #{old_id} new: #{id}") if old_id
      attrs[:id] = id
      html
    end

    def add_classes html, *names
      html[:attrs] ||= {}

      old_class = html[:attrs][:class]
      new_class = names.compact.join(SPACE)

      return html if old_class == new_class
      html[:attrs][:class] = [old_class, new_class].compact.join(SPACE)
      html
    end

    def update_html e, attrs=nil, blok=nil
      if attrs
        e[:attrs] ||= {}
        add_id(e, attrs[:id]) if attrs[:id]
        e[:attrs].merge! attrs
      end

      if blok
        result = parent(e) {
          blok.call
        }

        e[:text] = result if result.is_a? String
      end

      e
    end

    def title &blok
      self.is_doc = true
      self.has_title = true

      c = new_html(:title, &blok)
      if parent?(:body)
        @head[:childs].push c
      else
        @parent[:childs].push c
      end
      c
    end

    def meta *args
      self.is_doc = true

      fail "Not allowed outside of :head" unless parent?(:body)
      c = new_html(:meta, *args)
      @head[:childs].push c
      c
    end

    def script *args, &blok
      self.is_doc = true

      fail "Not allowed outside of :head" unless parent?(:body)
      c = new_html(:script, *args, &blok)
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
        h.map { |k,styles|
          %^#{k.to_s.gsub(INVALID_CSS_CLASS_CHARS, '_')} {
              #{to_styles styles}
            }
          ^
        }.join.strip

      when :style
        h.map { |k,v|
          %^#{k.to_s.gsub(INVALID_CSS_PROP_NAME_CHARS, '_')} : #{v};^
        }.join("\n").strip

      when :html
        html = h[:childs].map { |c|
          "#{hash_to_text c}"
        }.join NEW_LINE

        if h[:text] && !(h[:text].strip).empty?
          if html.empty?
            html = h[:text]
          else
            html << hash_to_text(new_html(:div, :class=>'text') { h[:text] })
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

    %w[ style html script ].each { |name|
      eval %~
        def in_#{name}?
          in? && @in[:type] == :#{name}
        end
      ~
    }

    def method_missing name, *args, &blok

      str_name = name.to_s
      case

      when !in?

        case
        when ::Sanitize::Config::RELAXED[:elements].include?(str_name)
          case
          when args.empty? && !blok
            @in = new_html(name)
            self
          else
            e = new_html(name, *args, &blok)
            @parent[:childs] << e
          end
        else
          super
        end

      when in?

        case
        when in_html?

          str_name = name.to_s
          if str_name[BANG] # === id
            add_id @in, str_name.sub(BANG, '')
          else # === css class name
            add_classes @in, name, (args.first && args.first.delete(:class))
          end

          if !args.empty? || blok
            @parent[:childs] << update_html(pop, *args, blok)
          else
            self
          end
        else
          super
        end

      when args.size == 1 && !blok && ::Sanitize::Config::RELAXED[:css][:properties].include?(css_name = str_name.gsub('_', '-'))
        # set style
        @parent[:id] ||= next_id
        @style[@parent_id] ||= {}
        @style[@parent_id][css_name] = args.first

      else
        super

      end
    end # === def method_missing

    # ===============================================================
    public # ========================================================
    # ===============================================================

    def to_html

      return @html_page if @html_page

      run

      final = if is_doc
                # Remember: to use !BODY first, because
                # :head content might include a '!HEAD'
                # value.
                fail "Title not set." unless has_title
                Document_Template.
                  sub('!BODY', hash_to_text(@body)).
                  sub('!HEAD', array_to_text(@head[:childs]))
              else
                array_to_text(@body[:childs])
              end

      utf_8 = Escape_Escape_Escape.clean_utf8(final)

      @html_page = if is_doc
                     Sanitize.document( utf_8 , WWW_Applet::Sanitize_Config)
                   else
                     Sanitize.fragment( utf_8 , WWW_Applet::Sanitize_Config)
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
