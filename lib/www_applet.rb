
class WWW_Applet

  Document_Template = File.read(__FILE__).split("__END__").last.strip

  module HTML

    def init
      @title  = nil
      @style  = {}
      @scripts = []
      @parent = nil
      @dom    = []
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

    %w[ p form button splash_line div ].each { |tag|
      eval %^
      def #{tag} attr = nil, &blok
        new_tag :#{tag}, attr, &blok
      end
      ^
    }

    def a href
      new_tag :a, {:href=>href} do
        yield
      end
    end

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
          e[:text] = result
        end
      end

      @parent = e[:parent]
      e[:parent] = nil
    end

    def to_attr h
      return '' unless h
      final = h.
        map { |k,v|
          %^#{k}="#{v}"^
        }.
        join " "

      if final.empty?
        ''
      else
         " " << final
      end
    end

    def to_html e = nil
      if !e
        raw_html = ""
        @dom.each { |ele|
          raw_html << to_html(ele)
        }

        html = Escape_Escape_Escape.html(raw_html)
        return html if !@title && @style.empty?

        Document_Template.gsub(/!([a-z0-9\_]+)/) { |sub|
          key = $1.to_sym
          case key
          when :style
            Sanitize::CSS.stylesheet "", Escape_Escape_Escape::CONFIG
          when :title
            @title || "[No Title]"
          when :body
            html
          end
        }
      end

      html = e[:childs].inject("") { |memo, c|
        memo << "\n#{to_html c}"
        memo
      }

      if e[:text] && !(e[:text].strip).empty?
        if html.empty?
          html = e[:text]
        else
          html << to_html(new_tag(:div, :class=>'text') { e[:text] })
        end
      end

      %^
        <#{e[:tag]}#{e[:attr] && to_attr(e[:attr])}>#{html}</#{e[:tag]}>
      ^.strip

    end

  end # === module HTML ===

  def initialize file_name = nil, &blok
    @klass = if file_name
      content = File.read(file_name)
      Class.new {
        include HTML
        code = %^
          def initialize
            init
            #{content}
          end
        ^
        eval code.strip, nil, file_name, (1-2)
      }

    else
      Class.new {
        include HTML
        define_method :initialize do
          init
          instance_eval &blok
        end
      }
    end
  end

  def to_html
    @klass.new.to_html
  end


end # === class WWW_Applet ===

__END__
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title>!title</title>
    <style type="text/css">!style</style>
  </head>
  <body>!body</body>
</html>
