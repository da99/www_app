
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
      'meta'       => ['name', 'http-equiv'. 'property', 'content', 'charset'],
      'html'       => ['lang']
    },

    :add_attributes => {'a'=>{'rel'=>'nofollow'}},

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

  module Mod

    def initialize data = nil
      @title   = nil
      @style   = {}
      @scripts = []
      @parent  = nil
      @dom     = []
      @data    = data || {}
      @html_page = nil
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

    %w[ a p form button splash_line div ].each { |tag|
      eval %^
        def #{tag} attr = nil, &blok
          new_tag :#{tag}, attr, &blok
        end
      ^
    }

    def new_tag tag, attr = nil
      e = {:tag=>tag, :attr=> nil, :text=>nil, :childs=>[]}

      e[:attr] = attr

      if @parent
        @parent[:childs] << e
        e[:parent] = @parent
      else
        @dom << e
      end

      @parent = e

      if block_given?
        result = yield
        if result.is_a? String
          e[:text] = Escape_Escape_Escape.inner_html(result)
        end
      end

      @parent = e[:parent]
      e[:parent] = nil
    end

    def to_attr h
      return '' unless h
      final = h.
        map { |k,v|
          %^#{k.to_s.gsub(INVALID_ATTR_CHARS,'_')}="#{Escape_Escape_Escape.inner_html(v)}"^
        }.
        join " "

      if final.empty?
        ''
      else
         " " << final
      end
    end

    def to_styles h
      h.map { |k,v|
        %^#{k.to_s.gsub(INVALID_CSS_PROP_NAME_CHARS, '_')} : #{v};^
      }.join("\n").strip
    end

    def to_style h
      h.map { |k,styles|
        %^#{k.to_s.gsub(INVALID_CSS_CLASS_CHARS, '_')} {
        #{to_styles styles}
      }
        ^
      }.join.strip
    end

    def element_to_html e
      html = e[:childs].inject("") { |memo, c|
        memo << "\n#{element_to_html c}"
        memo
      }

      if e[:text] && !(e[:text].strip).empty?
        if html.empty?
          html = e[:text]
        else
          html << element_to_html(new_tag(:div, :class=>'text') { e[:text] })
        end
      end

      %^
        <#{e[:tag]}#{e[:attr] && to_attr(e[:attr])}>#{html}</#{e[:tag]}>
      ^.strip
    end

    def to_html

      return @html_page if @html_page

      run

      raw_html = ""
      @dom.each { |ele|
        raw_html << element_to_html(ele)
      }

      is_doc = @title || !@style.empty?

      final = if is_doc
                raw_html
              else
                Document_Template.gsub(/!([a-z0-9\_]+)/) { |sub|
                  key = $1.to_sym
                  case key
                  when :style
                    to_style(@style)
                  when :title
                    @title || "[No Title]"
                  when :body
                    raw_html
                  end
                }
              end

      utf_8 = Escape_Escape_Escape.clean_utf8(final)

      @html_page = if is_doc
                     Sanitize.document( utf_8 , WWW_Applet::Sanitize_Config)
                   else
                     Sanitize.fragment( utf_8 , WWW_Applet::Sanitize_Config)
                   end
    end

  end # === module Mod ===

  class << self

    def new_class file_name = nil, &blok
      Class.new {
        include Mod

        if file_name
          eval(<<-EOF.strip, nil, file_name, 1-1)
            def run
              #{File.read(file_name)}
            end
          EOF
        else

          define_method :run do
            instance_eval &blok
          end

        end
      }
    end # === def new_class

  end # === class self ===

end # === class WWW_Applet ===

__END__
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title>!title</title>
    <style type="text/css">
      !style
    </style>
  </head>
  <body>!body</body>
</html>
