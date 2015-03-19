
class WWW_App
  module HTML

    SELF_CLOSING_TAGS = [:br, :input, :link, :meta, :hr, :img]
    NO_NEW_LINES = [:p, :code, :span].freeze

    TAGS   = %w[
      title
      body   div    span

      img
      b      em     i  strong  u  a 
      abbr   blockquote  cite
      br     cite   code 
      ul     ol     li  p  pre  q 
      sup    sub 
      form   input  button

      link

      script
    ].map(&:to_sym)

    TAGS_TO_ATTRIBUTES = {
      :all         => [:id, :class],
      :a           => [:href, :rel],
      :form        => [:action, :method, :accept_charset],
      :input       => [:type, :name, :value],
      :style       => [:type],
      :script      => [:type, :src, :language],
      :link        => [:rel, :type, :sizes, :href, :title],
      :meta        => [:name, :http_equiv, :property, :content, :charset],
      :img         => [:src], # :width, :height will be used by CSS only.
      :html        => [:lang]
    }

    ATTRIBUTES_TO_TAGS = TAGS_TO_ATTRIBUTES.inject({}) { |memo, (tag, attrs)|
      attrs.each { |a|
        memo[a] ||= []
        memo[a] << tag
      }
      memo
    }

    ATTRIBUTES = ATTRIBUTES_TO_TAGS.keys

    ATTRIBUTES_TO_TAGS.each { |name, tags|
      eval <<-EOF, nil, __FILE__, __LINE__ + 1
        def #{name} val
          alter_attribute :#{name}, val
          block_given? ?
            close { yield } :
            self
        end
      EOF
    }

    TAGS.each { |name|
      eval <<-EOF, nil, __FILE__, __LINE__ + 1
        def #{name}
          create(:#{name})
          block_given? ?
            close { yield } :
            self
        end
      EOF
    }

    def alter_attribute name, val
      allowed = @tag &&
        ATTRIBUTES_TO_TAGS[name] &&
        ATTRIBUTES_TO_TAGS[name].include?(@tag[:tag_name])

      fail "#{name.inspect} not allowed to be set here." unless allowed

      @tag[name] = val

      block_given? ?
        close { yield } :
        self
    end

    def meta *args
      fail "No block allowed." if block_given?
      fail "Not allowed here." if parent
      create(:meta, *args)
    end

    def title
      fail ":title not allowed here" if parent
      create :title do
        yield
      end
    end

    def id new_id
      if !@tag
        fail "No HTML tag found. Try using _.id(#{new_id.inspect})"
      end

      if !ancestor?(:group)
        old_id = @tag[:id]
        if old_id && old_id != new_id
          fail("Id already set: #{old_id} new: #{new_id}")
        end

        if @html_ids[new_id]
          fail(HTML_ID_Duplicate, "Id already used: #{new_id.inspect}, tag index: #{@html_ids[new_id]}")
        end
        @html_ids[ new_id ] = new_id
      end

      @tag[:id] = new_id

      if block_given?
        close { yield }
      else
        self
      end
    end # === def id

    def is_fragment?
      !is_doc?
    end

    def is_doc?
      @is_doc ||= begin
                    found = false
                    tags = @tags.dup
                    while !found && !tags.empty?
                      t = tags.shift
                      found = begin
                                (t[:tag_name] == :body && (t[:id] || t[:css]) ) ||
                                  t[:tag_name] == :style                        ||
                                  t[:tag_name] == :script                       ||
                                  t[:tag_name] == :meta                         ||
                                  t[:css]                                       ||
                                  (t[:tag_name] == :title && t[:parent] && t[:parent][:tag_name] == :body)
                              end
                      if !found && t[:children]
                        tags = t[:children].concat(tags)
                      end
                    end

                    found
                  end
    end # === def is_doc?

    def lang name
      fail "Tag has to be placed tomost of the page." if parent
      fail "Block not allowed here." if block_given?
      create :html_tag_attr do
        @tag[:lang] = name.to_s.downcase.gsub(/[^a-z0-9\_\-]+/, ''.freeze)
        @tag[:lang] = 'en' if @tag[:lang].empty?
      end

      self
    end

    #
    # Example:
    #   div.^(:alert, :red_hot) { 'my content' }
    #
    def ^ *names
      @tag[:class] ||= []
      @tag[:class].concat(names)

      if block_given?
        close { yield }
      else
        self
      end
    end

    def render_if name
      fail ::ArgumentError, "Not a symbol: #{name.inspect}" unless name.is_a?(Symbol)
      raw_text %^{{#coll.#{name}}}^
      yield
      raw_text %^{{/coll.#{name}}}^
      nil
    end

    def render_unless name
      fail ::ArgumentError, "Not a symbol: #{name.inspect}" unless name.is_a?(Symbol)
      raw_text %!{{^coll.#{name}}}!
      yield
      raw_text %!{{/coll.#{name}}}!
      nil
    end

    def input *args
      case
      when args.size === 3
        create(:input, :type=>args[0].to_s, :name=>args[1].to_s, :value=>args[2], :closed=>true)
        go_up
      else
        super
      end
    end

    def script *classes
      attrs = {}
      classes.select! { |u|
        case
        when u.is_a?(String) && u['.js'.freeze]
          attrs[:src] = u
          false
        when u.is_a?(String)
          attrs[:type] = u
          false
        else
          true
        end
      }

      if attrs[:src]
        return create(:script, :src=>attrs[:src]) { }
      end

      attrs[:class] = classes unless classes.empty?
      attrs[:type]  ||= "text/hogan"

      create :script, attrs
      close { yield } if block_given?
      self
    end

  end # === module HTML
end # === class WWW_App

