
class WWW_App
  module JavaScript

    def parent name
      js :parent, [name]
    end

    def add_class *classes
      js :add_class, classes.flatten
    end

    def js func, args
      @tag[:js] ||= []
      @tag[:js] << [func, args]
      self
    end

    def on name, &blok
      fail "Block required." unless blok

      @js << 'create_event'
      @js << [selector_id, name]

      orig             = @css_id_override
      @css_id_override = name
      results          = yield
      @css_id_override = orig

      if @js.last.size == 2
        @js.pop
        @js.pop
      end

      results
    end

  end # === module JavaScript
end # === class WWW_App
