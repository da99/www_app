
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
        include ::Kernel
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
      @in        = { type: nil, name: nil }
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

    def new_child type, tag, attr=nil, &blok
      e = {
        type: type,
        tag:  tag,
        attr: attr,
        text: nil,
        childs: []
      }

      if blok
        result = parent(e) {
          yield
        }

        if result.is_a? String
          e[:text] = Escape_Escape_Escape.inner_html(result)
        end
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
      when :attr
        final = h[:value].map { |k,v|
          %^#{k.to_s.gsub(INVALID_ATTR_CHARS,'_')}="#{Escape_Escape_Escape.inner_html(v)}"^
        }.join " "

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
        html = h[:childs].inject("") { |memo, c|
          memo << "\n#{hash_to_text c}"
          memo
        }

        if h[:text] && !(h[:text].strip).empty?
          if html.empty?
            html = h[:text]
          else
            html << hash_to_text(new_html(:div, :class=>'text') { h[:text] })
          end
        end

        if h[:tag]
          %^
            <#{h[:tag]}#{h[:attr] && hash_to_text(:type=>:attr, :value=>h[:attr])}>#{html}</#{h[:tag]}>
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

    def in_something?
      !!(@in[:type])
    end

    %w[ style html script ].each { |name|
      eval %~
        def in_#{name}?
          @in[:type] == :#{name}
        end
      ~
    }

    def method_missing name, *args, &blok

      str_name = name.to_s
      case

      when in_something? && args.empty? && !blok
        case

        when in_style?
          super

        when in_html?
          super

        when in_script?
          super

        else
          fail "Unknown element: #{name.inspect}"
        end

      when ::Sanitize::Config::RELAXED[:elements].include?(str_name)
        e = new_html(name, *args, &blok)
        @parent[:childs] << e

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
