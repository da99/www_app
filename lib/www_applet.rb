
class WWW_Applet

  module HTML

    def init
      @title  = nil
      @style  = {}
      @parent = nil
      @dom    = []
    end

    def title string
      @title = string
    end

    def style h
      @style = h
    end

    %w[ p form button splash_line div ].each { |tag|
      eval %^
      def #{tag} attr, &blok
        new_tag :#{tag}, attr, &blok
      end
      ^
    }

    def a attr, &blok
      new_tag :a, {:href=>attr}, &blok
    end

    def new_tag tag, attr
      e = {:tag=>tag, :attr=> nil, :text=>nil, :childs=>[]}

      case attr
      when String
        e[:text] = attr
      when Hash
        e[:attr] = attr
      end

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
      if e
        if e[:text]
          if e[:childs].empty?
          end
        end

        html = e[:childs].inject("") { |memo, c|
          memo << "\n#{to_html c}"
          memo
        }
        if e[:text] && !e[:text].empty?
          if html.empty?
            html = e[:text]
          else
            html << %^
              <div class="text">#{e[:text]}</div>
            ^
          end
        end
        %^
          <#{e[:tag]}#{to_attr e[:attr]}>#{html}</#{e[:tag]}>
        ^.strip

      else
        html = ""
        @dom.each { |ele|
          html << to_html(ele)
        }
        html
      end
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
