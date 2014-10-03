

class WWW_App
  class Code_ify < BasicObject
    def initialize &blok
      @code = []
      @target = @code
      @indent = []
      instance_eval(&blok) if blok
    end

    def method_missing *args, &blok
      @target << {:name=>args.shift, :args=>args}

      if blok
        @indent << 1
        @target.last[:blok] = []
        @target.last[:indent] = @indent.size

        orig = @target
        @target = @target.last[:blok]
        instance_eval(&blok)

        @indent.pop
        @target = orig
      end

      self
    end

    def to_text
      @code.map { |e|
        to_string e
      }.join "\n".freeze
    end

    private
    def to_string e
      if e.is_a? ::Array
        return e.map { |ee| to_string ee }.join "\n".freeze
      end

      s = %^#{e[:name]}(#{e[:args].map(&:inspect).join ', '.freeze})^
      if e[:blok]
        first_indent = ' '.freeze * e[:indent]
        last_indent  = ' '.freeze * (e[:indent] - 1)
        s << %^ {\n#{first_indent}#{to_string e[:blok]}\n#{last_indent}}^
      end
      s
    end

  end # === class
end # === class
