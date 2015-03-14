
class WWW_App
  module JavaScript

    class DSL < BasicObject

      include ::Kernel

      def initialize &blok
        @js = []
        instance_eval &blok
      end

      %w[ add_class ].each { |name|
        eval <<-EOF, nil, __FILE__, __LINE__ + 1
          def #{name} *args
            run_method :#{name}, args
          end
        EOF
      }
      def run_method name, args
        self << name
        self << args
        self
      end

      def on name, &blok
        self << :on
        code = capture {
          instance_eval &blok
        }
        self << [name]
        self << code
        self
      end

      def raw_code
        @js
      end

      def concat arr
        @js.concat(arr)
      end

      def << *args
        @js.<<(*args)
      end

      def capture &blok
        orig = @js
        new  = []
        @js = new
        instance_eval &blok
        @js = orig
        new
      end

    end # === class

    def parent name
      js :parent, [name]
    end

    def js func, args
      @tag[:js] ||= []
      @tag[:js] << [func, args]
      self
    end

    def on name, &blok
      fail "Block required." unless blok

      val = JavaScript::DSL.new {
        on(name, &blok)
      }.raw_code
      create :js, :value=>val, :closed=>true
      go_up
    end

  end # === module JavaScript
end # === class WWW_App
