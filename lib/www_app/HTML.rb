
class WWW_App
  module HTML

    NO_END_TAGS = [:br, :input, :link, :meta, :hr, :img]

    HTML_TAGS   = %w[
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
      :img         => [:src, :width, :height]
    }

    ATTRIBUTES_TO_TAGS = TAGS_TO_ATTRIBUTES.inject({}) { |memo, (tag, attrs)|
      attrs.each { |a|
        memo[a] ||= []
        memo[a] << tag
      }
      memo
    }

    ATTRIBUTES_TO_TAGS.each { |name, tags|
      eval <<-EOF, nil, __FILE__, __LINE__ + 1
        def #{name} val
          allowed = ATTRIBUTES_TO_TAGS[:#{name}]
          allowed = allowed && allowed[tag[:type]]
          return super unless allowed

          tag[:attrs][:#{name}] = val

          if block_given?
            close_tag { yield }
          else
            self
          end
        end
      EOF
    }

    HTML_TAGS.each { |name|
      eval <<-EOF, nil, __FILE__, __LINE__ + 1
        def #{name}
          if block_given?
            create(:#{name}) { yield }
          else
            create(:#{name})
          end
        end
      EOF
    }

    def meta *args
      fail "No block allowed." if block_given?
      fail "Not allowed here." unless tag?(:body)
      c = nil
      in_tag(@tag) { c = tag(:meta, *args) }
      c
    end

    def title
      create :title do
        yield
      end
    end

    def id new_id
      old_id = tag[:id]

      if old_id && old_id != new_id
        fail("Id already set: #{old_id} new: #{new_id}")
      end

      if @html_ids[new_id] && !ancestor?(:group)
        fail(HTML_ID_Duplicate, "Id already used: #{new_id.inspect}, tag index: #{@html_ids[new_id]}")
      end

      @html_ids[ new_id ] = new_id
      tag[:id] = new_id

      if block_given?
        close { yield }
      else
        self
      end
    end

    #
    # Example:
    #   div.^(:alert, :red_hot) { 'my content' }
    #
    def ^ *names
      tag[:class] ||= []
      tag[:class].concat(names)

      if block_given?
        close { yield }
      else
        self
      end
    end

    def render_if name
      create(:render_if, :key=>name) {
        yield
      }
      nil
    end

    def render_unless name
      create(:render_unless, :key=>name) {
        yield
      }
      nil
    end


    def render_if name
      create(:render_if, :key=>name) {
        yield
      }
      nil
    end

    def render_unless name
      create(:render_unless, :key=>name) {
        yield
      }
      nil
    end

    def input *args
      case
      when args.size === 3
        create(:input).type(args[0]).name(args[1]).value(args[2])
      else
        super
      end
    end

  end # === module HTML
end # === class WWW_App

