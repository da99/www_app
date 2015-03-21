
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

    end # === class DSL

  end # === module JavaScript
end # === class WWW_App
